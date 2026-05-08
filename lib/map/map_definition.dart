import 'dart:ui';

class ScenePoint {
  const ScenePoint(this.x, this.y);

  final double x;
  final double y;
}

class SceneTeleportDefinition {
  const SceneTeleportDefinition({
    required this.rect,
    required this.targetMapId,
    required this.targetSpawnId,
    this.requiredFlag,
    this.blockedMessage,
  });

  final Rect rect;
  final String targetMapId;
  final String targetSpawnId;
  final String? requiredFlag;
  final String? blockedMessage;
}

class SceneNpcDefinition {
  const SceneNpcDefinition({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.spritePath,
    this.idleFrames = 2,
    this.showWhenFlag,
    this.hiddenWhenFlag,
  });

  final String id;
  final String label;
  final double x;
  final double y;
  final String spritePath;
  final int idleFrames;
  final String? showWhenFlag;
  final String? hiddenWhenFlag;
}

class SceneEnemyDefinition {
  const SceneEnemyDefinition({
    required this.id,
    required this.enemyId,
    required this.label,
    required this.x,
    required this.y,
    this.showWhenFlag,
    this.hiddenWhenFlag,
  });

  final String id;
  final String enemyId;
  final String label;
  final double x;
  final double y;
  final String? showWhenFlag;
  final String? hiddenWhenFlag;
}

class SceneChestDefinition {
  const SceneChestDefinition({
    required this.id,
    required this.itemId,
    required this.x,
    required this.y,
    this.giveFlag,
    this.showWhenFlag,
    this.hiddenWhenFlag,
  });

  final String id;
  final String itemId;
  final double x;
  final double y;
  final String? giveFlag;
  final String? showWhenFlag;
  final String? hiddenWhenFlag;
}

class MapDefinition {
  const MapDefinition({
    required this.id,
    required this.mapAsset,
    required this.renderTileSize,
    required this.sceneSize,
    required this.defaultSpawnId,
    required this.spawnPoints,
    required this.blockingRects,
    required this.teleports,
    required this.npcs,
    required this.enemies,
    required this.chests,
    required this.hudMessage,
    this.collisionLayers,
  });

  final String id;
  final String mapAsset;
  final double renderTileSize;
  final ScenePoint sceneSize;
  final String defaultSpawnId;
  final Map<String, ScenePoint> spawnPoints;
  final List<Rect> blockingRects;
  final List<SceneTeleportDefinition> teleports;
  final List<SceneNpcDefinition> npcs;
  final List<SceneEnemyDefinition> enemies;
  final List<SceneChestDefinition> chests;
  final String hudMessage;
  final List<String>? collisionLayers;
}

