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
    mapAsset: 'assets/images/multi_scenario/tile/map_biome1.json',
    renderTileSize: 32,
    sceneSize: ScenePoint(960, 640),
    defaultSpawnId: 'village_square',
    spawnPoints: {
      'village_square': ScenePoint(112, 304),
      'market_lane': ScenePoint(352, 192),
      'ruins_gate': ScenePoint(864, 352),
      'return_from_ruins': ScenePoint(800, 352),
    },
    blockingRects: [],
    teleports: [
      SceneTeleportDefinition(
        rect: Rect.fromLTWH(928, 320, 32, 224),
        targetMapId: 'ruins',
        targetSpawnId: 'entry',
        requiredFlag: 'has_key_01',
        blockedMessage: '東側密林的路障還鎖著，需要先找到舊鑰匙。',
      ),
    ],
    npcs: [
      SceneNpcDefinition(
        id: 'elder',
        label: '長老',
        x: 320,
        y: 192,
        spritePath: 'npc/wizard_idle.png',
      ),
      SceneNpcDefinition(
        id: 'merchant',
        label: '商人',
        x: 464,
        y: 336,
        spritePath: 'npc/critter_idle.png',
      ),
      SceneNpcDefinition(
        id: 'scout',
        label: '斥候',
        x: 768,
        y: 320,
        spritePath: 'npc/critter_idle.png',
      ),
    ],
    enemies: [
      SceneEnemyDefinition(
        id: 'slime_training',
        enemyId: 'slime',
        label: '池畔史萊姆',
        x: 256,
        y: 512,
        hiddenWhenFlag: 'beat_slime_01',
      ),
      SceneEnemyDefinition(
        id: 'bat_ambush',
        enemyId: 'bat',
        label: '樹梢蝙蝠',
        x: 640,
        y: 128,
        hiddenWhenFlag: 'beat_bat_01',
      ),
      SceneEnemyDefinition(
        id: 'slime_garden',
        enemyId: 'slime',
        label: '木橋史萊姆',
        x: 672,
        y: 480,
        hiddenWhenFlag: 'beat_slime_02',
      ),
      SceneEnemyDefinition(
        id: 'bat_roofline',
        enemyId: 'bat',
        label: '蘆葦蝙蝠',
        x: 288,
        y: 416,
        hiddenWhenFlag: 'beat_bat_02',
      ),
    ],
    chests: [
      SceneChestDefinition(
        id: 'gate_key',
        itemId: 'old_key',
        x: 704,
        y: 480,
        giveFlag: 'has_key_01',
      ),
      SceneChestDefinition(
        id: 'market_supply',
        itemId: 'potion',
        x: 256,
        y: 352,
      ),
    ],
    hudMessage: '先穿過木橋水道熟悉地形，再往右側密林通道前進。',
    collisionLayers: ['base', 'solo', 'tree'],
  ),
  'ruins': MapDefinition(
    id: 'ruins',
    mapAsset: 'assets/images/multi_scenario/tile/map_biome2.json',
    renderTileSize: 32,
    sceneSize: ScenePoint(960, 640),
    defaultSpawnId: 'entry',
    spawnPoints: {
      'entry': ScenePoint(96, 448),
      'guardian_hall': ScenePoint(384, 288),
      'treasure_room': ScenePoint(736, 448),
    },
    blockingRects: [],
    teleports: [
      SceneTeleportDefinition(
        rect: Rect.fromLTWH(0, 384, 32, 224),
        targetMapId: 'village',
        targetSpawnId: 'return_from_ruins',
      ),
    ],
    npcs: [
      SceneNpcDefinition(
        id: 'ruin_spirit',
        label: '遺跡精靈',
        x: 352,
        y: 288,
        spritePath: 'npc/wizard_idle.png',
        showWhenFlag: 'has_key_01',
      ),
    ],
    enemies: [
      SceneEnemyDefinition(
        id: 'goblin_raider',
        enemyId: 'goblin',
        label: '海灣哥布林',
        x: 224,
        y: 336,
        hiddenWhenFlag: 'beat_goblin_01',
      ),
      SceneEnemyDefinition(
        id: 'goblin_chief',
        enemyId: 'goblin_chief',
        label: '沙灘守衛',
        x: 608,
        y: 448,
        hiddenWhenFlag: 'beat_goblin_chief',
      ),
      SceneEnemyDefinition(
        id: 'goblin_watch',
        enemyId: 'goblin',
        label: '巡邏哥布林',
        x: 608,
        y: 80,
        hiddenWhenFlag: 'beat_goblin_02',
      ),
    ],
    chests: [
      SceneChestDefinition(
        id: 'ruins_reward',
        itemId: 'potion',
        x: 512,
        y: 320,
      ),
      SceneChestDefinition(
        id: 'ruins_armor',
        itemId: 'cloth_armor',
        x: 832,
        y: 544,
      ),
    ],
    hudMessage: '穿過沙灘與叢林水窪，清掉散落的哥布林再回來。',
    collisionLayers: ['base', 'solo', 'tree'],
  ),
};
