import 'dart:async';
import 'dart:async' as dart_async;
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../audio_manager.dart';
import '../components/actors/enemy_component.dart';
import '../components/actors/npc_component.dart';
import '../components/actors/player_component.dart';
import '../components/effects/damage_number_effect.dart';
import '../components/effects/enemy_attack_effect.dart';
import '../components/effects/enemy_orb_projectile_effect.dart';
import '../components/effects/floating_text_effect.dart';
import '../components/effects/player_attack_effect.dart';
import '../components/effects/player_fireball_effect.dart';
import '../components/objects/chest_component.dart';
import '../components/objects/interactable_entity.dart';
import '../components/objects/teleport_component.dart';
import '../state/game_state_controller.dart';
import '../state/models/game_models.dart';
import 'map_definition.dart';
import 'punyworld_renderer.dart';

class WorldMapManager extends Component {
  WorldMapManager({
    required this.player,
    required this.controller,
    required this.onTeleportTriggered,
  });

  final PlayerComponent player;
  final GameStateController controller;
  final Future<void> Function(String mapId, String spawnId) onTeleportTriggered;
  final PunyworldRenderer _punyworldRenderer = PunyworldRenderer();

  final Component _sceneRoot = Component();
  final List<Rect> _collisionRects = <Rect>[];
  final List<InteractableEntity> _interactables = <InteractableEntity>[];
  final List<EnemyComponent> _enemies = <EnemyComponent>[];
  final Map<EnemyComponent, String> _enemySceneIds = <EnemyComponent, String>{};
  final List<TeleportComponent> _teleports = <TeleportComponent>[];
  final Map<String, Vector2> _spawnPoints = <String, Vector2>{};
  final Map<EnemyComponent, double> _contactDamageCooldown =
      <EnemyComponent, double>{};
  final Map<EnemyComponent, double> _enemySkillCooldown =
      <EnemyComponent, double>{};
    final Map<EnemyComponent, _ElderDemonLordSkillPattern> _elderSkillPattern =
      <EnemyComponent, _ElderDemonLordSkillPattern>{};
  final List<_PendingRespawn> _pendingRespawns = <_PendingRespawn>[];
  MapDefinition? _activeDefinition;
  static const double _enemyPathGrid = 16;
  static const int _maxActiveEnemies = 12;
  static const double _bossSkillMinRange = 72;
  static const double _regularEnemySkillMaxRange = 212;
  static const double _elderDemonLordSkillMaxRange = 360;
  static const double _elderDemonLordProjectileSpeed = 165;
  static const double _elderDemonLordProjectileDistance = 560;

  Vector2 mapPixelSize = Vector2.zero();
  bool _teleportLatch = false;
  int _seenEquipmentPickupSerial = 0;

  @override
  Future<void> onLoad() async {
    await add(_sceneRoot);
    controller.onNodeFlagSet = (key) => unawaited(_spawnEnemiesUnlockedByFlag(key));
  }

  Future<void> loadMap(
    String mapId, {
    String? spawnId,
    Vector2? explicitPlayerPosition,
  }) async {
    final definition = mapDefinitions[mapId];
    if (definition == null) {
      return;
    }

    _sceneRoot.removeAll(_sceneRoot.children.toList());
    _collisionRects.clear();
    _interactables.clear();
    _enemies.clear();
    _enemySceneIds.clear();
    _teleports.clear();
    _spawnPoints.clear();
    _contactDamageCooldown.clear();
    _enemySkillCooldown.clear();
    _elderSkillPattern.clear();
    for (final pending in _pendingRespawns) {
      pending.timer.cancel();
    }
    _pendingRespawns.clear();
    _teleportLatch = false;
    _activeDefinition = definition;

    mapPixelSize = Vector2(definition.sceneSize.x, definition.sceneSize.y);
    await _sceneRoot.add(await _buildSceneBackdrop(definition));

    _spawnPoints.addAll(
      definition.spawnPoints.map(
        (key, value) => MapEntry(key, Vector2(value.x, value.y)),
      ),
    );
    if (definition.collisionLayers case final collisionLayers?) {
      _collisionRects.addAll(
        await _punyworldRenderer.buildCollisionRects(
          tmjAsset: definition.mapAsset,
          tileSize: definition.renderTileSize,
          includeLayers: collisionLayers.toSet(),
        ),
      );
    } else {
      _collisionRects.addAll(definition.blockingRects);
    }
    await _loadTeleports(definition);
    await _loadNpcs(definition);
    await _loadEnemies(definition);
    await _loadChests(definition);
    _syncFieldBgmForCurrentScene();

    if (player.parent != null) {
      player.removeFromParent();
    }
    await _sceneRoot.add(player);

    final desiredSpawnId = spawnId ?? definition.defaultSpawnId;
    final spawnPosition =
        explicitPlayerPosition ??
        _spawnPoints[desiredSpawnId] ??
        Vector2(64, 64);
    player.snapTo(spawnPosition);
    controller.setMapContext(mapId: mapId, spawnId: desiredSpawnId);
    controller.setHudMessage(definition.hudMessage);
  }

  bool canMoveTo(Rect targetRect) {
    if (targetRect.left < 0 ||
        targetRect.top < 0 ||
        targetRect.right > mapPixelSize.x ||
        targetRect.bottom > mapPixelSize.y) {
      return false;
    }
    return !_collisionRects.any(targetRect.overlaps);
  }

  bool canPlayerMoveTo(Rect targetRect) {
    if (!canMoveTo(targetRect)) {
      return false;
    }
    for (final enemy in _enemies) {
      if (!enemy.isMounted) {
        continue;
      }
      if (enemy.bodyRect.inflate(2).overlaps(targetRect)) {
        return false;
      }
    }
    return true;
  }

  Future<void> interactInFrontOfPlayer() async {
    final probe = player.interactionProbe;
    final candidates = _interactables
        .where((entity) => entity.interactionBounds.overlaps(probe))
        .toList();
    if (candidates.isEmpty) {
      controller.setHudMessage('前方沒有可互動物件。');
      return;
    }
    candidates.sort(
      (a, b) =>
          (a.interactionBounds.center - probe.center).distanceSquared.compareTo(
            (b.interactionBounds.center - probe.center).distanceSquared,
          ),
    );
    await candidates.first.interact();
  }

