import 'dart:math';

const Map<String, ItemDefinition> itemCatalog = {
  'potion': ItemDefinition(
    id: 'potion',
    name: '治療藥水',
    description: '回復 25 HP。',
    type: ItemType.consumable,
    healAmount: 25,
  ),
  'bronze_sword': ItemDefinition(
    id: 'bronze_sword',
    name: '青銅短劍',
    description: '基礎武器，ATK +4。',
    type: ItemType.weapon,
    attackBonus: 4,
  ),
  'cloth_armor': ItemDefinition(
    id: 'cloth_armor',
    name: '布甲',
    description: '入門護甲，DEF +2。',
    type: ItemType.armor,
    defenseBonus: 2,
  ),
  'old_key': ItemDefinition(
    id: 'old_key',
    name: '舊鑰匙',
    description: '看起來能開啟某個地方。',
    type: ItemType.keyItem,
  ),
};

const Map<String, EnemyDefinition> enemyCatalog = {
  'slime': EnemyDefinition(
    id: 'slime',
    name: '史萊姆',
    maxHp: 28,
    attack: 8,
    defense: 2,
    moveSpeed: 42,
    aggroRange: 84,
    attackRange: 28,
    attackCooldown: 1.4,
    experienceReward: 16,
    aggressive: false,
    spriteSheet: 'npc/critter_run_right.png',
    rewardItemId: 'potion',
    rewardFlag: 'beat_slime_01',
  ),
  'bat': EnemyDefinition(
    id: 'bat',
    name: '洞窟蝙蝠',
    maxHp: 22,
    attack: 10,
    defense: 1,
    moveSpeed: 72,
    aggroRange: 168,
    attackRange: 30,
    attackCooldown: 1.1,
    experienceReward: 18,
    aggressive: true,
    spriteSheet: 'npc/critter_run_right.png',
    rewardFlag: 'beat_bat_01',
  ),
  'goblin': EnemyDefinition(
    id: 'goblin',
    name: '林地哥布林',
    maxHp: 42,
    attack: 14,
    defense: 4,
    moveSpeed: 80,
    aggroRange: 176,
    attackRange: 34,
    attackCooldown: 1.0,
    experienceReward: 24,
    aggressive: true,
    spriteSheet: 'enemy/goblin_run_right.png',
    rewardItemId: 'potion',
    rewardFlag: 'beat_goblin_01',
  ),
  'goblin_chief': EnemyDefinition(
    id: 'goblin_chief',
    name: '遺跡守衛',
    maxHp: 58,
    attack: 18,
    defense: 6,
    moveSpeed: 88,
    aggroRange: 196,
    attackRange: 36,
    attackCooldown: 0.9,
    experienceReward: 40,
    aggressive: true,
    spriteSheet: 'enemy/goblin_run_right.png',
    rewardItemId: 'potion',
    rewardFlag: 'beat_goblin_chief',
  ),
};

enum FacingDirection { up, down, left, right }

enum ItemType { consumable, weapon, armor, keyItem }

enum BattleCommand { attack, guard, item, run }

class ItemDefinition {
  const ItemDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.attackBonus = 0,
    this.defenseBonus = 0,
    this.healAmount = 0,
  });

  final String id;
  final String name;
  final String description;
  final ItemType type;
  final int attackBonus;
  final int defenseBonus;
  final int healAmount;
}

class InventoryEntry {
  const InventoryEntry({required this.itemId, required this.quantity});

  final String itemId;
  final int quantity;

  ItemDefinition get item => itemCatalog[itemId] ??
      ItemDefinition(
        id: itemId,
        name: itemId,
        description: 'Unknown item',
        type: ItemType.keyItem,
      );

  InventoryEntry copyWith({String? itemId, int? quantity}) {
    return InventoryEntry(
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'quantity': quantity,
      };

  factory InventoryEntry.fromJson(Map<String, dynamic> json) {
    return InventoryEntry(
      itemId: json['itemId'] as String,
      quantity: json['quantity'] as int,
    );
  }
}

class EquipmentLoadout {
  const EquipmentLoadout({this.weaponId, this.armorId});

  final String? weaponId;
  final String? armorId;

  EquipmentLoadout copyWith({String? weaponId, String? armorId, bool clearWeapon = false, bool clearArmor = false}) {
    return EquipmentLoadout(
      weaponId: clearWeapon ? null : (weaponId ?? this.weaponId),
      armorId: clearArmor ? null : (armorId ?? this.armorId),
    );
  }

  Map<String, dynamic> toJson() => {
        'weaponId': weaponId,
        'armorId': armorId,
      };

  factory EquipmentLoadout.fromJson(Map<String, dynamic> json) {
    return EquipmentLoadout(
      weaponId: json['weaponId'] as String?,
      armorId: json['armorId'] as String?,
    );
  }
}

class PlayerStats {
  const PlayerStats({
    required this.maxHp,
    required this.hp,
    required this.maxMp,
    required this.mp,
    required this.attack,
    required this.defense,
  });

  final int maxHp;
  final int hp;
  final int maxMp;
  final int mp;
  final int attack;
  final int defense;

  PlayerStats copyWith({int? maxHp, int? hp, int? maxMp, int? mp, int? attack, int? defense}) {
    return PlayerStats(
      maxHp: maxHp ?? this.maxHp,
      hp: hp ?? this.hp,
      maxMp: maxMp ?? this.maxMp,
      mp: mp ?? this.mp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
    );
  }

