import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components/actors/enemy_component.dart';
import '../components/actors/npc_component.dart';
import '../components/actors/player_component.dart';
import '../components/effects/player_attack_effect.dart';
import '../components/objects/chest_component.dart';
import '../components/objects/interactable_entity.dart';
import '../components/objects/teleport_component.dart';
import '../state/game_state_controller.dart';
import '../state/models/game_models.dart';
import 'map_definition.dart';

class WorldMapManager extends Component {
  WorldMapManager({
    required this.player,
    required this.controller,
    required this.onTeleportTriggered,
  });

  final PlayerComponent player;
  final GameStateController controller;
  final Future<void> Function(String mapId, String spawnId) onTeleportTriggered;

  final Component _sceneRoot = Component();
  final List<Rect> _collisionRects = <Rect>[];
  final List<InteractableEntity> _interactables = <InteractableEntity>[];
  final List<EnemyComponent> _enemies = <EnemyComponent>[];
  final List<TeleportComponent> _teleports = <TeleportComponent>[];
  final Map<String, Vector2> _spawnPoints = <String, Vector2>{};

  Vector2 mapPixelSize = Vector2.zero();
  bool _teleportLatch = false;

  @override
  Future<void> onLoad() async {
    await add(_sceneRoot);
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
    _teleports.clear();
    _spawnPoints.clear();
    _teleportLatch = false;

    mapPixelSize = Vector2(
      definition.sceneSize.x,
      definition.sceneSize.y,
    );
    await _sceneRoot.add(_buildSceneBackdrop(definition));

    _spawnPoints.addAll(
      definition.spawnPoints.map(
        (key, value) => MapEntry(key, Vector2(value.x, value.y)),
      ),
    );
    _collisionRects.addAll(definition.blockingRects);
    await _loadTeleports(definition);
    await _loadNpcs(definition);
    await _loadEnemies(definition);
    await _loadChests(definition);

    if (player.parent != null) {
      player.removeFromParent();
    }
    await _sceneRoot.add(player);

    final desiredSpawnId = spawnId ?? definition.defaultSpawnId;
    final spawnPosition = explicitPlayerPosition ?? _spawnPoints[desiredSpawnId] ?? Vector2(64, 64);
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

  Future<void> interactInFrontOfPlayer() async {
    final probe = player.interactionProbe;
    final candidates = _interactables.where((entity) => entity.interactionBounds.overlaps(probe)).toList();
    if (candidates.isEmpty) {
      controller.setHudMessage('前方沒有可互動物件。');
      return;
    }
    candidates.sort((a, b) =>
        (a.interactionBounds.center - probe.center).distanceSquared.compareTo(
              (b.interactionBounds.center - probe.center).distanceSquared,
            ));
    await candidates.first.interact();
  }

  Future<void> playerAttack() async {
    if (!player.tryAttack()) {
      return;
    }
    await _sceneRoot.add(
      PlayerAttackEffect(
        facing: player.facing,
        position: Vector2(player.attackHitbox.center.dx, player.attackHitbox.center.dy),
      ),
    );
    final hitEnemies = _enemies.where((enemy) => enemy.bodyRect.overlaps(player.attackHitbox)).toList();
    if (hitEnemies.isEmpty) {
      controller.setHudMessage('你揮空了。');
      return;
    }

    for (final enemy in hitEnemies) {
      final damage = controller.rollPlayerDamage(enemy.definition.defense);
      final defeated = await enemy.receiveDamage(damage);
      if (!defeated) {
        controller.setHudMessage('命中 ${enemy.definition.name}，造成 $damage 點傷害。');
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final activeTeleport = _teleports.where(
      (teleport) => teleport.toAbsoluteRect().overlaps(player.bodyRect),
    );
    final currentTeleport = activeTeleport.isEmpty ? null : activeTeleport.first;
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
        return;
      }
    }

    _teleportLatch = true;
    onTeleportTriggered(currentTeleport.targetMapId, currentTeleport.targetSpawnId);
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

  bool _canEnemyMoveTo(Rect targetRect) {
    if (targetRect.overlaps(player.bodyRect.inflate(6))) {
      return false;
    }
    return canMoveTo(targetRect);
  }

  Future<void> _handleEnemyAttack(EnemyComponent enemy) async {
    final damage = controller.rollEnemyDamage(enemy.definition);
    final defeated = controller.applyPlayerDamage(damage, source: enemy.definition.name);
    if (!defeated) {
      return;
    }
    final safeSpawn = _spawnPoints[controller.currentSpawnId] ?? Vector2(64, 64);
    player.snapTo(safeSpawn);
  }

  Component _buildSceneBackdrop(MapDefinition definition) {
    final root = PositionComponent(priority: -1000);
    final backgroundColor = switch (definition.id) {
      'ruins' => const Color(0xFF1A1A24),
      _ => const Color(0xFF1C2F20),
    };

    root.add(
      RectangleComponent(
        position: Vector2.zero(),
        size: mapPixelSize,
        paint: Paint()..color = backgroundColor,
      ),
    );

    switch (definition.id) {
      case 'village':
        _addVillageBackdrop(root);
      case 'ruins':
        _addRuinsBackdrop(root);
    }

    return root;
  }

  void _addVillageBackdrop(PositionComponent root) {
    final decorativeRects = <({Rect rect, Color color})>[
      (rect: const Rect.fromLTWH(0, 0, 1440, 192), color: const Color(0xFF183724)),
      (rect: const Rect.fromLTWH(0, 736, 1440, 224), color: const Color(0xFF21452B)),
      (rect: const Rect.fromLTWH(160, 416, 1120, 144), color: const Color(0xFF6D5739)),
      (rect: const Rect.fromLTWH(192, 448, 1056, 80), color: const Color(0xFF9A7C4D)),
      (rect: const Rect.fromLTWH(224, 468, 992, 36), color: const Color(0xFFBEA06A)),
      (rect: const Rect.fromLTWH(112, 600, 300, 80), color: const Color(0xFF1D4F69)),
      (rect: const Rect.fromLTWH(96, 616, 332, 46), color: const Color(0xFF338AB2)),
      (rect: const Rect.fromLTWH(544, 224, 352, 448), color: const Color(0xFF8B6B3F)),
      (rect: const Rect.fromLTWH(576, 256, 288, 384), color: const Color(0xFFBDA06A)),
      (rect: const Rect.fromLTWH(304, 248, 176, 152), color: const Color(0xFF6F5136)),
      (rect: const Rect.fromLTWH(320, 264, 144, 120), color: const Color(0xFFC5A16D)),
      (rect: const Rect.fromLTWH(912, 248, 176, 152), color: const Color(0xFF6F5136)),
      (rect: const Rect.fromLTWH(928, 264, 144, 120), color: const Color(0xFFC5A16D)),
      (rect: const Rect.fromLTWH(160, 256, 160, 576), color: const Color(0xFF295E43)),
      (rect: const Rect.fromLTWH(1120, 224, 160, 608), color: const Color(0xFF295E43)),
      (rect: const Rect.fromLTWH(1040, 320, 160, 128), color: const Color(0xFF5D5C68)),
      (rect: const Rect.fromLTWH(1048, 328, 144, 112), color: const Color(0xFF928F9C)),
      (rect: const Rect.fromLTWH(1088, 304, 64, 16), color: const Color(0xFFD9D4C7)),
      (rect: const Rect.fromLTWH(1088, 432, 64, 16), color: const Color(0xFFD9D4C7)),
    ];

    for (final item in decorativeRects) {
      root.add(
        RectangleComponent(
          position: Vector2(item.rect.left, item.rect.top),
          size: Vector2(item.rect.width, item.rect.height),
          paint: Paint()..color = item.color,
        ),
      );
    }

    for (var index = 0; index < 10; index++) {
      root.add(
        CircleComponent(
          radius: 18 + (index % 3) * 6,
          position: Vector2(210 + index * 96, 150 + (index.isEven ? 24 : 0)),
          paint: Paint()..color = const Color(0xAA6D8F3B),
        ),
      );
    }

    for (var index = 0; index < 12; index++) {
      root.add(
        CircleComponent(
          radius: 12 + (index % 2) * 4,
          position: Vector2(260 + index * 76, 610 + (index.isEven ? 10 : -2)),
          paint: Paint()..color = const Color(0xAA84B65B),
        ),
      );
    }

    for (var index = 0; index < 18; index++) {
      root.add(
        RectangleComponent(
          position: Vector2(236 + index * 48, 482 + (index.isEven ? -4 : 10)),
          size: Vector2(18, 8),
          paint: Paint()..color = const Color(0x80DCC6A4),
        ),
      );
    }

    for (var index = 0; index < 6; index++) {
      root.add(
        RectangleComponent(
          position: Vector2(360 + index * 118, 394),
          size: Vector2(14, 54),
          paint: Paint()..color = const Color(0xFF4B3423),
        ),
      );
      root.add(
        CircleComponent(
          radius: 9,
          position: Vector2(367 + index * 118, 386),
          paint: Paint()..color = const Color(0xFFE0BF6A),
        ),
      );
    }

    final flowerColors = <Color>[
      const Color(0xFFE76FAD),
      const Color(0xFFF4D35E),
      const Color(0xFF8FE388),
      const Color(0xFF72DDF7),
    ];
    for (var index = 0; index < 28; index++) {
      root.add(
        CircleComponent(
          radius: 4,
          position: Vector2(204 + (index % 14) * 22, 690 + (index ~/ 14) * 18),
          paint: Paint()..color = flowerColors[index % flowerColors.length],
        ),
      );
    }
  }

  void _addRuinsBackdrop(PositionComponent root) {
    final decorativeRects = <({Rect rect, Color color})>[
      (rect: const Rect.fromLTWH(16, 16, 448, 448), color: const Color(0xFF14141D)),
      (rect: const Rect.fromLTWH(32, 32, 416, 416), color: const Color(0xFF2A2A34)),
      (rect: const Rect.fromLTWH(64, 64, 352, 352), color: const Color(0xFF3A3A46)),
      (rect: const Rect.fromLTWH(96, 336, 256, 48), color: const Color(0xFF716047)),
      (rect: const Rect.fromLTWH(96, 344, 256, 24), color: const Color(0xFFA68F68)),
      (rect: const Rect.fromLTWH(112, 112, 256, 32), color: const Color(0xFF5E5A67)),
      (rect: const Rect.fromLTWH(160, 256, 160, 32), color: const Color(0xFF78674E)),
      (rect: const Rect.fromLTWH(160, 288, 32, 96), color: const Color(0xFF78674E)),
      (rect: const Rect.fromLTWH(288, 288, 32, 96), color: const Color(0xFF78674E)),
      (rect: const Rect.fromLTWH(176, 96, 128, 64), color: const Color(0xFF8E7B57)),
      (rect: const Rect.fromLTWH(96, 176, 48, 112), color: const Color(0xFF4A4A57)),
      (rect: const Rect.fromLTWH(336, 176, 48, 112), color: const Color(0xFF4A4A57)),
      (rect: const Rect.fromLTWH(208, 160, 64, 160), color: const Color(0x4035C2A1)),
    ];

    for (final item in decorativeRects) {
      root.add(
        RectangleComponent(
          position: Vector2(item.rect.left, item.rect.top),
          size: Vector2(item.rect.width, item.rect.height),
          paint: Paint()..color = item.color,
        ),
      );
    }

    for (var index = 0; index < 8; index++) {
      root.add(
        RectangleComponent(
          position: Vector2(72 + index * 40, 80 + (index.isEven ? 8 : 0)),
          size: Vector2(16, 16),
          paint: Paint()..color = const Color(0xCC4A6A58),
        ),
      );
    }

    for (var index = 0; index < 5; index++) {
      root.add(
        RectangleComponent(
          position: Vector2(92 + index * 72, 140),
          size: Vector2(22, 62),
          paint: Paint()..color = const Color(0xFF86818E),
        ),
      );
      root.add(
        RectangleComponent(
          position: Vector2(88 + index * 72, 132),
          size: Vector2(30, 10),
          paint: Paint()..color = const Color(0xFFB0A79A),
        ),
      );
    }

    for (var index = 0; index < 9; index++) {
      root.add(
        CircleComponent(
          radius: 5 + (index % 3),
          position: Vector2(84 + index * 38, 392 + (index.isEven ? 8 : -4)),
          paint: Paint()..color = const Color(0xFF54515C),
        ),
      );
    }

    for (var index = 0; index < 14; index++) {
      root.add(
        RectangleComponent(
          position: Vector2(72 + (index % 7) * 46, 92 + (index ~/ 7) * 260),
          size: Vector2(12, 20),
          paint: Paint()..color = const Color(0x8048D9A8),
        ),
      );
    }

    for (var index = 0; index < 4; index++) {
      root.add(
        CircleComponent(
          radius: 7,
          position: Vector2(126 + index * 92, 326),
          paint: Paint()..color = const Color(0xFFE1AA53),
        ),
      );
      root.add(
        CircleComponent(
          radius: 3,
          position: Vector2(126 + index * 92, 322),
          paint: Paint()..color = const Color(0xFFFFF1B0),
        ),
      );
    }
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
      if (!_isVisible(showWhenFlag: npcDef.showWhenFlag, hiddenWhenFlag: npcDef.hiddenWhenFlag)) {
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
      if (!_isVisible(showWhenFlag: enemyDef.showWhenFlag, hiddenWhenFlag: enemyDef.hiddenWhenFlag)) {
        continue;
      }
      final enemyData = enemyCatalog[enemyDef.enemyId];
      if (enemyData == null) {
        continue;
      }
      final enemy = EnemyComponent(
        position: Vector2(enemyDef.x, enemyDef.y),
        size: enemyDef.enemyId == 'goblin_chief' ? Vector2(56, 64) : Vector2(40, 48),
        definition: enemyData,
        player: player,
        canMoveTo: _canEnemyMoveTo,
        onAttackPlayer: _handleEnemyAttack,
        onDefeated: (enemy) async {
          _enemies.remove(enemy);
          controller.onEnemyDefeated(
            enemy.definition,
            defeatedFlag: enemyDef.hiddenWhenFlag,
            messagePrefix: enemyDef.label,
          );
          enemy.removeFromParent();
        },
      );
      _enemies.add(enemy);
      await _sceneRoot.add(enemy);
    }
  }

  Future<void> _loadChests(MapDefinition definition) async {
    for (final chestDef in definition.chests) {
      if (!_isVisible(showWhenFlag: chestDef.showWhenFlag, hiddenWhenFlag: chestDef.hiddenWhenFlag)) {
        continue;
      }
      final chest = ChestComponent(
        chestId: chestDef.id,
        position: Vector2(chestDef.x, chestDef.y),
        size: Vector2(28, 28),
        onInteract: () async {
          final flagKey = 'chest_${chestDef.id}_opened';
          if (controller.flag(flagKey)) {
            controller.setHudMessage('這個寶箱已經空了。');
            return;
          }
          controller.setFlag(flagKey, true);
          if (chestDef.giveFlag case final giveFlag?) {
            controller.setFlag(giveFlag, true);
          }
          controller.addItem(chestDef.itemId);
          controller.setHudMessage('獲得 ${itemCatalog[chestDef.itemId]?.name ?? chestDef.itemId}。');
        },
      );
      if (controller.flag('chest_${chestDef.id}_opened')) {
        chest.opened = true;
        chest.paint.color = Colors.orange.withValues(alpha: 0.5);
      }
      _interactables.add(chest);
      await _sceneRoot.add(chest);
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
                  ? '補給都準備好了，遺跡裡看到哥布林就別猶豫。'
                  : '新冒險家？拿著這瓶藥水，別在村外第一戰就倒下。',
              choices: claimedGift
                  ? const [
                      DialogChoice(label: '知道了'),
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
              text: controller.flag('has_key_01')
                  ? '你找到鑰匙了。石門就在我身後，裡頭有哥布林守衛。'
                  : '河道北側的補給箱裡藏著舊鑰匙。先拿到它，才能開遺跡大門。',
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
              text: controller.flag('beat_goblin_chief')
                  ? '封印已經穩定，帶著戰利品回村吧。'
                  : '守門者就在前方。擊退它，這片土地才會安寧。',
            ),
          },
        );
      case 'elder':
      default:
        final hasKey = controller.flag('has_key_01');
        final defeatedChief = controller.flag('beat_goblin_chief');
        return DialogTree(
          startNodeId: 'start',
          nodes: {
            'start': DialogNode(
              id: 'start',
              speaker: '長老',
              text: defeatedChief
                  ? '村子得救了。這片遺跡終於安靜下來。'
                  : hasKey
                      ? '很好，舊鑰匙在你手上了。往東邊石門去，結束這場騷動。'
                      : '先去商人那裡拿補給，再去東邊找到舊鑰匙。別空手闖遺跡。',
              nextNodeId: defeatedChief ? 'finish' : (hasKey ? 'ready' : 'choice'),
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
              text: '蝙蝠與哥布林都怕你手上的勇氣。去吧，我會在村裡等你。',
              nextNodeId: 'finish',
            ),
            'finish': const DialogNode(
              id: 'finish',
              speaker: '長老',
              text: '記得按 J 攻擊、Space 互動，Esc 可以打開選單。',
            ),
          },
        );
    }
  }
}