  Future<void> playerAttack() async {
    if (!player.tryAttack()) {
      return;
    }
    unawaited(AudioManager.instance.playSwordHitSfx());
    await _sceneRoot.add(
      PlayerAttackEffect(
        direction: player.aimDirection,
        position: player.attackEffectOrigin,
      ),
    );
    final hitEnemies = _enemies
        .where(_isEnemyInPlayerMeleeRange)
        .toList();
    if (hitEnemies.isEmpty) {
      controller.setHudMessage('你揮空了。');
      return;
    }

    for (final enemy in hitEnemies) {
      final damage = controller.rollPlayerDamage(enemy.definition.defense);
      enemy.applyKnockback(player.aimDirection, distance: 18);
      _showDamageNumber(
        position: _enemyDamagePosition(enemy),
        amount: damage,
        isPlayerHit: false,
      );
      final defeated = await enemy.receiveDamage(damage);
      if (!defeated) {
        controller.setHudMessage('命中 ${enemy.definition.name}，造成 $damage 點傷害。');
      }
    }
  }

  bool _isEnemyInPlayerMeleeRange(EnemyComponent enemy) {
    if (!enemy.isMounted) {
      return false;
    }

    // Keep the directional hitbox, but give it side tolerance.
    if (enemy.bodyRect.overlaps(player.attackHitbox.inflate(10))) {
      return true;
    }

    final playerCenter = player.bodyRect.center;
    final enemyCenter = enemy.bodyRect.center;
    final toEnemy = Vector2(
      enemyCenter.dx - playerCenter.dx,
      enemyCenter.dy - playerCenter.dy,
    );
    final distance = toEnemy.length;
    if (distance == 0) {
      return true;
    }

    // Secondary fallback: nearby targets slightly off to the side should still connect.
    if (distance > 54) {
      return false;
    }
    final dirToEnemy = toEnemy / distance;
    final facingDot = dirToEnemy.dot(player.aimDirection.normalized());
    return facingDot >= -0.12;
  }

  Future<void> playerCastFireball({Vector2? direction}) async {
    const mpCost = 3;
    final shotDirection = (direction != null && direction.length2 > 0)
        ? direction.normalized()
        : player.aimDirection;
    final fireMode = controller.level >= 12
        ? _FireballMode.inferno
        : (controller.level >= 6 ? _FireballMode.flamethrower : _FireballMode.basic);
    if (controller.baseStats.mp < mpCost) {
      final skillName = switch (fireMode) {
        _FireballMode.basic => '火球',
        _FireballMode.flamethrower => '噴射火焰',
        _FireballMode.inferno => '大字爆炎',
      };
      controller.setHudMessage('MP 不足，無法施放$skillName。');
      return;
    }
    if (!player.tryCastFireball()) {
      return;
    }
    if (!controller.spendMp(mpCost, silent: true)) {
      final skillName = switch (fireMode) {
        _FireballMode.basic => '火球',
        _FireballMode.flamethrower => '噴射火焰',
        _FireballMode.inferno => '大字爆炎',
      };
      controller.setHudMessage('MP 不足，無法施放$skillName。');
      return;
    }

    final directions = switch (fireMode) {
      _FireballMode.basic => <Vector2>[shotDirection],
      _FireballMode.flamethrower => <Vector2>[
          _rotate(shotDirection, -0.24),
          shotDirection,
          _rotate(shotDirection, 0.24),
        ],
      _FireballMode.inferno => List<Vector2>.generate(
          12,
          (index) {
            final angle = (math.pi * 2 * index) / 12;
            return Vector2(math.cos(angle), math.sin(angle));
          },
        ),
    };

    for (final dir in directions) {
      await _sceneRoot.add(
        PlayerFireballEffect(
          direction: dir,
          position: player.fireballOrigin,
          canTravelTo: canMoveTo,
          findEnemyHit: (targetRect) {
            for (final enemy in _enemies) {
              if (enemy.isMounted && enemy.bodyRect.overlaps(targetRect)) {
                return enemy;
              }
            }
            return null;
          },
          onEnemyHit: (enemy, hitDirection) =>
              unawaited(_handleFireballHit(enemy, hitDirection)),
        ),
      );
    }
    unawaited(AudioManager.instance.playFireBallSfx());
    final castMessage = switch (fireMode) {
      _FireballMode.basic => '火球發射！消耗 $mpCost MP。',
      _FireballMode.flamethrower => '噴射火焰！扇形三連發，消耗 $mpCost MP。',
      _FireballMode.inferno => '大字爆炎！全向爆發，消耗 $mpCost MP。',
    };
    controller.setHudMessage(castMessage);
  }

  Vector2 _rotate(Vector2 direction, double radians) {
    final cosA = math.cos(radians);
    final sinA = math.sin(radians);
    return Vector2(
      direction.x * cosA - direction.y * sinA,
      direction.x * sinA + direction.y * cosA,
    ).normalized();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _maybeShowEquipmentPickupText();
    _tickCombatCooldowns(dt);
    _pendingRespawns.removeWhere((pending) => !pending.timer.isActive);
    _applyTouchCollisionDamage();
    _updateEnemySkills();

    final activeTeleport = _teleports.where(
      (teleport) => teleport.toAbsoluteRect().overlaps(player.bodyRect),
    );
    final currentTeleport = activeTeleport.isEmpty
        ? null
        : activeTeleport.first;
    if (currentTeleport == null) {
      _teleportLatch = false;
      return;
    }
    if (_teleportLatch || controller.isOverlayBusy) {
      return;
    }

    if (currentTeleport.requiredStoryFlag case final requiredFlag?) {
      if (!controller.flag(requiredFlag)) {
        _teleportLatch = true;
        controller.setHudMessage(currentTeleport.blockedMessage ?? '前方似乎被封住了。');
        if (controller.currentMapId == 'ruins' && requiredFlag == 'can_escape_forest') {
          onTeleportTriggered('ruins', 'entry');
        }
        return;
      }
    }

    _teleportLatch = true;
    onTeleportTriggered(
      currentTeleport.targetMapId,
      currentTeleport.targetSpawnId,
    );
  }

  bool _isVisible({String? showWhenFlag, String? hiddenWhenFlag}) {
    if (showWhenFlag != null && !controller.flag(showWhenFlag)) {
      return false;
    }
    if (hiddenWhenFlag != null && controller.flag(hiddenWhenFlag)) {
      return false;
    }
    return true;
  }

