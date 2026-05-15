import 'dart:math';

const Map<String, ItemDefinition> itemCatalog = {
  'potion': ItemDefinition(
    id: 'potion',
    name: '治療藥水',
    description: '回復 25 HP。',
    type: ItemType.consumable,
    healAmount: 25,
    price: 20,
  ),
  'mana_potion': ItemDefinition(
    id: 'mana_potion',
    name: '魔力藥水',
    description: '回復 18 MP。',
    type: ItemType.consumable,
    manaAmount: 18,
    price: 28,
  ),
  'bronze_sword': ItemDefinition(
    id: 'bronze_sword',
    name: '青銅短劍',
    description: '基礎武器，ATK +4。',
    type: ItemType.weapon,
    attackBonus: 4,
    price: 55,
  ),
  'hunter_dagger': ItemDefinition(
    id: 'hunter_dagger',
    name: '獵手短刃',
    description: '輕型武器，ATK +6。',
    type: ItemType.weapon,
    attackBonus: 6,
    price: 90,
  ),
  'iron_blade': ItemDefinition(
    id: 'iron_blade',
    name: '鐵鋼刃',
    description: '中階武器，ATK +9。',
    type: ItemType.weapon,
    attackBonus: 9,
    price: 140,
  ),
  'storm_lance': ItemDefinition(
    id: 'storm_lance',
    name: '風暴長槍',
    description: '稀有武器，ATK +13。',
    type: ItemType.weapon,
    attackBonus: 13,
    price: 260,
  ),
  'mist_reaver': ItemDefinition(
    id: 'mist_reaver',
    name: '迷霧收割者',
    description: '隱藏武器，ATK +18，召喚 1/2 能力的半透明分身協助戰鬥，倒下後 10 秒復活。',
    type: ItemType.weapon,
    attackBonus: 18,
    hiddenDropOnly: true,
    price: 0,
  ),
  'cloth_armor': ItemDefinition(
    id: 'cloth_armor',
    name: '布甲',
    description: '入門護甲，DEF +2。',
    type: ItemType.armor,
    defenseBonus: 2,
    price: 52,
  ),
  'leather_armor': ItemDefinition(
    id: 'leather_armor',
    name: '皮甲',
    description: '基礎護甲，DEF +4。',
    type: ItemType.armor,
    defenseBonus: 4,
    price: 95,
  ),
  'guard_mail': ItemDefinition(
    id: 'guard_mail',
    name: '衛兵鎧甲',
    description: '中階護甲，DEF +7。',
    type: ItemType.armor,
    defenseBonus: 7,
    price: 150,
  ),
  'aegis_plate': ItemDefinition(
    id: 'aegis_plate',
    name: '聖盾板甲',
    description: '稀有護甲，DEF +11。',
    type: ItemType.armor,
    defenseBonus: 11,
    price: 275,
  ),
  'phantom_cloak': ItemDefinition(
    id: 'phantom_cloak',
    name: '幻影披風',
    description: '隱藏防具，DEF +14，提升移動速度並在移動時留下殘影。',
    type: ItemType.armor,
    defenseBonus: 14,
    hiddenDropOnly: true,
    price: 0,
  ),
  'old_key': ItemDefinition(
    id: 'old_key',
    name: '舊鑰匙',
    description: '看起來能開啟某個地方。',
    type: ItemType.keyItem,
  ),
  'mist_compass': ItemDefinition(
    id: 'mist_compass',
    name: '迷霧羅盤',
    description: '指出迷霧森林的出口真位。',
    type: ItemType.keyItem,
  ),
  'forest_emblem': ItemDefinition(
    id: 'forest_emblem',
    name: '森林紋章',
    description: '擊敗迷霧首領後的證明。',
    type: ItemType.keyItem,
  ),
  'cangxiang': ItemDefinition(
    id: 'cangxiang',
    name: '倉音',
    description: '傳說之劍，ATK +999，MP +999。 當遇到魔物時就會發出光芒',
    type: ItemType.weapon,
    attackBonus: 999,
    maxMpBonus: 999,
    hiddenDropOnly: true,
    price: 0,
  ),
  'zamazenta_armor': ItemDefinition(
    id: 'zamazenta_armor',
    name: '臧馬闌寺',
    description: '傳說之盾，DEF +999，MP +999。 當遇到魔物時就會發出光芒',
    type: ItemType.armor,
    defenseBonus: 999,
    maxHpBonus: 999,
    hiddenDropOnly: true,
    price: 0,
  ),
};

