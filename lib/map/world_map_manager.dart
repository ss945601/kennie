import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:tiled/tiled.dart';

import '../components/actors/npc_component.dart';
import '../components/actors/player_component.dart';
import '../components/objects/chest_component.dart';
import '../components/objects/interactable_entity.dart';
import '../components/objects/prop_component.dart';
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
    _teleports.clear();
    _spawnPoints.clear();
    _teleportLatch = false;

    final tiled = await TiledComponent.load(definition.tmxAsset, Vector2.all(32));
    await _sceneRoot.add(tiled);

    final tiledMap = tiled.tileMap;
    final map = tiledMap.map;
    mapPixelSize = Vector2(
      map.width * map.tileWidth.toDouble(),
      map.height * map.tileHeight.toDouble(),
    );

    _readSpawnPoints(tiledMap);
    _readCollisionLayer(tiledMap);
    await _readProps(tiledMap);
    await _readTeleports(tiledMap);
    await _readNpcs(tiledMap);
    await _readChests(tiledMap);

    if (player.parent != null) {
      player.removeFromParent();
    }
    await _sceneRoot.add(player);

    final desiredSpawnId = spawnId ?? definition.defaultSpawnId;
    final spawnPosition = explicitPlayerPosition ?? _spawnPoints[desiredSpawnId] ?? Vector2(64, 64);
    player.snapTo(spawnPosition);
    controller.setMapContext(mapId: mapId, spawnId: desiredSpawnId);
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

  @override
  void update(double dt) {
    super.update(dt);
    final currentTeleport = _teleports.firstWhere(
      (teleport) => teleport.toAbsoluteRect().overlaps(player.bodyRect),
      orElse: () => TeleportComponent(
        position: Vector2.all(-9999),
        size: Vector2.zero(),
        targetMapId: '',
        targetSpawnId: '',
      ),
    );
    final hasTeleport = currentTeleport.targetMapId.isNotEmpty;
    if (hasTeleport && !_teleportLatch && !controller.isOverlayBusy) {
      _teleportLatch = true;
      onTeleportTriggered(currentTeleport.targetMapId, currentTeleport.targetSpawnId);
    } else if (!hasTeleport) {
      _teleportLatch = false;
    }
  }

  void _readSpawnPoints(RenderableTiledMap tiledMap) {
    final layer = tiledMap.getLayer<ObjectGroup>('SpawnPoints');
    for (final object in layer?.objects ?? const <TiledObject>[]) {
      _spawnPoints[object.name] = Vector2(object.x, object.y);
    }
  }

  void _readCollisionLayer(RenderableTiledMap tiledMap) {
    final layer = tiledMap.getLayer<ObjectGroup>('Collisions');
    for (final object in layer?.objects ?? const <TiledObject>[]) {
      _collisionRects.add(Rect.fromLTWH(object.x, object.y, object.width, object.height));
    }
  }

  Future<void> _readTeleports(RenderableTiledMap tiledMap) async {
    final layer = tiledMap.getLayer<ObjectGroup>('Teleports');
    for (final object in layer?.objects ?? const <TiledObject>[]) {
      final parts = object.name.split('#');
      if (parts.length != 2) {
        continue;
      }
      final teleport = TeleportComponent(
        position: Vector2(object.x, object.y),
        size: Vector2(object.width, object.height),
        targetMapId: parts.first,
        targetSpawnId: parts.last,
      );
      _teleports.add(teleport);
      await _sceneRoot.add(teleport);
    }
  }

  Future<void> _readProps(RenderableTiledMap tiledMap) async {
    final layer = tiledMap.getLayer<ObjectGroup>('Props');
    for (final object in layer?.objects ?? const <TiledObject>[]) {
      final color = object.name.contains('tree')
          ? const Color(0xFF6D8F3B)
          : object.name.contains('house')
              ? const Color(0xFF8C5A3C)
              : const Color(0xFF86765F);
      final prop = PropComponent(
        position: Vector2(object.x, object.y),
        size: Vector2(object.width, object.height),
        color: color,
      );
      await _sceneRoot.add(prop);
    }
  }

  Future<void> _readNpcs(RenderableTiledMap tiledMap) async {
    final layer = tiledMap.getLayer<ObjectGroup>('NPCs');
    for (final object in layer?.objects ?? const <TiledObject>[]) {
      final npc = NpcComponent(
        npcId: object.name,
        position: Vector2(object.x, object.y),
        size: Vector2(object.width, object.height),
        onInteract: () async {
          controller.startDialog(_buildNpcDialog(object.name));
        },
      );
      _interactables.add(npc);
      await _sceneRoot.add(npc);
    }
  }

  Future<void> _readChests(RenderableTiledMap tiledMap) async {
    final layer = tiledMap.getLayer<ObjectGroup>('Chests');
    for (final object in layer?.objects ?? const <TiledObject>[]) {
      final chest = ChestComponent(
        chestId: object.name,
        position: Vector2(object.x, object.y),
        size: Vector2(object.width, object.height),
        onInteract: () async {
          final flagKey = 'chest_${object.name}_opened';
          if (controller.flag(flagKey)) {
            controller.setHudMessage('這個寶箱已經空了。');
            return;
          }
          final itemId = object.name == 'old_key' ? 'old_key' : 'potion';
          controller.setFlag(flagKey, true);
          if (itemId == 'old_key') {
            controller.setFlag('has_key_01', true);
          }
          controller.addItem(itemId);
          controller.setHudMessage('獲得 ${itemCatalog[itemId]?.name ?? itemId}。');
        },
      );
      if (controller.flag('chest_${object.name}_opened')) {
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
        return const DialogTree(
          startNodeId: 'start',
          nodes: {
            'start': DialogNode(
              id: 'start',
              speaker: '商人',
              text: '旅人啊，想買東西還是試試身手？',
              choices: [
                DialogChoice(label: '拿一瓶藥水', giveItemId: 'potion', nextNodeId: 'gift'),
                DialogChoice(label: '來場戰鬥練習', startBattleId: 'bat'),
                DialogChoice(label: '先不用了'),
              ],
            ),
            'gift': DialogNode(
              id: 'gift',
              speaker: '商人',
              text: '這瓶送你，別說我不照顧新手。',
            ),
          },
        );
      case 'elder':
      default:
        final hasKey = controller.flag('has_key_01');
        return DialogTree(
          startNodeId: 'start',
          nodes: {
            'start': DialogNode(
              id: 'start',
              speaker: '村長',
              text: hasKey
                  ? '你已經拿到舊鑰匙了。準備好就進屋內深處吧。'
                  : '村外的老屋裡藏著一把舊鑰匙，把它帶回來。',
              nextNodeId: hasKey ? 'finish' : 'choice',
              setFlagOnEnter: 'intro_seen',
            ),
            'choice': const DialogNode(
              id: 'choice',
              speaker: '村長',
              text: '出發之前，要不要先來場模擬戰？',
              choices: [
                DialogChoice(label: '好，開始吧', startBattleId: 'slime'),
                DialogChoice(label: '先不用', nextNodeId: 'finish'),
              ],
            ),
            'finish': const DialogNode(
              id: 'finish',
              speaker: '村長',
              text: '記得按 Space 與人交談，Esc 可以開啟選單。',
            ),
          },
        );
    }
  }
}