  bool _canEnemyMoveTo(EnemyComponent movingEnemy, Rect targetRect) {
    if (targetRect.overlaps(player.bodyRect.inflate(4))) {
      return false;
    }
    if (!canMoveTo(targetRect)) {
      return false;
    }
    for (final other in _enemies) {
      if (!other.isMounted || identical(other, movingEnemy)) {
        continue;
      }
      if (other.bodyRect.inflate(2).overlaps(targetRect)) {
        return false;
      }
    }
    return true;
  }

  bool get _enemyAttacksBlocked => controller.isOverlayBusy;

  Future<void> _handleEnemyAttack(
    EnemyComponent enemy,
    Vector2 attackDirection,
  ) async {
    if (!enemy.isMounted || _enemyAttacksBlocked) {
      return;
    }
    if (enemy.definition.id == 'elder_demon_lord') {
      final telegraphed = await enemy.playAttackTelegraph();
      if (!telegraphed || !enemy.isMounted || _enemyAttacksBlocked) {
        return;
      }
    }
    final damage = controller.rollEnemyDamage(enemy.definition);
    _spawnEnemyAttackEffect(_playerDamagePosition());
    player.applyKnockback(attackDirection, distance: 22);
    _showDamageNumber(
      position: _playerDamagePosition(),
      amount: damage,
      isPlayerHit: true,
    );
    final defeated = _applyDamageToPlayer(
      damage,
      source: enemy.definition.name,
    );
    if (!defeated) {
      return;
    }
  }

  Future<void> _handleFireballHit(
    EnemyComponent enemy,
    Vector2 hitDirection,
  ) async {
    if (!enemy.isMounted) {
      return;
    }
    final damage = controller.rollPlayerDamage(enemy.definition.defense) + 6;
    enemy.applyKnockback(hitDirection, distance: 20);
    _showDamageNumber(
      position: _enemyDamagePosition(enemy),
      amount: damage,
      isPlayerHit: false,
    );
    final defeated = await enemy.receiveDamage(damage);
    if (!defeated) {
      controller.setHudMessage('火球命中 ${enemy.definition.name}，造成 $damage 點傷害。');
    }
  }

  Vector2 _enemyDamagePosition(EnemyComponent enemy) {
    final body = enemy.bodyRect;
    return Vector2(body.center.dx, body.top - 10);
  }

  Vector2 _playerDamagePosition() {
    final body = player.bodyRect;
    return Vector2(body.center.dx, body.top - 12);
  }

  void _showDamageNumber({
    required Vector2 position,
    required int amount,
    required bool isPlayerHit,
  }) {
    if (amount <= 0) {
      return;
    }
    _sceneRoot.add(
      DamageNumberEffect(
        amount: amount,
        isPlayerHit: isPlayerHit,
        position: position,
      ),
    );
  }

  void _maybeShowEquipmentPickupText() {
    final event = controller.latestEquipmentPickup;
    if (event == null || event.serial <= _seenEquipmentPickupSerial) {
      return;
    }
    _seenEquipmentPickupSerial = event.serial;
    final color = switch (event.rarity) {
      ItemRarity.common => const Color(0xFFE8EDF8),
      ItemRarity.uncommon => const Color(0xFF9FFFB2),
      ItemRarity.rare => const Color(0xFF82DBFF),
      ItemRarity.epic => const Color(0xFFE7A9FF),
      ItemRarity.legendary => const Color(0xFFFFDC86),
    };
    final body = player.bodyRect;
    _sceneRoot.add(
      FloatingTextEffect(
        text: event.itemName,
        color: color,
        position: Vector2(body.center.dx, body.top - 22),
      ),
    );
  }

  void _spawnEnemyAttackEffect(Vector2 position) {
    _sceneRoot.add(EnemyAttackEffect(position: position));
  }

  bool _applyDamageToPlayer(int damage, {required String source}) {
    final defeated = controller.applyPlayerDamage(
      damage,
      source: source,
    );
    if (defeated) {
      final safeSpawn =
          _spawnPoints[controller.currentSpawnId] ?? Vector2(64, 64);
      player.snapTo(safeSpawn);
    }
    return defeated;
  }

  void _tickCombatCooldowns(double dt) {
    _contactDamageCooldown.removeWhere((enemy, cooldown) {
      if (!enemy.isMounted) {
        return true;
      }
      final next = cooldown - dt;
      if (next <= 0) {
        return true;
      }
      _contactDamageCooldown[enemy] = next;
      return false;
    });

    _enemySkillCooldown.removeWhere((enemy, cooldown) {
      if (!enemy.isMounted) {
        return true;
      }
      final next = cooldown - dt;
      if (next <= 0) {
        return true;
      }
      _enemySkillCooldown[enemy] = next;
      return false;
    });
  }

  void _applyTouchCollisionDamage() {
    if (_enemyAttacksBlocked) {
      return;
    }
    for (final enemy in _enemies) {
      if (!enemy.isMounted) {
        continue;
      }
      final onCooldown = (_contactDamageCooldown[enemy] ?? 0) > 0;
      if (onCooldown) {
        continue;
      }
      if (!enemy.bodyRect.overlaps(player.bodyRect.inflate(4))) {
        continue;
      }

      final collisionDamage = math.max(1, (enemy.definition.attack * 0.32).round());
      final pushDirection = Vector2(
        player.bodyRect.center.dx - enemy.bodyRect.center.dx,
        player.bodyRect.center.dy - enemy.bodyRect.center.dy,
      );
      player.applyKnockback(pushDirection, distance: 12);
      _spawnEnemyAttackEffect(_playerDamagePosition());
      _showDamageNumber(
        position: _playerDamagePosition(),
        amount: collisionDamage,
        isPlayerHit: true,
      );
      _applyDamageToPlayer(collisionDamage, source: '${enemy.definition.name} 衝撞');
      _contactDamageCooldown[enemy] = 0.65;
    }
  }