const Map<String, EnemyDefinition> enemyCatalog = {
  'slime': EnemyDefinition(
    id: 'slime',
    name: '南瓜史萊姆',
    maxHp: 28,
    attack: 8,
    defense: 2,
    moveSpeed: 42,
    aggroRange: 84,
    attackRange: 28,
    attackCooldown: 1.4,
    experienceReward: 16,
    aggressive: false,
    spriteSheet: 'characters/Enemy/Enemy 03-1.png',
    rewardItemId: 'potion',
    rewardFlag: 'beat_slime_01',
    minGold: 8,
    maxGold: 15,
  ),
  'bat': EnemyDefinition(
    id: 'bat',
    name: '骷髏小兵',
    maxHp: 22,
    attack: 10,
    defense: 1,
    moveSpeed: 72,
    aggroRange: 168,
    attackRange: 30,
    attackCooldown: 1.1,
    experienceReward: 18,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 06-1.png',
    rewardFlag: 'beat_bat_01',
    minGold: 10,
    maxGold: 18,
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
    minGold: 15,
    maxGold: 26,
  ),
  'goblin_chief': EnemyDefinition(
    id: 'goblin_chief',
    name: '迷霧統御者',
    maxHp: 110,
    attack: 12,
    defense: 14,
    moveSpeed: 96,
    aggroRange: 214,
    attackRange: 44,
    attackCooldown: 0.72,
    experienceReward: 90,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 22.png',
    rewardItemId: 'potion',
    rewardFlag: 'beat_forest_boss',
    minGold: 120,
    maxGold: 180,
    isBoss: true,
  ),
  'elder_demon_lord': EnemyDefinition(
    id: 'elder_demon_lord',
    name: '大魔王',
    maxHp: 400,
    attack: 15,
    defense: 25,
    moveSpeed: 80,
    aggroRange: 300,
    attackRange: 50,
    attackCooldown: 0.65,
    experienceReward: 300,
    aggressive: true,
    spriteSheet: 'characters/Boss/Boss 01.png',
    rewardItemId: 'potion',
    rewardFlag: 'beat_elder_boss',
    minGold: 300,
    maxGold: 500,
    isBoss: true,
  ),
  'mist_wisp': EnemyDefinition(
    id: 'mist_wisp',
    name: '迷霧小妖',
    maxHp: 26,
    attack: 9,
    defense: 2,
    moveSpeed: 66,
    aggroRange: 144,
    attackRange: 30,
    attackCooldown: 1.25,
    experienceReward: 18,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 01-1.png',
    rewardItemId: 'mana_potion',
    minGold: 9,
    maxGold: 16,
  ),
  'bog_pup': EnemyDefinition(
    id: 'bog_pup',
    name: '沼澤幼犬',
    maxHp: 30,
    attack: 10,
    defense: 3,
    moveSpeed: 70,
    aggroRange: 138,
    attackRange: 30,
    attackCooldown: 1.2,
    experienceReward: 20,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 02-1.png',
    rewardItemId: 'potion',
    minGold: 10,
    maxGold: 17,
  ),
  'thorn_imp': EnemyDefinition(
    id: 'thorn_imp',
    name: '荊棘小惡魔',
    maxHp: 34,
    attack: 11,
    defense: 4,
    moveSpeed: 74,
    aggroRange: 150,
    attackRange: 32,
    attackCooldown: 1.15,
    experienceReward: 22,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 03-1.png',
    rewardItemId: 'potion',
    minGold: 12,
    maxGold: 19,
  ),
  'mire_rat': EnemyDefinition(
    id: 'mire_rat',
    name: '泥沼鼠',
    maxHp: 28,
    attack: 12,
    defense: 2,
    moveSpeed: 80,
    aggroRange: 132,
    attackRange: 29,
    attackCooldown: 1.0,
    experienceReward: 22,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 04-1.png',
    rewardItemId: 'mana_potion',
    minGold: 11,
    maxGold: 18,
  ),
  'fog_crawler': EnemyDefinition(
    id: 'fog_crawler',
    name: '霧行爬獸',
    maxHp: 38,
    attack: 13,
    defense: 5,
    moveSpeed: 68,
    aggroRange: 160,
    attackRange: 33,
    attackCooldown: 1.08,
    experienceReward: 24,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 05-1.png',
    minGold: 14,
    maxGold: 22,
  ),
  'night_owl': EnemyDefinition(
    id: 'night_owl',
    name: '夜羽魔鴞',
    maxHp: 33,
    attack: 14,
    defense: 3,
    moveSpeed: 86,
    aggroRange: 188,
    attackRange: 34,
    attackCooldown: 0.98,
    experienceReward: 26,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 06-1.png',
    minGold: 15,
    maxGold: 24,
  ),
  'bramble_hound': EnemyDefinition(
    id: 'bramble_hound',
    name: '刺藤獵犬',
    maxHp: 42,
    attack: 15,
    defense: 5,
    moveSpeed: 82,
    aggroRange: 176,
    attackRange: 35,
    attackCooldown: 0.95,
    experienceReward: 28,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 07-1.png',
    rewardItemId: 'hunter_dagger',
    minGold: 18,
    maxGold: 28,
  ),
  'grave_beetle': EnemyDefinition(
    id: 'grave_beetle',
    name: '墓甲蟲',
    maxHp: 46,
    attack: 14,
    defense: 7,
    moveSpeed: 62,
    aggroRange: 144,
    attackRange: 31,
    attackCooldown: 1.2,
    experienceReward: 29,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 08-1.png',
    rewardItemId: 'cloth_armor',
    minGold: 17,
    maxGold: 27,
  ),
  'ember_slime': EnemyDefinition(
    id: 'ember_slime',
    name: '餘燼史萊姆',
    maxHp: 40,
    attack: 16,
    defense: 4,
    moveSpeed: 58,
    aggroRange: 150,
    attackRange: 32,
    attackCooldown: 1.1,
    experienceReward: 30,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 09-1.png',
    rewardItemId: 'mana_potion',
    minGold: 19,
    maxGold: 29,
  ),
  'moss_guard': EnemyDefinition(
    id: 'moss_guard',
    name: '苔蘚守衛',
    maxHp: 50,
    attack: 16,
    defense: 8,
    moveSpeed: 56,
    aggroRange: 156,
    attackRange: 33,
    attackCooldown: 1.12,
    experienceReward: 34,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 10-1.png',
    rewardItemId: 'leather_armor',
    minGold: 22,
    maxGold: 34,
  ),
  'crypt_knight': EnemyDefinition(
    id: 'crypt_knight',
    name: '地窖騎士',
    maxHp: 56,
    attack: 18,
    defense: 9,
    moveSpeed: 64,
    aggroRange: 170,
    attackRange: 35,
    attackCooldown: 1.0,
    experienceReward: 38,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 11-1.png',
    rewardItemId: 'iron_blade',
    minGold: 24,
    maxGold: 38,
  ),
  'void_seer': EnemyDefinition(
    id: 'void_seer',
    name: '虛空觀測者',
    maxHp: 52,
    attack: 20,
    defense: 8,
    moveSpeed: 72,
    aggroRange: 190,
    attackRange: 36,
    attackCooldown: 0.92,
    experienceReward: 40,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 12-1.png',
    rewardItemId: 'mana_potion',
    minGold: 26,
    maxGold: 41,
  ),
  'frost_spirit': EnemyDefinition(
    id: 'frost_spirit',
    name: '霜語精靈',
    maxHp: 54,
    attack: 21,
    defense: 8,
    moveSpeed: 74,
    aggroRange: 198,
    attackRange: 36,
    attackCooldown: 0.9,
    experienceReward: 42,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 13-1.png',
    rewardItemId: 'guard_mail',
    minGold: 28,
    maxGold: 44,
  ),
  'sunken_monk': EnemyDefinition(
    id: 'sunken_monk',
    name: '沉沒僧侶',
    maxHp: 58,
    attack: 22,
    defense: 10,
    moveSpeed: 68,
    aggroRange: 184,
    attackRange: 36,
    attackCooldown: 0.94,
    experienceReward: 45,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 14-1.png',
    rewardItemId: 'storm_lance',
    minGold: 30,
    maxGold: 46,
  ),
  'mist_assassin': EnemyDefinition(
    id: 'mist_assassin',
    name: '迷霧暗殺者',
    maxHp: 48,
    attack: 24,
    defense: 7,
    moveSpeed: 94,
    aggroRange: 212,
    attackRange: 38,
    attackCooldown: 0.84,
    experienceReward: 46,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 15-1.png',
    minGold: 30,
    maxGold: 48,
  ),
  'mist_assassin_elite': EnemyDefinition(
    id: 'mist_assassin_elite',
    name: '迷霧暗殺者・菁英',
    maxHp: 62,
    attack: 27,
    defense: 9,
    moveSpeed: 96,
    aggroRange: 220,
    attackRange: 40,
    attackCooldown: 0.78,
    experienceReward: 58,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 15-6.png',
    rewardItemId: 'mist_reaver',
    minGold: 36,
    maxGold: 58,
  ),
  'hex_stalker': EnemyDefinition(
    id: 'hex_stalker',
    name: '咒紋追獵者',
    maxHp: 60,
    attack: 25,
    defense: 10,
    moveSpeed: 88,
    aggroRange: 218,
    attackRange: 40,
    attackCooldown: 0.82,
    experienceReward: 56,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 16-3.png',
    minGold: 34,
    maxGold: 54,
  ),
  'hex_stalker_elite': EnemyDefinition(
    id: 'hex_stalker_elite',
    name: '咒紋追獵者・深淵',
    maxHp: 66,
    attack: 28,
    defense: 12,
    moveSpeed: 90,
    aggroRange: 226,
    attackRange: 42,
    attackCooldown: 0.78,
    experienceReward: 62,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 16-8.png',
    rewardItemId: 'phantom_cloak',
    minGold: 40,
    maxGold: 64,
  ),
  'abyss_watcher': EnemyDefinition(
    id: 'abyss_watcher',
    name: '深淵監視者',
    maxHp: 68,
    attack: 29,
    defense: 12,
    moveSpeed: 84,
    aggroRange: 230,
    attackRange: 42,
    attackCooldown: 0.76,
    experienceReward: 66,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 17-4.png',
    minGold: 42,
    maxGold: 66,
  ),
  'abyss_watcher_lord': EnemyDefinition(
    id: 'abyss_watcher_lord',
    name: '深淵監視者・領主',
    maxHp: 74,
    attack: 32,
    defense: 14,
    moveSpeed: 86,
    aggroRange: 236,
    attackRange: 44,
    attackCooldown: 0.72,
    experienceReward: 72,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 17-8.png',
    rewardItemId: 'mist_reaver',
    minGold: 48,
    maxGold: 72,
  ),
  'bone_puppet': EnemyDefinition(
    id: 'bone_puppet',
    name: '骸骨傀儡',
    maxHp: 52,
    attack: 20,
    defense: 11,
    moveSpeed: 62,
    aggroRange: 166,
    attackRange: 36,
    attackCooldown: 1.02,
    experienceReward: 44,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 18.png',
    minGold: 24,
    maxGold: 40,
  ),
  'rune_doll': EnemyDefinition(
    id: 'rune_doll',
    name: '符文人偶',
    maxHp: 57,
    attack: 23,
    defense: 12,
    moveSpeed: 68,
    aggroRange: 188,
    attackRange: 39,
    attackCooldown: 0.9,
    experienceReward: 50,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 19.png',
    rewardItemId: 'guard_mail',
    minGold: 30,
    maxGold: 48,
  ),
  'clockwork_knight': EnemyDefinition(
    id: 'clockwork_knight',
    name: '發條騎士',
    maxHp: 64,
    attack: 26,
    defense: 14,
    moveSpeed: 72,
    aggroRange: 194,
    attackRange: 41,
    attackCooldown: 0.86,
    experienceReward: 58,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 20.png',
    rewardItemId: 'aegis_plate',
    minGold: 34,
    maxGold: 54,
  ),
  'ember_mage': EnemyDefinition(
    id: 'ember_mage',
    name: '燼火術師',
    maxHp: 60,
    attack: 27,
    defense: 11,
    moveSpeed: 78,
    aggroRange: 214,
    attackRange: 42,
    attackCooldown: 0.8,
    experienceReward: 60,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 21.png',
    rewardItemId: 'storm_lance',
    minGold: 36,
    maxGold: 58,
  ),
  'doom_reaper': EnemyDefinition(
    id: 'doom_reaper',
    name: '終暮收割者',
    maxHp: 78,
    attack: 34,
    defense: 16,
    moveSpeed: 82,
    aggroRange: 244,
    attackRange: 46,
    attackCooldown: 0.7,
    experienceReward: 85,
    aggressive: true,
    spriteSheet: 'characters/Enemy/Enemy 22.png',
    rewardItemId: 'phantom_cloak',
    minGold: 55,
    maxGold: 86,
  ),
};