  Map<String, dynamic> toJson() => {
        'maxHp': maxHp,
        'hp': hp,
        'maxMp': maxMp,
        'mp': mp,
        'attack': attack,
        'defense': defense,
      };

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    final parsedMaxHp = (json['maxHp'] as num?)?.toInt() ?? 64;
    final parsedMaxMp = (json['maxMp'] as num?)?.toInt() ?? 30;
    return PlayerStats(
      maxHp: parsedMaxHp,
      hp: ((json['hp'] as num?)?.toInt() ?? parsedMaxHp).clamp(0, parsedMaxHp),
      maxMp: parsedMaxMp,
      mp: ((json['mp'] as num?)?.toInt() ?? parsedMaxMp).clamp(0, parsedMaxMp),
      attack: (json['attack'] as num?)?.toInt() ?? 12,
      defense: (json['defense'] as num?)?.toInt() ?? 6,
    );
  }
}

class GameSnapshot {
  const GameSnapshot({
    required this.currentMapId,
    required this.currentSpawnId,
    required this.playerX,
    required this.playerY,
    required this.level,
    required this.experience,
    required this.nextLevelExperience,
    required this.storyFlags,
    required this.inventory,
    required this.equipment,
    required this.stats,
  });

  final String currentMapId;
  final String currentSpawnId;
  final double playerX;
  final double playerY;
  final int level;
  final int experience;
  final int nextLevelExperience;
  final Map<String, bool> storyFlags;
  final List<InventoryEntry> inventory;
  final EquipmentLoadout equipment;
  final PlayerStats stats;

  Map<String, dynamic> toJson() => {
        'currentMapId': currentMapId,
        'currentSpawnId': currentSpawnId,
        'playerX': playerX,
        'playerY': playerY,
        'level': level,
        'experience': experience,
        'nextLevelExperience': nextLevelExperience,
        'storyFlags': storyFlags,
        'inventory': inventory.map((entry) => entry.toJson()).toList(),
        'equipment': equipment.toJson(),
        'stats': stats.toJson(),
      };

  factory GameSnapshot.fromJson(Map<String, dynamic> json) {
    return GameSnapshot(
      currentMapId: json['currentMapId'] as String,
      currentSpawnId: json['currentSpawnId'] as String,
      playerX: (json['playerX'] as num).toDouble(),
      playerY: (json['playerY'] as num).toDouble(),
        level: (json['level'] as num?)?.toInt() ?? 1,
        experience: (json['experience'] as num?)?.toInt() ?? 0,
        nextLevelExperience: (json['nextLevelExperience'] as num?)?.toInt() ?? 30,
      storyFlags: Map<String, bool>.from(json['storyFlags'] as Map),
      inventory: (json['inventory'] as List<dynamic>)
          .map((entry) => InventoryEntry.fromJson(entry as Map<String, dynamic>))
          .toList(),
      equipment: EquipmentLoadout.fromJson(json['equipment'] as Map<String, dynamic>),
      stats: PlayerStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }
}

class DialogChoice {
  const DialogChoice({
    required this.label,
    this.nextNodeId,
    this.setFlagKey,
    this.giveItemId,
    this.startBattleId,
  });

  final String label;
  final String? nextNodeId;
  final String? setFlagKey;
  final String? giveItemId;
  final String? startBattleId;
}

class DialogNode {
  const DialogNode({
    required this.id,
    required this.speaker,
    required this.text,
    this.nextNodeId,
    this.choices = const [],
    this.setFlagOnEnter,
  });

  final String id;
  final String speaker;
  final String text;
  final String? nextNodeId;
  final List<DialogChoice> choices;
  final String? setFlagOnEnter;
}

class DialogTree {
  const DialogTree({
    required this.startNodeId,
    required this.nodes,
  });

  final String startNodeId;
  final Map<String, DialogNode> nodes;
}

class DialogSession {
  const DialogSession({
    required this.tree,
    required this.currentNodeId,
  });

  final DialogTree tree;
  final String currentNodeId;

  DialogNode get currentNode => tree.nodes[currentNodeId]!;

  DialogSession copyWith({String? currentNodeId}) {
    return DialogSession(
      tree: tree,
      currentNodeId: currentNodeId ?? this.currentNodeId,
    );
  }
}

class EnemyDefinition {
  const EnemyDefinition({
    required this.id,
    required this.name,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.moveSpeed,
    required this.aggroRange,
    required this.attackRange,
    required this.attackCooldown,
    required this.experienceReward,
    required this.aggressive,
    required this.spriteSheet,
    this.rewardItemId,
    this.rewardFlag,
  });

  final String id;
  final String name;
  final int maxHp;
  final int attack;
  final int defense;
  final double moveSpeed;
  final double aggroRange;
  final double attackRange;
  final double attackCooldown;
  final int experienceReward;
  final bool aggressive;
  final String spriteSheet;
  final String? rewardItemId;
  final String? rewardFlag;
}

class BattleState {
  const BattleState({
    required this.enemyId,
    required this.enemyName,
    required this.enemyHp,
    required this.enemyMaxHp,
    required this.log,
    this.playerGuarding = false,
    this.canRun = true,
  });

  final String enemyId;
  final String enemyName;
  final int enemyHp;
  final int enemyMaxHp;
  final String log;
  final bool playerGuarding;
  final bool canRun;

  BattleState copyWith({
    int? enemyHp,
    String? log,
    bool? playerGuarding,
    bool? canRun,
  }) {
    return BattleState(
      enemyId: enemyId,
      enemyName: enemyName,
      enemyHp: enemyHp ?? this.enemyHp,
      enemyMaxHp: enemyMaxHp,
      log: log ?? this.log,
      playerGuarding: playerGuarding ?? this.playerGuarding,
      canRun: canRun ?? this.canRun,
    );
  }
}

int clampDamage(int attack, int defense, Random random) {
  return max(1, attack - defense + random.nextInt(4));
}