  void _updateEnemySkills() {
    if (_enemyAttacksBlocked) {
      return;
    }
    for (final enemy in _enemies) {
      if (!enemy.isMounted) {
        continue;
      }
      if ((_enemySkillCooldown[enemy] ?? 0) > 0) {
        continue;
      }

      final supportsSkill = enemy.definition.id == 'bat' ||
          enemy.definition.id == 'goblin_chief' ||
          enemy.definition.id == 'elder_demon_lord';
      if (!supportsSkill) {
        continue;
      }

      final direction = Vector2(
        player.bodyRect.center.dx - enemy.bodyRect.center.dx,
        player.bodyRect.center.dy - enemy.bodyRect.center.dy,
      );
      final distance = direction.length;
      final maxRange = enemy.definition.id == 'elder_demon_lord'
          ? _elderDemonLordSkillMaxRange
          : _regularEnemySkillMaxRange;
      if (distance < _bossSkillMinRange || distance > maxRange) {
        continue;
      }

      if (enemy.definition.id == 'elder_demon_lord') {
        unawaited(
          _triggerElderDemonLordSkill(
            enemy,
          ),
        );
        _enemySkillCooldown[enemy] = 6.0;
      } else if (enemy.definition.id == 'goblin_chief') {
        _spawnBossOrbBurst(enemy, direction);
        _enemySkillCooldown[enemy] = 2.1;
      } else {
        _spawnEnemySkillProjectile(enemy, direction);
        _enemySkillCooldown[enemy] = 1.7;
      }
    }
  }

  Future<void> _triggerElderDemonLordSkill(EnemyComponent enemy) async {
    if (!enemy.isMounted || _enemyAttacksBlocked) {
      return;
    }
    final telegraphed = await enemy.playAttackTelegraph();
    if (!telegraphed || !enemy.isMounted || _enemyAttacksBlocked) {
      return;
    }
    final nextPattern = _elderSkillPattern[enemy] ?? _ElderDemonLordSkillPattern.ringBurst;
    switch (nextPattern) {
      case _ElderDemonLordSkillPattern.ringBurst:
        _elderSkillPattern[enemy] = _ElderDemonLordSkillPattern.serpentineBarrage;
        await _spawnSequentialBossOrbBursts(
          enemy,
          waves: 3,
          projectileCount: 14,
          interval: const Duration(milliseconds: 180),
        );
      case _ElderDemonLordSkillPattern.serpentineBarrage:
        _elderSkillPattern[enemy] = _ElderDemonLordSkillPattern.ringBurst;
        await _spawnSerpentineBossBarrage(
          enemy,
          totalShots: 50,
          interval: const Duration(milliseconds: 90),
        );
    }
  }

  Future<void> _spawnSequentialBossOrbBursts(
    EnemyComponent enemy, {
    required int waves,
    required int projectileCount,
    required Duration interval,
  }) async {
    for (var wave = 0; wave < waves; wave += 1) {
      if (!isMounted || !enemy.isMounted || _enemyAttacksBlocked) {
        return;
      }
      final towardPlayer = Vector2(
        player.bodyRect.center.dx - enemy.bodyRect.center.dx,
        player.bodyRect.center.dy - enemy.bodyRect.center.dy,
      );
      _spawnBossOrbBurst(
        enemy,
        towardPlayer,
        projectileCount: projectileCount,
      );
      if (wave < waves - 1) {
        await Future<void>.delayed(interval);
      }
    }
  }

  Future<void> _spawnSerpentineBossBarrage(
    EnemyComponent enemy, {
    required int totalShots,
    required Duration interval,
  }) async {
    for (var shot = 0; shot < totalShots; shot += 1) {
      if (!isMounted || !enemy.isMounted || _enemyAttacksBlocked) {
        return;
      }
      final towardPlayer = Vector2(
        player.bodyRect.center.dx - enemy.bodyRect.center.dx,
        player.bodyRect.center.dy - enemy.bodyRect.center.dy,
      );
      final baseDirection = towardPlayer.length2 == 0
          ? Vector2(0, 1)
          : towardPlayer.normalized();
      final progress = shot / totalShots;
      final angleOffset = math.sin(progress * math.pi * 4) * 0.82;
      final direction = _rotate(baseDirection, angleOffset);
      _spawnEnemySkillProjectile(enemy, direction);

      if (shot < totalShots - 1) {
        await Future<void>.delayed(interval);
      }
    }
  }

  void _spawnBossOrbBurst(
    EnemyComponent enemy,
    Vector2 towardPlayer, {
    int projectileCount = 10,
  }) {
    final base = towardPlayer.length2 == 0 ? Vector2(1, 0) : towardPlayer.normalized();
    final step = (math.pi * 2) / projectileCount;
    final startAngle = math.atan2(base.y, base.x);

    for (var i = 0; i < projectileCount; i += 1) {
      final angle = startAngle + (step * i);
      final direction = Vector2(math.cos(angle), math.sin(angle));
      _spawnEnemySkillProjectile(enemy, direction);
    }
  }

  void _syncFieldBgmForCurrentScene() {
    if (_enemies.any((enemy) => enemy.isMounted && enemy.definition.id == 'goblin_chief')) {
      unawaited(AudioManager.instance.playBossBgm());
      return;
    }
    unawaited(AudioManager.instance.playGameBgm());
  }

  void _spawnEnemySkillProjectile(EnemyComponent enemy, Vector2 direction) {
    final isElderDemonLord = enemy.definition.id == 'elder_demon_lord';
    _sceneRoot.add(
      EnemyOrbProjectileEffect(
        position: Vector2(enemy.bodyRect.center.dx, enemy.bodyRect.center.dy),
        direction: direction,
        canTravelTo: canMoveTo,
        playerBodyRect: () => player.bodyRect,
        speed: isElderDemonLord
            ? _elderDemonLordProjectileSpeed
            : 190,
        maxDistance: isElderDemonLord
            ? _elderDemonLordProjectileDistance
            : 260,
        onHitPlayer: (hitDirection) {
          if (_enemyAttacksBlocked) {
            return;
          }
          final damage = math.max(2, (enemy.definition.attack * 0.68).round());
          player.applyKnockback(hitDirection, distance: 18);
          _spawnEnemyAttackEffect(_playerDamagePosition());
          _showDamageNumber(
            position: _playerDamagePosition(),
            amount: damage,
            isPlayerHit: true,
          );
          _applyDamageToPlayer(damage, source: '${enemy.definition.name} 技能');
        },
      ),
    );
  }