enum FacingDirection {
  up,
  upRight,
  right,
  downRight,
  down,
  downLeft,
  left,
  upLeft,
}

enum ItemType { consumable, weapon, armor, keyItem }

enum ItemRarity { common, uncommon, rare, epic, legendary }

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
    this.manaAmount = 0,
    this.maxMpBonus = 0,
    this.maxHpBonus = 0,
    this.price = 0,
    this.hiddenDropOnly = false,
  });

  final String id;
  final String name;
  final String description;
  final ItemType type;
  final int attackBonus;
  final int defenseBonus;
  final int healAmount;
  final int manaAmount;
  final int maxMpBonus;
  final int maxHpBonus;
  final int price;
  final bool hiddenDropOnly;
}

class InventoryEntry {
  const InventoryEntry({
    required this.itemId,
    required this.quantity,
    this.entryId = '',
    this.rarity = ItemRarity.common,
    this.bonusAttack = 0,
    this.bonusDefense = 0,
    this.bonusMaxHp = 0,
    this.bonusMaxMp = 0,
    this.justObtained = false,
  });

  final String itemId;
  final int quantity;
  final String entryId;
  final ItemRarity rarity;
  final int bonusAttack;
  final int bonusDefense;
  final int bonusMaxHp;
  final int bonusMaxMp;
  final bool justObtained;

