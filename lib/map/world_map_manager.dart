import 'dart:async';

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
    await _sceneRoot.add(
      PlayerAttackEffect(
        facing: player.facing,
        position: Vector2(
          player.attackHitbox.center.dx,
          player.attackHitbox.center.dy,
        ),
      ),
    );
    final hitEnemies = _enemies
        .where((enemy) => enemy.bodyRect.overlaps(player.attackHitbox))
        .toList();
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

  bool _canEnemyMoveTo(Rect targetRect) {
    if (targetRect.overlaps(player.bodyRect.inflate(6))) {
      return false;
    }
    return canMoveTo(targetRect);
  }

  Future<void> _handleEnemyAttack(EnemyComponent enemy) async {
    final damage = controller.rollEnemyDamage(enemy.definition);
    final defeated = controller.applyPlayerDamage(
      damage,
      source: enemy.definition.name,
    );
    if (!defeated) {
      return;
    }
    final safeSpawn =
        _spawnPoints[controller.currentSpawnId] ?? Vector2(64, 64);
    player.snapTo(safeSpawn);
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
      final enemy = EnemyComponent(
        position: Vector2(enemyDef.x, enemyDef.y),
        size: enemyDef.enemyId == 'goblin_chief'
            ? Vector2(56, 64)
            : Vector2(40, 48),
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
      if (!_isVisible(
        showWhenFlag: chestDef.showWhenFlag,
        hiddenWhenFlag: chestDef.hiddenWhenFlag,
      )) {
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
          controller.setHudMessage(
            '獲得 ${itemCatalog[chestDef.itemId]?.name ?? chestDef.itemId}。',
          );
        },
      );
      if (controller.flag('chest_${chestDef.id}_opened')) {
        chest.opened = true;
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
                  ? const [DialogChoice(label: '知道了')]
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
                  ? '你找到鑰匙了。右側密林出口已經能通行，穿過去就是下一區。'
                  : '右下木橋旁的補給箱裡藏著舊鑰匙。先拿到它，才能打開右側路障。',
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
                  ? '很好，舊鑰匙在你手上了。沿著右側木橋出去，把海灣的騷動壓下來。'
                  : '先去商人那裡拿補給，再去右下方找到舊鑰匙。別空手往外衝。',
              nextNodeId: defeatedChief
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