  Future<Component> _buildSceneBackdrop(MapDefinition definition) async {
    final root = PositionComponent(priority: -1000);
    final backgroundColor = switch (definition.id) {
      'ruins' => const Color(0xFFE5D6AE),
      'village' => const Color(0xFFA7D7D8),
      _ => const Color(0xFF1C2F20),
    };

    root.add(
      RectangleComponent(
        position: Vector2.zero(),
        size: mapPixelSize,
        paint: Paint()..color = backgroundColor,
        priority: -2000,
      ),
    );

    await root.add(
      await _punyworldRenderer.buildMap(
        tmjAsset: definition.mapAsset,
        position: Vector2.zero(),
        tileSize: definition.renderTileSize,
        priority: -995,
      ),
    );

    return root;
  }

  Future<void> _loadTeleports(MapDefinition definition) async {
    for (final teleportDef in definition.teleports) {
      final teleport = TeleportComponent(
        position: Vector2(teleportDef.rect.left, teleportDef.rect.top),
        size: Vector2(teleportDef.rect.width, teleportDef.rect.height),
        targetMapId: teleportDef.targetMapId,
        targetSpawnId: teleportDef.targetSpawnId,
        requiredStoryFlag: teleportDef.requiredFlag,
        blockedMessage: teleportDef.blockedMessage,
      );
      _teleports.add(teleport);
      await _sceneRoot.add(teleport);
    }
  }

  Future<void> _loadNpcs(MapDefinition definition) async {
    for (final npcDef in definition.npcs) {
      if (!_isVisible(
        showWhenFlag: npcDef.showWhenFlag,
        hiddenWhenFlag: npcDef.hiddenWhenFlag,
      )) {
        continue;
      }
      final npc = NpcComponent(
        npcId: npcDef.id,
        interactionLabel: '與 ${npcDef.label} 對話',
        spritePath: npcDef.spritePath,
        idleFrames: npcDef.idleFrames,
        position: Vector2(npcDef.x, npcDef.y),
        size: Vector2(40, 48),
        onInteract: () async {
          controller.startDialog(_buildNpcDialog(npcDef.id));
        },
      );
      _interactables.add(npc);
      await _sceneRoot.add(npc);
    }
  }

  Future<void> _loadEnemies(MapDefinition definition) async {
    for (final enemyDef in definition.enemies) {
      if (!_isVisible(
        showWhenFlag: enemyDef.showWhenFlag,
        hiddenWhenFlag: enemyDef.hiddenWhenFlag,
      )) {
        continue;
      }
      final enemyData = enemyCatalog[enemyDef.enemyId];
      if (enemyData == null) {
        continue;
      }
      await _spawnEnemy(enemyDef, enemyData);
    }
  }

  Future<void> _spawnEnemy(
    SceneEnemyDefinition enemyDef,
    EnemyDefinition baseEnemy,
  ) async {
    if (_enemies.where((enemy) => enemy.isMounted).length >= _maxActiveEnemies) {
      return;
    }

    final spawnPosition = _resolveEnemySpawnPosition(
      initial: Vector2(enemyDef.x, enemyDef.y),
      isBoss: enemyDef.isBoss,
    );
    if (spawnPosition == null) {
      return;
    }

    final scaled = _scaledEnemy(baseEnemy);
    final enemySize = enemyDef.isBoss ? Vector2(72, 84) : Vector2(40, 48);
    final enemy = EnemyComponent(
      position: spawnPosition,
      size: enemySize,
      definition: scaled,
      player: player,
      canMoveTo: _canEnemyMoveTo,
      findPath: _findEnemyPath,
      onAttackPlayer: _handleEnemyAttack,
      onDefeated: (enemy) async {
        _enemies.remove(enemy);
        _enemySceneIds.remove(enemy);
        controller.onEnemyDefeated(
          enemy.definition,
          defeatedFlag: enemyDef.hiddenWhenFlag,
          messagePrefix: enemyDef.label,
        );
        if (enemyDef.isBoss) {
          unawaited(AudioManager.instance.playGameBgm());
        }
        enemy.removeFromParent();
        if (enemyDef.canRespawn && !enemyDef.isBoss && isMounted) {
          _scheduleRespawn(enemyDef, baseEnemy);
        }
      },
    );
    _enemies.add(enemy);
    _enemySceneIds[enemy] = enemyDef.id;
    await _sceneRoot.add(enemy);
    if (enemyDef.isBoss) {
      unawaited(AudioManager.instance.playBossBgm());
    }
  }

  EnemyDefinition _scaledEnemy(EnemyDefinition baseEnemy) {
    final rand = math.Random();
    final deltaRange = baseEnemy.isBoss ? 2 : 1;
    final rawOffset = rand.nextInt(deltaRange * 2 + 1) - deltaRange;
    final target = controller.level + rawOffset;
    final minLevel = math.max(1, controller.level - 2);
    final maxLevel = controller.level + 2;
    final enemyLevel = target.clamp(minLevel, maxLevel);
    final isBoss = baseEnemy.isBoss;
    final growth = isBoss ? 0.17 : 0.1;
    final defenseGrowth = isBoss ? 0.12 : 0.08;
    final expGrowth = isBoss ? 0.22 : 0.14;
    final mul = 1 + ((enemyLevel - 1) * growth);
    final hpMul = isBoss ? (mul * 1.35) : mul;
    final atkMul = isBoss ? (mul * 1.2) : mul;
    return EnemyDefinition(
      id: baseEnemy.id,
      name: '${baseEnemy.name} Lv.$enemyLevel',
      maxHp: (baseEnemy.maxHp * hpMul).round(),
      attack: (baseEnemy.attack * atkMul).round(),
      defense: (baseEnemy.defense * (1 + (enemyLevel - 1) * defenseGrowth)).round(),
      moveSpeed: baseEnemy.moveSpeed,
      aggroRange: baseEnemy.aggroRange,
      attackRange: baseEnemy.attackRange,
      attackCooldown: baseEnemy.attackCooldown,
      experienceReward: (baseEnemy.experienceReward * (1 + (enemyLevel - 1) * expGrowth)).round(),
      aggressive: baseEnemy.aggressive,
      spriteSheet: baseEnemy.spriteSheet,
      rewardItemId: baseEnemy.rewardItemId,
      rewardFlag: baseEnemy.rewardFlag,
      minGold: (baseEnemy.minGold * mul).round(),
      maxGold: (baseEnemy.maxGold * mul).round(),
      isBoss: baseEnemy.isBoss,
    );
  }