  bool get isEquipment =>
      item.type == ItemType.weapon || item.type == ItemType.armor;
  String get stableEntryId => entryId.isEmpty ? '${itemId}_legacy' : entryId;

  ItemDefinition get item =>
      itemCatalog[itemId] ??
      ItemDefinition(
        id: itemId,
        name: itemId,
        description: 'Unknown item',
        type: ItemType.keyItem,
      );

  InventoryEntry copyWith({
    String? itemId,
    int? quantity,
    String? entryId,
    ItemRarity? rarity,
    int? bonusAttack,
    int? bonusDefense,
    int? bonusMaxHp,
    int? bonusMaxMp,
    bool? justObtained,
  }) {
    return InventoryEntry(
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      entryId: entryId ?? this.entryId,
      rarity: rarity ?? this.rarity,
      bonusAttack: bonusAttack ?? this.bonusAttack,
      bonusDefense: bonusDefense ?? this.bonusDefense,
      bonusMaxHp: bonusMaxHp ?? this.bonusMaxHp,
      bonusMaxMp: bonusMaxMp ?? this.bonusMaxMp,
      justObtained: justObtained ?? this.justObtained,
    );
  }

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'quantity': quantity,
    'entryId': entryId,
    'rarity': rarity.name,
    'bonusAttack': bonusAttack,
    'bonusDefense': bonusDefense,
    'bonusMaxHp': bonusMaxHp,
    'bonusMaxMp': bonusMaxMp,
    'justObtained': justObtained,
  };

  factory InventoryEntry.fromJson(Map<String, dynamic> json) {
    final rarityName = json['rarity'] as String?;
    return InventoryEntry(
      itemId: json['itemId'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      entryId: json['entryId'] as String? ?? '',
      rarity: ItemRarity.values.firstWhere(
        (value) => value.name == rarityName,
        orElse: () => ItemRarity.common,
      ),
      bonusAttack: (json['bonusAttack'] as num?)?.toInt() ?? 0,
      bonusDefense: (json['bonusDefense'] as num?)?.toInt() ?? 0,
      bonusMaxHp: (json['bonusMaxHp'] as num?)?.toInt() ?? 0,
      bonusMaxMp: (json['bonusMaxMp'] as num?)?.toInt() ?? 0,
      justObtained: (json['justObtained'] as bool?) ?? false,
    );
  }
}