const mapDefinitions = <String, MapDefinition>{
  'village': MapDefinition(
    id: 'village',
    mapAsset: 'assets/images/solaria/map.tmj',
    renderTileSize: 32,
    sceneSize: ScenePoint(1440, 960),
    defaultSpawnId: 'village_square',
    spawnPoints: {
      'village_square': ScenePoint(640, 512),
      'market_lane': ScenePoint(800, 512),
      'ruins_gate': ScenePoint(1184, 512),
      'return_from_ruins': ScenePoint(1120, 512),
    },
    blockingRects: [
      Rect.fromLTWH(0, 0, 160, 960),
      Rect.fromLTWH(0, 0, 1440, 192),
      Rect.fromLTWH(1280, 0, 160, 960),
      Rect.fromLTWH(0, 832, 1440, 128),
      Rect.fromLTWH(320, 256, 224, 192),
      Rect.fromLTWH(864, 256, 224, 192),
      Rect.fromLTWH(576, 640, 288, 128),
    ],
    teleports: [
      SceneTeleportDefinition(
        rect: Rect.fromLTWH(1248, 448, 96, 96),
        targetMapId: 'ruins',
        targetSpawnId: 'entry',
        requiredFlag: 'has_key_01',
        blockedMessage: '遺跡大門被封住了，需要舊鑰匙。',
      ),
    ],
    npcs: [
      SceneNpcDefinition(
        id: 'elder',
        label: '長老',
        x: 480,
        y: 416,
        spritePath: 'npc/wizard_idle.png',
      ),
      SceneNpcDefinition(
        id: 'merchant',
        label: '商人',
        x: 800,
        y: 480,
        spritePath: 'npc/critter_idle.png',
      ),
      SceneNpcDefinition(
        id: 'scout',
        label: '斥候',
        x: 1120,
        y: 544,
        spritePath: 'npc/critter_idle.png',
      ),
    ],
    enemies: [
      SceneEnemyDefinition(
        id: 'slime_training',
        enemyId: 'slime',
        label: '訓練史萊姆',
        x: 960,
        y: 704,
        hiddenWhenFlag: 'beat_slime_01',
      ),
      SceneEnemyDefinition(
        id: 'bat_ambush',
        enemyId: 'bat',
        label: '黃昏蝙蝠',
        x: 1120,
        y: 672,
        hiddenWhenFlag: 'beat_bat_01',
      ),
      SceneEnemyDefinition(
        id: 'slime_garden',
        enemyId: 'slime',
        label: '花圃史萊姆',
        x: 448,
        y: 704,
        hiddenWhenFlag: 'beat_slime_02',
      ),
      SceneEnemyDefinition(
        id: 'bat_roofline',
        enemyId: 'bat',
        label: '屋簷蝙蝠',
        x: 944,
        y: 240,
        hiddenWhenFlag: 'beat_bat_02',
      ),
    ],
    chests: [
      SceneChestDefinition(
        id: 'gate_key',
        itemId: 'old_key',
        x: 896,
        y: 704,
        giveFlag: 'has_key_01',
      ),
      SceneChestDefinition(
        id: 'market_supply',
        itemId: 'potion',
        x: 704,
        y: 544,
      ),
    ],
    hudMessage: '新冒險開始。先和長老談談，再往東邊遺跡前進。',
    collisionLayers: ['water', 'decoration'],
  ),
  'ruins': MapDefinition(
    id: 'ruins',
    mapAsset: 'assets/images/tiled/punnyworld/simple_map.tmj',
    renderTileSize: 32,
    sceneSize: ScenePoint(480, 480),
    defaultSpawnId: 'entry',
    spawnPoints: {
      'entry': ScenePoint(128, 352),
      'guardian_hall': ScenePoint(224, 192),
      'treasure_room': ScenePoint(288, 128),
    },
    blockingRects: [
      Rect.fromLTWH(0, 0, 480, 32),
      Rect.fromLTWH(0, 0, 32, 480),
      Rect.fromLTWH(448, 0, 32, 480),
      Rect.fromLTWH(0, 448, 480, 32),
      Rect.fromLTWH(160, 256, 160, 32),
      Rect.fromLTWH(160, 288, 32, 96),
      Rect.fromLTWH(288, 288, 32, 96),
    ],
    teleports: [
      SceneTeleportDefinition(
        rect: Rect.fromLTWH(96, 384, 64, 64),
        targetMapId: 'village',
        targetSpawnId: 'return_from_ruins',
      ),
    ],
    npcs: [
      SceneNpcDefinition(
        id: 'ruin_spirit',
        label: '遺跡精靈',
        x: 224,
        y: 128,
        spritePath: 'npc/wizard_idle.png',
        showWhenFlag: 'has_key_01',
      ),
    ],
    enemies: [
      SceneEnemyDefinition(
        id: 'goblin_raider',
        enemyId: 'goblin',
        label: '林地哥布林',
        x: 160,
        y: 192,
        hiddenWhenFlag: 'beat_goblin_01',
      ),
      SceneEnemyDefinition(
        id: 'goblin_chief',
        enemyId: 'goblin_chief',
        label: '遺跡守衛',
        x: 288,
        y: 128,
        hiddenWhenFlag: 'beat_goblin_chief',
      ),
      SceneEnemyDefinition(
        id: 'goblin_watch',
        enemyId: 'goblin',
        label: '巡邏哥布林',
        x: 352,
        y: 224,
        hiddenWhenFlag: 'beat_goblin_02',
      ),
    ],
    chests: [
      SceneChestDefinition(
        id: 'ruins_reward',
        itemId: 'potion',
        x: 288,
        y: 96,
      ),
      SceneChestDefinition(
        id: 'ruins_armor',
        itemId: 'cloth_armor',
        x: 192,
        y: 96,
      ),
    ],
    hudMessage: '遺跡裡有哥布林守衛，小心前進。',
  ),
};