  void _scheduleRespawn(SceneEnemyDefinition enemyDef, EnemyDefinition baseEnemy) {
    final delay = Duration(seconds: 7 + math.Random().nextInt(8));
    final timer = dart_async.Timer(delay, () {
      if (!isMounted || _activeDefinition == null) {
        return;
      }
      if (_activeDefinition!.id != controller.currentMapId) {
        return;
      }
      if (!_isVisible(showWhenFlag: enemyDef.showWhenFlag, hiddenWhenFlag: enemyDef.hiddenWhenFlag)) {
        return;
      }
      unawaited(_spawnEnemy(enemyDef, baseEnemy));
    });
    _pendingRespawns.add(_PendingRespawn(timer));
  }

  Vector2? _resolveEnemySpawnPosition({
    required Vector2 initial,
    required bool isBoss,
  }) {
    final bodySize = isBoss ? const Size(36, 46) : const Size(20, 30);
    Rect bodyAt(Vector2 pos) => Rect.fromLTWH(
          pos.x + 10,
          pos.y + 14,
          bodySize.width,
          bodySize.height,
        );

    final initialRect = bodyAt(initial);
    if (canMoveTo(initialRect) && !_isSpawnOverlapping(initialRect)) {
      return initial;
    }

    final offsets = <Vector2>[];
    for (var ring = 1; ring <= 4; ring += 1) {
      final r = ring * 16.0;
      offsets.addAll([
        Vector2(r, 0),
        Vector2(-r, 0),
        Vector2(0, r),
        Vector2(0, -r),
        Vector2(r, r),
        Vector2(-r, r),
        Vector2(r, -r),
        Vector2(-r, -r),
      ]);
    }

    for (final offset in offsets) {
      final candidate = initial + offset;
      final rect = bodyAt(candidate);
      if (!canMoveTo(rect) || _isSpawnOverlapping(rect)) {
        continue;
      }
      return candidate;
    }
    return null;
  }

  bool _isSpawnOverlapping(Rect rect) {
    if (rect.overlaps(player.bodyRect.inflate(8))) {
      return true;
    }
    for (final enemy in _enemies) {
      if (!enemy.isMounted) {
        continue;
      }
      if (enemy.bodyRect.inflate(4).overlaps(rect)) {
        return true;
      }
    }
    return false;
  }

  List<Vector2> _findEnemyPath(Rect fromBodyRect, Rect targetBodyRect) {
    final start = _toGrid(fromBodyRect.center);
    final goal = _toGrid(targetBodyRect.center);
    final width = fromBodyRect.width;
    final height = fromBodyRect.height;

    final targetCell = _pickNearestWalkableTarget(goal, width: width, height: height);
    if (targetCell == null) {
      return const <Vector2>[];
    }

    final open = <_PathCell>[start];
    final cameFrom = <_PathCell, _PathCell>{};
    final gScore = <_PathCell, double>{start: 0};
    final fScore = <_PathCell, double>{start: _heuristic(start, targetCell)};
    final closed = <_PathCell>{};

    var iterations = 0;
    while (open.isNotEmpty && iterations < 2400) {
      iterations += 1;
      _PathCell current = open.first;
      for (final candidate in open.skip(1)) {
        if ((fScore[candidate] ?? double.infinity) <
            (fScore[current] ?? double.infinity)) {
          current = candidate;
        }
      }

      if (current == targetCell) {
        return _reconstructPath(cameFrom, current)
            .skip(1)
            .map((cell) => _cellCenter(cell))
            .toList();
      }

      open.remove(current);
      closed.add(current);

      for (final neighbor in _neighbors(current)) {
        if (closed.contains(neighbor) ||
            !_isWalkableCell(neighbor, width: width, height: height)) {
          continue;
        }

        final diagonal = neighbor.x != current.x && neighbor.y != current.y;
        if (diagonal) {
          final n1 = _PathCell(neighbor.x, current.y);
          final n2 = _PathCell(current.x, neighbor.y);
          if (!_isWalkableCell(n1, width: width, height: height) ||
              !_isWalkableCell(n2, width: width, height: height)) {
            continue;
          }
        }

        final stepCost = diagonal ? 1.41421356237 : 1.0;
        final tentative = (gScore[current] ?? double.infinity) + stepCost;
        if (tentative >= (gScore[neighbor] ?? double.infinity)) {
          continue;
        }

        cameFrom[neighbor] = current;
        gScore[neighbor] = tentative;
        fScore[neighbor] = tentative + _heuristic(neighbor, targetCell);
        if (!open.contains(neighbor)) {
          open.add(neighbor);
        }
      }
    }

    return const <Vector2>[];
  }

  _PathCell? _pickNearestWalkableTarget(
    _PathCell target, {
    required double width,
    required double height,
  }) {
    if (_isWalkableCell(target, width: width, height: height)) {
      return target;
    }
    for (var radius = 1; radius <= 5; radius += 1) {
      _PathCell? best;
      var bestDist = double.infinity;
      for (var dx = -radius; dx <= radius; dx += 1) {
        for (var dy = -radius; dy <= radius; dy += 1) {
          final candidate = _PathCell(target.x + dx, target.y + dy);
          if (!_isWalkableCell(candidate, width: width, height: height)) {
            continue;
          }
          final dist = _heuristic(candidate, target);
          if (dist < bestDist) {
            bestDist = dist;
            best = candidate;
          }
        }
      }
      if (best != null) {
        return best;
      }
    }
    return null;
  }

  List<_PathCell> _neighbors(_PathCell cell) {
    return <_PathCell>[
      _PathCell(cell.x + 1, cell.y),
      _PathCell(cell.x - 1, cell.y),
      _PathCell(cell.x, cell.y + 1),
      _PathCell(cell.x, cell.y - 1),
      _PathCell(cell.x + 1, cell.y + 1),
      _PathCell(cell.x + 1, cell.y - 1),
      _PathCell(cell.x - 1, cell.y + 1),
      _PathCell(cell.x - 1, cell.y - 1),
    ];
  }