class EquipmentLoadout {
  const EquipmentLoadout({this.weaponEntryId, this.armorEntryId});

  final String? weaponEntryId;
  final String? armorEntryId;

  EquipmentLoadout copyWith({
    String? weaponEntryId,
    String? armorEntryId,
    bool clearWeapon = false,
    bool clearArmor = false,
  }) {
    return EquipmentLoadout(
      weaponEntryId: clearWeapon ? null : (weaponEntryId ?? this.weaponEntryId),
      armorEntryId: clearArmor ? null : (armorEntryId ?? this.armorEntryId),
    );
  }

  Map<String, dynamic> toJson() => {
    'weaponEntryId': weaponEntryId,
    'armorEntryId': armorEntryId,
  };

  factory EquipmentLoadout.fromJson(Map<String, dynamic> json) {
    final legacyWeapon = json['weaponId'] as String?;
    final legacyArmor = json['armorId'] as String?;
    return EquipmentLoadout(
      weaponEntryId:
          json['weaponEntryId'] as String? ??
          (legacyWeapon == null ? null : '${legacyWeapon}_legacy'),
      armorEntryId:
          json['armorEntryId'] as String? ??
          (legacyArmor == null ? null : '${legacyArmor}_legacy'),
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

  PlayerStats copyWith({
    int? maxHp,
    int? hp,
    int? maxMp,
    int? mp,
    int? attack,
    int? defense,
  }) {
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
      hp: max(0, (json['hp'] as num?)?.toInt() ?? parsedMaxHp),
      maxMp: parsedMaxMp,
      mp: max(0, (json['mp'] as num?)?.toInt() ?? parsedMaxMp),
      attack: (json['attack'] as num?)?.toInt() ?? 12,
      defense: (json['defense'] as num?)?.toInt() ?? 6,
    );
  }
}

class GameSnapshot {
  const GameSnapshot({
    required this.playerName,
    required this.currentMapId,
    required this.currentSpawnId,
    required this.playerX,
    required this.playerY,
    required this.level,
    required this.experience,
    required this.nextLevelExperience,
    required this.gold,
    required this.storyFlags,
    required this.inventory,
    required this.equipment,
    required this.stats,
  });

