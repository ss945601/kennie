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
    this.canRespawn = false,
    this.isBoss = false,
  });

  final String id;
  final String enemyId;
  final String label;
  final double x;
  final double y;
  final String? showWhenFlag;
  final String? hiddenWhenFlag;
  final bool canRespawn;
  final bool isBoss;
}

class SceneChestDefinition {
  const SceneChestDefinition({
    required this.id,
    required this.itemId,
    required this.x,
    required this.y,
    this.giveFlag,
    this.extraItemIds = const <String>[],
    this.showWhenFlag,
    this.hiddenWhenFlag,
    this.hiddenTrigger = false,
  });

  final String id;
  final String itemId;
  final double x;
  final double y;
  final String? giveFlag;
  final List<String> extraItemIds;
  final String? showWhenFlag;
  final String? hiddenWhenFlag;
  final bool hiddenTrigger;
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
        blockedMessage: '東側密林被迷霧覆蓋，先找到舊鑰匙才能啟程。',
      ),
    ],
    npcs: [
      SceneNpcDefinition(
        id: 'elder',
        label: '長老',
        x: 320,
        y: 192,
        spritePath: 'characters/Male/Male 18-1.png',
        idleFrames: 3,
        hiddenWhenFlag: 'elder_boss_triggered',
      ),
      SceneNpcDefinition(
        id: 'merchant',
        label: '商人',
        x: 464,
        y: 336,
        spritePath: 'characters/Female/Female 23-1.png',
        idleFrames: 3,
        hiddenWhenFlag: 'report_to_elder_prompted',
      ),
      SceneNpcDefinition(
        id: 'scout',
        label: '斥候',
        x: 768,
        y: 320,
        spritePath: 'characters/Female/Female 24-1.png',
        idleFrames: 3,
        hiddenWhenFlag: 'report_to_elder_prompted',
      ),
      SceneNpcDefinition(
        id: 'sign',
        label: '告示牌',
        x: 30,
        y: 250,
        idleFrames: 1,
        spritePath: 'items/sign.png',
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
        y: 408,
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
      SceneEnemyDefinition(
        id: 'elder_demon_lord',
        enemyId: 'elder_demon_lord',
        label: '大魔王',
        x: 330,
        y: 202,
        showWhenFlag: 'elder_boss_triggered',
        hiddenWhenFlag: 'beat_elder_boss',
        canRespawn: false,
        isBoss: true,
      ),
    ],
    chests: [
      SceneChestDefinition(
        id: 'starter_legend_cache',
        itemId: 'cangxiang',
        extraItemIds: ['zamazenta_armor'],
        x: 128,
        y: 344,
        hiddenTrigger: true,
      ),
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
        requiredFlag: 'can_escape_forest',
        blockedMessage: '迷霧扭曲了出口，你被傳回森林深處。擊敗首領並取得迷霧羅盤後再試。',
      ),
      SceneTeleportDefinition(
        rect: Rect.fromLTWH(928, 320, 32, 224),
        targetMapId: 'ruins',
        targetSpawnId: 'entry',
        blockedMessage: '濃霧翻湧，你又被扭回了森林入口。',
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
      SceneNpcDefinition(
        id: 'trader_wanderer',
        label: '迷霧商旅',
        x: 160,
        y: 500,
        spritePath: 'npc/wizard_idle.png',
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
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'mist_wisp_north',
        enemyId: 'mist_wisp',
        label: '北境迷霧小妖',
        x: 180,
        y: 170,
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'bog_pup_stream',
        enemyId: 'bog_pup',
        label: '溪谷沼澤幼犬',
        x: 280,
        y: 470,
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'thorn_imp_arch',
        enemyId: 'thorn_imp',
        label: '拱門荊棘小惡魔',
        x: 500,
        y: 160,
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'mire_rat_south',
        enemyId: 'mire_rat',
        label: '南側泥沼鼠',
        x: 740,
        y: 500,
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'fog_crawler_mid',
        enemyId: 'fog_crawler',
        label: '中央霧行爬獸',
        x: 420,
        y: 360,
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'night_owl_west',
        enemyId: 'night_owl',
        label: '西林夜羽魔鴞',
        x: 110,
        y: 330,
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'grave_beetle_nook',
        enemyId: 'grave_beetle',
        label: '角落墓甲蟲',
        x: 760,
        y: 130,
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'ember_slime_bank',
        enemyId: 'ember_slime',
        label: '河岸餘燼史萊姆',
        x: 360,
        y: 520,
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'crypt_knight_gate',
        enemyId: 'crypt_knight',
        label: '門衛地窖騎士',
        x: 300,
        y: 250,
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'frost_spirit_ring',
        enemyId: 'frost_spirit',
        label: '霜語巡守者',
        x: 520,
        y: 520,
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'mist_assassin_shadow',
        enemyId: 'mist_assassin',
        label: '暗影迷霧暗殺者',
        x: 430,
        y: 90,
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'goblin_chief',
        enemyId: 'goblin_chief',
        label: '迷霧首領',
        x: 836,
        y: 544,
        showWhenFlag: 'has_mist_compass',
        hiddenWhenFlag: 'beat_forest_boss',
        canRespawn: false,
        isBoss: true,
      ),
      SceneEnemyDefinition(
        id: 'goblin_watch',
        enemyId: 'goblin',
        label: '巡邏哥布林',
        x: 608,
        y: 80,
        hiddenWhenFlag: 'beat_goblin_02',
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'void_seer_lane',
        enemyId: 'void_seer',
        label: '支路虛空觀測者',
        x: 680,
        y: 320,
        canRespawn: true,
      ),
      SceneEnemyDefinition(
        id: 'moss_guard_hall',
        enemyId: 'moss_guard',
        label: '大廳苔蘚守衛',
        x: 570,
        y: 290,
        canRespawn: true,
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
        id: 'mist_compass',
        itemId: 'mist_compass',
        x: 836,
        y: 544,
        giveFlag: 'has_mist_compass',
      ),
    ],
    hudMessage: '你陷入迷霧森林了。出口會把你傳回來，先找羅盤並擊敗迷霧首領。',
    collisionLayers: ['base', 'solo', 'tree'],
  ),
};