  bool _isWalkableCell(
    _PathCell cell, {
    required double width,
    required double height,
  }) {
    final center = _cellCenter(cell);
    final rect = Rect.fromCenter(
      center: Offset(center.x, center.y),
      width: width,
      height: height,
    );
    return canMoveTo(rect);
  }

  _PathCell _toGrid(Offset worldPoint) {
    return _PathCell(
      (worldPoint.dx / _enemyPathGrid).floor(),
      (worldPoint.dy / _enemyPathGrid).floor(),
    );
  }

  Vector2 _cellCenter(_PathCell cell) {
    return Vector2(
      (cell.x + 0.5) * _enemyPathGrid,
      (cell.y + 0.5) * _enemyPathGrid,
    );
  }

  double _heuristic(_PathCell a, _PathCell b) {
    final dx = (a.x - b.x).abs();
    final dy = (a.y - b.y).abs();
    return math.max(dx, dy).toDouble();
  }

  List<_PathCell> _reconstructPath(
    Map<_PathCell, _PathCell> cameFrom,
    _PathCell current,
  ) {
    final path = <_PathCell>[current];
    var cursor = current;
    while (cameFrom.containsKey(cursor)) {
      final parent = cameFrom[cursor]!;
      path.add(parent);
      cursor = parent;
    }
    return path.reversed.toList();
  }

  Future<void> _loadChests(MapDefinition definition) async {
    for (final chestDef in definition.chests) {
      if (!_isVisible(
        showWhenFlag: chestDef.showWhenFlag,
        hiddenWhenFlag: chestDef.hiddenWhenFlag,
      )) {
        continue;
      }
      late final ChestComponent chest;
      final openedFlagKey = 'chest_${chestDef.id}_opened';
      if (controller.flag(openedFlagKey)) {
        continue;
      }
      chest = ChestComponent(
        chestId: chestDef.id,
        position: Vector2(chestDef.x, chestDef.y),
        size: chestDef.hiddenTrigger ? Vector2(18, 18) : Vector2(28, 28),
        showSprite: !chestDef.hiddenTrigger,
        onInteract: () async {
          final flagKey = 'chest_${chestDef.id}_opened';
          if (controller.flag(flagKey)) {
            controller.setHudMessage('這個寶箱已經空了。');
            return;
          }
          final rewardItemIds = <String>[chestDef.itemId, ...chestDef.extraItemIds];
          for (final itemId in rewardItemIds) {
            controller.addItem(itemId);
            await controller.showChestRewardDialog(
              chestId: chestDef.id,
              itemId: itemId,
              itemName: itemCatalog[itemId]?.name ?? itemId,
            );
          }
          controller.setFlag(flagKey, true);
          if (chestDef.giveFlag case final giveFlag?) {
            controller.setFlag(giveFlag, true);
            await _spawnEnemiesUnlockedByFlag(giveFlag);
          }
          _interactables.remove(chest);
          if (chest.isMounted) {
            chest.removeFromParent();
          }
          controller.setHudMessage(
            '獲得 ${rewardItemIds.map((itemId) => itemCatalog[itemId]?.name ?? itemId).join('、')}。',
          );
        },
      );
      _interactables.add(chest);
      await _sceneRoot.add(chest);
    }
  }

  Future<void> _spawnEnemiesUnlockedByFlag(String flagKey) async {
    final definition = _activeDefinition;
    if (definition == null) {
      return;
    }
    _enemySceneIds.removeWhere((enemy, _) => !enemy.isMounted);
    for (final enemyDef in definition.enemies) {
      if (enemyDef.showWhenFlag != flagKey) {
        continue;
      }
      if (!_isVisible(
        showWhenFlag: enemyDef.showWhenFlag,
        hiddenWhenFlag: enemyDef.hiddenWhenFlag,
      )) {
        continue;
      }
      if (_enemySceneIds.containsValue(enemyDef.id)) {
        continue;
      }
      final enemyData = enemyCatalog[enemyDef.enemyId];
      if (enemyData == null) {
        continue;
      }
      await _spawnEnemy(enemyDef, enemyData);
    }
  }