  final String playerName;
  final String currentMapId;
  final String currentSpawnId;
  final double playerX;
  final double playerY;
  final int level;
  final int experience;
  final int nextLevelExperience;
  final int gold;
  final Map<String, bool> storyFlags;
  final List<InventoryEntry> inventory;
  final EquipmentLoadout equipment;
  final PlayerStats stats;

  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'currentMapId': currentMapId,
    'currentSpawnId': currentSpawnId,
    'playerX': playerX,
    'playerY': playerY,
    'level': level,
    'experience': experience,
    'nextLevelExperience': nextLevelExperience,
    'gold': gold,
    'storyFlags': storyFlags,
    'inventory': inventory.map((entry) => entry.toJson()).toList(),
    'equipment': equipment.toJson(),
    'stats': stats.toJson(),
  };

  factory GameSnapshot.fromJson(Map<String, dynamic> json) {
    return GameSnapshot(
      playerName: json['playerName'] as String? ?? 'Kennie',
      currentMapId: json['currentMapId'] as String,
      currentSpawnId: json['currentSpawnId'] as String,
      playerX: (json['playerX'] as num).toDouble(),
      playerY: (json['playerY'] as num).toDouble(),
      level: (json['level'] as num?)?.toInt() ?? 1,
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      nextLevelExperience: (json['nextLevelExperience'] as num?)?.toInt() ?? 30,
      gold: (json['gold'] as num?)?.toInt() ?? 40,
      storyFlags: Map<String, bool>.from(json['storyFlags'] as Map),
      inventory: (json['inventory'] as List<dynamic>)
          .map(
            (entry) => InventoryEntry.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
      equipment: EquipmentLoadout.fromJson(
        json['equipment'] as Map<String, dynamic>,
      ),
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
    this.actionKey,
  });

  final String label;
  final String? nextNodeId;
  final String? setFlagKey;
  final String? giveItemId;
  final String? startBattleId;
  final String? actionKey;
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
  const DialogTree({required this.startNodeId, required this.nodes});

  final String startNodeId;
  final Map<String, DialogNode> nodes;
}

class DialogSession {
  const DialogSession({required this.tree, required this.currentNodeId});

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
    this.minGold = 0,
    this.maxGold = 0,
    this.isBoss = false,
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
  final int minGold;
  final int maxGold;
  final bool isBoss;
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