  DialogTree _buildNpcDialog(String npcId) {
    switch (npcId) {
      case 'merchant':
        final claimedGift = controller.flag('merchant_gift_claimed');
        return DialogTree(
          startNodeId: 'start',
          nodes: {
            'start': DialogNode(
              id: 'start',
              speaker: '商人',
              text: claimedGift
                  ? '補給都準備好了，缺什麼就說。'
                  : '新冒險家？拿著這瓶藥水，別在村外第一戰就倒下。',
              choices: claimedGift
                  ? const [
                      DialogChoice(label: '買治療藥水 (20G)', actionKey: 'buy_potion', nextNodeId: 'start'),
                      DialogChoice(label: '買魔力藥水 (28G)', actionKey: 'buy_mana_potion', nextNodeId: 'start'),
                      DialogChoice(label: '賣治療藥水', actionKey: 'sell_potion', nextNodeId: 'start'),
                      DialogChoice(label: '賣魔力藥水', actionKey: 'sell_mana_potion', nextNodeId: 'start'),
                      DialogChoice(label: '賣一件裝備', actionKey: 'sell_equipment', nextNodeId: 'start'),
                      DialogChoice(label: '離開'),
                    ]
                  : const [
                      DialogChoice(
                        label: '收下藥水',
                        giveItemId: 'potion',
                        setFlagKey: 'merchant_gift_claimed',
                        nextNodeId: 'gift',
                      ),
                      DialogChoice(label: '先逛逛'),
                    ],
            ),
            'gift': const DialogNode(
              id: 'gift',
              speaker: '商人',
              text: '好好保管。東邊的石門一開，村子就靠你了。',
            ),
          },
        );
      case 'scout':
        return DialogTree(
          startNodeId: 'start',
          nodes: {
            'start': DialogNode(
              id: 'start',
              speaker: '斥候',
              text: controller.flag('can_escape_forest')
                  ? '出口迷霧散了！趕緊回村莊報平安。'
                  : controller.flag('has_key_01')
                  ? '你進了迷霧森林會不斷繞回來，先找迷霧羅盤，再打倒首領。'
                  : '右下木橋旁補給箱有舊鑰匙，先找到它再出發。',
            ),
          },
        );
      case 'trader_wanderer':
        return const DialogTree(
          startNodeId: 'start',
          nodes: {
            'start': DialogNode(
              id: 'start',
              speaker: '迷霧商旅',
              text: '困在迷霧裡了吧？我這裡有貨，隱藏神裝只能打怪掉，我可不賣。',
              choices: [
                DialogChoice(label: '買武器箱 (120G)', actionKey: 'buy_weapon_crate', nextNodeId: 'start'),
                DialogChoice(label: '買防具箱 (120G)', actionKey: 'buy_armor_crate', nextNodeId: 'start'),
                DialogChoice(label: '賣一件裝備', actionKey: 'sell_equipment', nextNodeId: 'start'),
                DialogChoice(label: '離開'),
              ],
            ),
          },
        );
      case 'ruin_spirit':
        return DialogTree(
          startNodeId: 'start',
          nodes: {
            'start': DialogNode(
              id: 'start',
              speaker: '遺跡精靈',
              text: controller.flag('can_escape_forest')
                  ? '羅盤與紋章共鳴成功，出口已穩定。快回村莊！'
                  : controller.flag('beat_forest_boss')
                  ? '你已擊敗首領，還差迷霧羅盤才能離開。'
                  : '出口被迷霧詛咒，必須先取回羅盤，再擊敗迷霧首領。',
            ),
          },
        );
      case 'elder':
      default:
        if (controller.flag('report_to_elder_prompted')) {
          return DialogTree(
            startNodeId: 'reveal_1',
            nodes: {
              'reveal_1': const DialogNode(
                id: 'reveal_1',
                speaker: '長老',
                text: '你回來了啊……而且真的替村子掃除了迷霧中的魔王。呵呵……哈哈哈哈哈！',
                nextNodeId: 'reveal_2',
              ),
              'reveal_2': const DialogNode(
                id: 'reveal_2',
                speaker: '長老',
                text: '你以為自己救了所有人嗎？太天真了。就在你被困在迷霧森林、拼命尋找羅盤的這段時間裡，我已經將整個村莊獻給了真正的大魔王。',
                nextNodeId: 'reveal_3',
              ),
              'reveal_3': const DialogNode(
                id: 'reveal_3',
                speaker: '長老',
                text: '沒錯，商人、斥候、還有那些曾經向你求助的人，他們的靈魂，全都成了契約的一部分。',
                nextNodeId: 'reveal_4',
              ),
              'reveal_4': const DialogNode(
                id: 'reveal_4',
                speaker: '長老',
                text: '你一定很想問我為什麼這麼做吧？因為這個腐朽又無能的世界，從來沒有把我的兒子還給我。',
                nextNodeId: 'reveal_5',
              ),
              'reveal_5': const DialogNode(
                id: 'reveal_5',
                speaker: '長老',
                text: '所以我向魔王低頭，我用整座村子的生命作為代價，只為換回一次讓他重返人世的機會。',
                nextNodeId: 'reveal_6',
              ),
              'reveal_6': const DialogNode(
                id: 'reveal_6',
                speaker: '長老',
                text: '而現在，契約還差最後一步。',
                nextNodeId: 'reveal_7',
              ),
              'reveal_7': const DialogNode(
                id: 'reveal_7',
                speaker: '長老',
                text: '那就是你。',
                nextNodeId: 'reveal_8',
              ),
              'reveal_8': const DialogNode(
                id: 'reveal_8',
                speaker: '長老',
                text: '你的到來、你的奮戰、你的勝利，全都只是我儀式的一部分。你不是英雄，你只是被我引導到這裡的祭品罷了！',
                nextNodeId: 'reveal_9',
              ),
              'reveal_9': const DialogNode(
                id: 'reveal_9',
                speaker: '長老',
                text: '來吧，讓你親眼見識我捨棄人類之身後，真正獲得的力量！',
                nextNodeId: 'reveal_final',
              ),
              'reveal_final': const DialogNode(
                id: 'reveal_final',
                speaker: '長老',
                text: '大魔王，降臨！',
                setFlagOnEnter: 'elder_boss_triggered',
              ),
            },
          );
        }
        final hasKey = controller.flag('has_key_01');
        final defeatedChief = controller.flag('beat_goblin_chief');
        return DialogTree(
          startNodeId: 'start',
          nodes: {
            'start': DialogNode(
              id: 'start',
              speaker: '長老',
            text: controller.flag('can_escape_forest')
              ? '你打破了迷霧迴圈，村子有救了！'
              : defeatedChief
              ? '你擊倒了首領，但還沒離開迷霧，先拿到羅盤。'
                  : hasKey
              ? '很好，舊鑰匙在你手上了。進入迷霧森林後，目標是拯救村莊。'
                  : '先去商人那裡拿補給，再去右下方找到舊鑰匙。別空手往外衝。',
            nextNodeId: controller.flag('can_escape_forest')
              ? 'finish'
              : defeatedChief
                  ? 'finish'
                  : (hasKey ? 'ready' : 'choice'),
              setFlagOnEnter: 'intro_seen',
            ),
            'choice': const DialogNode(
              id: 'choice',
              speaker: '長老',
              text: '出發之前，要不要先來場模擬戰？',
              choices: [
                DialogChoice(label: '好，說明一下', nextNodeId: 'training'),
                DialogChoice(label: '先不用', nextNodeId: 'finish'),
              ],
            ),
            'training': const DialogNode(
              id: 'training',
              speaker: '長老',
              text: '走到怪物附近時要立刻拉開位置，用 J 揮劍，別被主動怪包圍。',
              nextNodeId: 'finish',
            ),
            'ready': const DialogNode(
              id: 'ready',
              speaker: '長老',
              text: '迷霧會把你困住，直到你帶回關鍵道具並擊敗首領。',
              nextNodeId: 'finish',
            ),
            'finish': const DialogNode(
              id: 'finish',
              speaker: '長老',
              text: '記得按 J 攻擊、Space 互動，Esc 可以打開選單。目標是拯救村莊。',
            ),
          },
        );
    }
  }
}

class _PendingRespawn {
  const _PendingRespawn(this.timer);

  final dart_async.Timer timer;
}

enum _FireballMode {
  basic,
  flamethrower,
  inferno,
}

enum _ElderDemonLordSkillPattern {
  ringBurst,
  serpentineBarrage,
}

class _PathCell {
  const _PathCell(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _PathCell && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}
