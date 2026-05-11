import 'dart:math';
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'models/game_models.dart';
import 'services/save_repository.dart';

class GameStateController extends ChangeNotifier {
  GameStateController({required SaveRepository saveRepository})
      : _saveRepository = saveRepository;

  final SaveRepository _saveRepository;
  final Random _random = Random();
  static const double _potionDropChance = 0.10;
  static const double _equipmentDropChance = 0.10;
  static const double _rareEquipmentChanceWithinEquipmentDrops = 0.10;

  bool showTitleMenu = true;
  bool hasSaveFile = false;
  bool isPauseMenuOpen = false;
  double transitionOpacity = 1;
  String currentMapId = 'village';
  String currentSpawnId = 'village_square';
  String playerName = 'Kennie';
  double playerX = 608;
  double playerY = 544;
  int level = 1;
  int experience = 0;
  int nextLevelExperience = 30;
  int gold = 40;
  PlayerStats baseStats = const PlayerStats(
    maxHp: 64,
    hp: 64,
    maxMp: 30,
    mp: 30,
    attack: 12,
    defense: 6,
  );
  EquipmentLoadout equipment = const EquipmentLoadout();
  final Map<String, bool> storyFlags = <String, bool>{};
  final List<InventoryEntry> inventory = <InventoryEntry>[
    const InventoryEntry(itemId: 'potion', quantity: 2, entryId: 'potion_stack'),
    const InventoryEntry(itemId: 'mana_potion', quantity: 1, entryId: 'mana_stack'),
    const InventoryEntry(itemId: 'bronze_sword', quantity: 1, entryId: 'bronze_sword_legacy'),
    const InventoryEntry(itemId: 'cloth_armor', quantity: 1, entryId: 'cloth_armor_legacy'),
  ];

  DialogSession? activeDialog;
  ChestRewardDialogState? activeChestRewardDialog;
  Completer<void>? _chestRewardDialogCompleter;
  BattleState? activeBattle;
  String hudMessage = '方向鍵移動，J 近戰，K 火球，Space 互動，Esc 開選單';
  EquipmentPickupEvent? latestEquipmentPickup;
  int _equipmentPickupSerial = 0;

  int get equipmentPickupSerial => _equipmentPickupSerial;

  Future<void> initialize() async {
    hasSaveFile = await _saveRepository.hasSave();
    transitionOpacity = 0;
    notifyListeners();
  }

  PlayerStats get effectiveStats {
    final weaponEntry = _entryById(equipment.weaponEntryId);
    final armorEntry = _entryById(equipment.armorEntryId);
    final weapon = weaponEntry?.item;
    final armor = armorEntry?.item;
    return baseStats.copyWith(
      maxHp: baseStats.maxHp +
          (weapon?.maxHpBonus ?? 0) +
          (armor?.maxHpBonus ?? 0) +
          (weaponEntry?.bonusMaxHp ?? 0) +
          (armorEntry?.bonusMaxHp ?? 0),
      maxMp: baseStats.maxMp +
          (weapon?.maxMpBonus ?? 0) +
          (armor?.maxMpBonus ?? 0) +
          (weaponEntry?.bonusMaxMp ?? 0) +
          (armorEntry?.bonusMaxMp ?? 0),
      attack: baseStats.attack + (weapon?.attackBonus ?? 0) + (weaponEntry?.bonusAttack ?? 0) + (armorEntry?.bonusAttack ?? 0),
      defense: baseStats.defense + (armor?.defenseBonus ?? 0) + (weaponEntry?.bonusDefense ?? 0) + (armorEntry?.bonusDefense ?? 0),
    );
  }

  InventoryEntry? _entryById(String? entryId) {
    if (entryId == null) {
      return null;
    }
    for (final entry in inventory) {
      if (entry.stableEntryId == entryId) {
        return entry;
      }
    }
    return null;
  }

  int _entryValue(InventoryEntry entry) {
    final base = entry.item.price;
    final bonusScore = (entry.bonusAttack + entry.bonusDefense) * 8 +
        entry.bonusMaxHp * 2 +
        entry.bonusMaxMp * 2;
    final rarityMultiplier = switch (entry.rarity) {
      ItemRarity.common => 1.0,
      ItemRarity.uncommon => 1.2,
      ItemRarity.rare => 1.5,
      ItemRarity.epic => 2.1,
      ItemRarity.legendary => 3.4,
    };
    return ((base + bonusScore) * rarityMultiplier).round().clamp(1, 9999);
  }

  void _ensureLegacyLoadoutBackfill() {
    if (equipment.weaponEntryId != null || equipment.armorEntryId != null) {
      return;
    }
    InventoryEntry? weaponEntry;
    InventoryEntry? armorEntry;
    for (final entry in inventory) {
      if (weaponEntry == null && entry.item.type == ItemType.weapon) {
        weaponEntry = entry;
      }
      if (armorEntry == null && entry.item.type == ItemType.armor) {
        armorEntry = entry;
      }
    }
    equipment = equipment.copyWith(
      weaponEntryId: weaponEntry?.stableEntryId,
      armorEntryId: armorEntry?.stableEntryId,
    );
  }

  void _syncEscapeFlag() {
    if (flag('beat_forest_boss') && flag('has_mist_compass')) {
      storyFlags['can_escape_forest'] = true;
    }
  }

  bool get isFieldInputLocked =>
      showTitleMenu ||
      isPauseMenuOpen ||
      activeDialog != null ||
      activeChestRewardDialog != null ||
      transitionOpacity > 0.05;

    bool get isOverlayBusy =>
      activeDialog != null || activeChestRewardDialog != null || isPauseMenuOpen;

  bool flag(String key) => storyFlags[key] ?? false;

  void setFlag(String key, bool value) {
    storyFlags[key] = value;
    _syncEscapeFlag();
    notifyListeners();
  }

  void setHudMessage(String message) {
    hudMessage = message;
    notifyListeners();
  }

  void startNewGame() {
    showTitleMenu = false;
    isPauseMenuOpen = false;
    activeDialog = null;
    activeBattle = null;
    currentMapId = 'village';
    currentSpawnId = 'village_square';
    playerName = 'Kennie';
    playerX = 608;
    playerY = 544;
    level = 1;
    experience = 0;
    nextLevelExperience = 30;
    gold = 40;
    transitionOpacity = 0;
    storyFlags
      ..clear()
      ..addAll({
        'intro_seen': false,
        'has_key_01': false,
        'merchant_gift_claimed': false,
        'fog_loop_active': true,
        'can_escape_forest': false,
      });
    inventory
      ..clear()
      ..addAll(const [
        InventoryEntry(itemId: 'potion', quantity: 2, entryId: 'potion_stack'),
        InventoryEntry(itemId: 'mana_potion', quantity: 1, entryId: 'mana_stack'),
        InventoryEntry(itemId: 'bronze_sword', quantity: 1, entryId: 'bronze_sword_legacy'),
        InventoryEntry(itemId: 'cloth_armor', quantity: 1, entryId: 'cloth_armor_legacy'),
      ]);
    baseStats = const PlayerStats(maxHp: 64, hp: 64, maxMp: 30, mp: 30, attack: 12, defense: 6);
    equipment = const EquipmentLoadout(weaponEntryId: 'bronze_sword_legacy', armorEntryId: 'cloth_armor_legacy');
    hudMessage = '新冒險開始！先去和長老聊聊吧，J 揮劍、K 火球。';
    notifyListeners();
  }

  Future<bool> continueFromSave() async {
    final snapshot = await _saveRepository.load();
    if (snapshot == null) {
      hudMessage = '目前沒有可載入的存檔。';
      hasSaveFile = false;
      notifyListeners();
      return false;
    }
    _applySnapshot(snapshot);
    _syncEscapeFlag();
    showTitleMenu = false;
    hudMessage = '已載入存檔。';
    notifyListeners();
    return true;
  }

  Future<void> saveGame() async {
    final snapshot = GameSnapshot(
      playerName: playerName,
      currentMapId: currentMapId,
      currentSpawnId: currentSpawnId,
      playerX: playerX,
      playerY: playerY,
      level: level,
      experience: experience,
      nextLevelExperience: nextLevelExperience,
      gold: gold,
      storyFlags: Map<String, bool>.from(storyFlags),
      inventory: List<InventoryEntry>.from(inventory),
      equipment: equipment,
      stats: baseStats,
    );
    await _saveRepository.save(snapshot);
    hasSaveFile = true;
    hudMessage = '遊戲已儲存。';
    notifyListeners();
  }

  Future<bool> loadGame() async {
    final snapshot = await _saveRepository.load();
    if (snapshot == null) {
      hudMessage = '沒有找到存檔資料。';
      notifyListeners();
      return false;
    }
    _applySnapshot(snapshot);
    _syncEscapeFlag();
    hudMessage = '存檔讀取完成。';
    notifyListeners();
    return true;
  }

  void _applySnapshot(GameSnapshot snapshot) {
    playerName = snapshot.playerName;
    currentMapId = snapshot.currentMapId;
    currentSpawnId = snapshot.currentSpawnId;
    playerX = snapshot.playerX;
    playerY = snapshot.playerY;
    level = snapshot.level;
    experience = snapshot.experience;
    nextLevelExperience = snapshot.nextLevelExperience;
    gold = snapshot.gold;
    storyFlags
      ..clear()
      ..addAll(snapshot.storyFlags);
    inventory
      ..clear()
      ..addAll(snapshot.inventory);
    equipment = snapshot.equipment;
    _ensureLegacyLoadoutBackfill();
    baseStats = snapshot.stats;
    activeDialog = null;
    activeBattle = null;
    isPauseMenuOpen = false;
    showTitleMenu = false;
    hasSaveFile = true;
  }

  void setPlayerPosition(double x, double y) {
    playerX = x;
    playerY = y;
  }

  void setMapContext({required String mapId, required String spawnId}) {
    currentMapId = mapId;
    currentSpawnId = spawnId;
    notifyListeners();
  }

  void setTransitionOpacity(double value) {
    transitionOpacity = value.clamp(0, 1).toDouble();
    notifyListeners();
  }

  void togglePauseMenu() {
    if (showTitleMenu || activeDialog != null || activeBattle != null) {
      return;
    }
    isPauseMenuOpen = !isPauseMenuOpen;
    notifyListeners();
  }

  void closePauseMenu() {
    if (!isPauseMenuOpen) {
      return;
    }
    isPauseMenuOpen = false;
    notifyListeners();
  }

  void returnToTitleMenu() {
    showTitleMenu = true;
    isPauseMenuOpen = false;
    activeDialog = null;
    activeChestRewardDialog = null;
    _chestRewardDialogCompleter?.complete();
    _chestRewardDialogCompleter = null;
    activeBattle = null;
    level = 1;
    experience = 0;
    nextLevelExperience = 30;
    transitionOpacity = 0;
    hudMessage = '方向鍵移動，J 近戰，K 火球，Space 互動，Esc 開選單';
    notifyListeners();
  }

  void startDialog(DialogTree tree) {
    final startNode = tree.nodes[tree.startNodeId];
    if (startNode == null) {
      return;
    }
    activeDialog = DialogSession(tree: tree, currentNodeId: tree.startNodeId);
    _applyNodeSideEffects(startNode);
    hudMessage = '方向鍵移動，J 近戰，K 火球，Space 互動，Esc 開選單';
    notifyListeners();
  }

  Future<void> showChestRewardDialog({
    required String chestId,
    required String itemId,
    required String itemName,
  }) {
    _chestRewardDialogCompleter?.complete();
    _chestRewardDialogCompleter = Completer<void>();
    activeChestRewardDialog = ChestRewardDialogState(
      chestId: chestId,
      itemId: itemId,
      itemName: itemName,
    );
    notifyListeners();
    return _chestRewardDialogCompleter!.future;
  }

  void confirmChestRewardDialog() {
    if (activeChestRewardDialog == null) {
      return;
    }
    activeChestRewardDialog = null;
    _chestRewardDialogCompleter?.complete();
    _chestRewardDialogCompleter = null;
    notifyListeners();
  }

  int rollPlayerDamage(int enemyDefense) {
    return clampDamage(effectiveStats.attack, enemyDefense, _random);
  }

  int rollEnemyDamage(EnemyDefinition enemy) {
    return clampDamage(enemy.attack, effectiveStats.defense, _random);
  }

  bool spendMp(int amount, {bool silent = false}) {
    if (amount <= 0) {
      return true;
    }
    if (baseStats.mp < amount) {
      return false;
    }
    baseStats = baseStats.copyWith(mp: baseStats.mp - amount);
    if (!silent) {
      notifyListeners();
    }
    return true;
  }

  bool applyPlayerDamage(int damage, {String? source}) {
    final remainingHp = max(0, baseStats.hp - damage);
    baseStats = baseStats.copyWith(hp: remainingHp);
    if (remainingHp == 0) {
      baseStats = baseStats.copyWith(hp: max(1, baseStats.maxHp ~/ 2));
      hudMessage = '${source ?? '敵人'} 擊倒了你，你勉強撤回安全位置。';
      notifyListeners();
      return true;
    }
    hudMessage = '${source ?? '敵人'} 造成 $damage 點傷害。';
    notifyListeners();
    return false;
  }

  bool usePotionQuick() {
    final potion = itemCatalog['potion'];
    if (potion == null) {
      return false;
    }
    if (!consumeItem('potion')) {
      hudMessage = '沒有可用的治療藥水。';
      notifyListeners();
      return false;
    }
    baseStats = baseStats.copyWith(
      hp: min(baseStats.maxHp, baseStats.hp + potion.healAmount),
    );
    hudMessage = '你使用了治療藥水，回復 ${potion.healAmount} HP。';
    notifyListeners();
    return true;
  }

  bool useManaPotionQuick() {
    final manaPotion = itemCatalog['mana_potion'];
    if (manaPotion == null) {
      return false;
    }
    if (!consumeItem('mana_potion')) {
      hudMessage = '沒有可用的魔力藥水。';
      notifyListeners();
      return false;
    }
    baseStats = baseStats.copyWith(
      mp: min(baseStats.maxMp, baseStats.mp + manaPotion.manaAmount),
    );
    hudMessage = '你使用了魔力藥水，回復 ${manaPotion.manaAmount} MP。';
    notifyListeners();
    return true;
  }

  void onEnemyDefeated(EnemyDefinition enemy, {String? defeatedFlag, String? messagePrefix}) {
    final drops = <String>[];
    if (_random.nextDouble() < _potionDropChance) {
      final potionId = _random.nextDouble() < 0.25 ? 'mana_potion' : 'potion';
      addItem(potionId, markObtained: false);
      drops.add(itemCatalog[potionId]?.name ?? potionId);
    }
    final rolledGold = enemy.maxGold > enemy.minGold
        ? enemy.minGold + _random.nextInt(enemy.maxGold - enemy.minGold + 1)
        : enemy.minGold;
    if (rolledGold > 0) {
      addGold(rolledGold, silent: true);
      drops.add('$rolledGold 金幣');
    }
    if (_random.nextDouble() < _equipmentDropChance) {
      final randomEquip = rollRandomEquipmentDrop(enemy);
      if (randomEquip != null) {
        final rarity = _rollDropEquipmentRarity();
        addEquipmentDrop(randomEquip, rarity: rarity, markObtained: true);
        final rarityTag = switch (rarity) {
          ItemRarity.common => '普通',
          ItemRarity.uncommon => '優秀',
          ItemRarity.rare => '稀有',
          ItemRarity.epic => '史詩',
          ItemRarity.legendary => '傳說',
        };
        drops.add('$rarityTag【${itemCatalog[randomEquip]?.name ?? randomEquip}】');
      }
    }
    if (enemy.rewardFlag case final rewardFlag?) {
      storyFlags[rewardFlag] = true;
    }
    if (defeatedFlag != null) {
      storyFlags[defeatedFlag] = true;
    }
    if (enemy.isBoss) {
      addItem('forest_emblem', markObtained: true);
      storyFlags['beat_forest_boss'] = true;
      _syncEscapeFlag();
    }
    gainExperience(enemy.experienceReward);
    final prefix = messagePrefix == null ? '' : '$messagePrefix ';
    final dropText = drops.isEmpty ? '' : ' 掉落: ${drops.join('、')}';
    hudMessage = '$prefix擊敗 ${enemy.name}，獲得 ${enemy.experienceReward} EXP。$dropText';
    notifyListeners();
  }

  void addGold(int amount, {bool silent = false}) {
    if (amount <= 0) {
      return;
    }
    gold += amount;
    if (!silent) {
      notifyListeners();
    }
  }

  bool spendGold(int amount, {bool silent = false}) {
    if (amount <= 0) {
      return true;
    }
    if (gold < amount) {
      return false;
    }
    gold -= amount;
    if (!silent) {
      notifyListeners();
    }
    return true;
  }

  String? rollRandomEquipmentDrop(EnemyDefinition enemy) {
    final pools = <String>[
      'hunter_dagger',
      'iron_blade',
      'storm_lance',
      'leather_armor',
      'guard_mail',
      'aegis_plate',
      if (enemy.isBoss || level >= 8) 'mist_reaver',
      if (enemy.isBoss || level >= 8) 'phantom_cloak',
    ];
    return pools[_random.nextInt(pools.length)];
  }

  ItemRarity _rollDropEquipmentRarity() {
    final roll = _random.nextDouble();
    if (roll < _rareEquipmentChanceWithinEquipmentDrops) {
      return ItemRarity.rare;
    }
    if (roll < 0.45) {
      return ItemRarity.uncommon;
    }
    return ItemRarity.common;
  }

  void addEquipmentDrop(
    String itemId, {
    required ItemRarity rarity,
    bool markObtained = false,
  }) {
    final affix = _generateAffix(rarity);
    final now = DateTime.now().millisecondsSinceEpoch;
    final entry = InventoryEntry(
      itemId: itemId,
      quantity: 1,
      entryId: '${itemId}_$now${_random.nextInt(999)}',
      rarity: rarity,
      bonusAttack: affix.bonusAttack,
      bonusDefense: affix.bonusDefense,
      bonusMaxHp: affix.bonusMaxHp,
      bonusMaxMp: affix.bonusMaxMp,
      justObtained: markObtained,
    );
    inventory.add(entry);
    if (markObtained) {
      _equipmentPickupSerial += 1;
      latestEquipmentPickup = EquipmentPickupEvent(
        serial: _equipmentPickupSerial,
        itemName: entry.item.name,
        rarity: entry.rarity,
      );
    }
  }

  _AffixRoll _generateAffix(ItemRarity rarity) {
    final base = switch (rarity) {
      ItemRarity.common => 0,
      ItemRarity.uncommon => 1,
      ItemRarity.rare => 2,
      ItemRarity.epic => 4,
      ItemRarity.legendary => 7,
    };
    final variance = base == 0 ? 1 : (base + _random.nextInt(base + 2));
    return _AffixRoll(
      bonusAttack: _random.nextInt(variance + 1),
      bonusDefense: _random.nextInt(variance + 1),
      bonusMaxHp: _random.nextInt(variance * 3 + 1),
      bonusMaxMp: _random.nextInt(variance * 2 + 1),
    );
  }

  void gainExperience(int amount) {
    experience += amount;
    while (experience >= nextLevelExperience) {
      experience -= nextLevelExperience;
      level += 1;
      nextLevelExperience = (nextLevelExperience * 1.35).round();
      baseStats = baseStats.copyWith(
        maxHp: baseStats.maxHp + 10,
        hp: baseStats.maxHp + 10,
        maxMp: baseStats.maxMp + 5,
        mp: baseStats.maxMp + 5,
        attack: baseStats.attack + 3,
        defense: baseStats.defense + 2,
      );
      hudMessage = '升級！你已到達 Lv.$level。';
    }
    notifyListeners();
  }

  void advanceDialog() {
    final session = activeDialog;
    if (session == null) {
      return;
    }
    final currentNode = session.currentNode;
    if (currentNode.choices.isNotEmpty) {
      return;
    }
    final nextNodeId = currentNode.nextNodeId;
    if (nextNodeId == null) {
      activeDialog = null;
      hudMessage = '對話結束。';
      notifyListeners();
      return;
    }
    final nextNode = session.tree.nodes[nextNodeId];
    if (nextNode == null) {
      activeDialog = null;
      notifyListeners();
      return;
    }
    activeDialog = session.copyWith(currentNodeId: nextNodeId);
    _applyNodeSideEffects(nextNode);
    notifyListeners();
  }

  void chooseDialogChoice(DialogChoice choice) {
    if (choice.actionKey case final action?) {
      _runDialogAction(action);
    }
    if (choice.setFlagKey case final key?) {
      storyFlags[key] = true;
    }
    if (choice.giveItemId case final itemId?) {
      addItem(itemId, markObtained: true);
    }
    if (choice.startBattleId case final enemyId?) {
      activeDialog = null;
      startBattle(enemyId);
      return;
    }
    final session = activeDialog;
    if (session == null || choice.nextNodeId == null) {
      activeDialog = null;
      notifyListeners();
      return;
    }
    final nextNode = session.tree.nodes[choice.nextNodeId!];
    if (nextNode == null) {
      activeDialog = null;
      notifyListeners();
      return;
    }
    activeDialog = session.copyWith(currentNodeId: nextNode.id);
    _applyNodeSideEffects(nextNode);
    notifyListeners();
  }

  void _runDialogAction(String action) {
    switch (action) {
      case 'buy_potion':
        _buyFromShop('potion', 20);
        break;
      case 'buy_mana_potion':
        _buyFromShop('mana_potion', 28);
        break;
      case 'buy_weapon_crate':
        _buyRandomShopEquipment(weaponOnly: true, price: 120);
        break;
      case 'buy_armor_crate':
        _buyRandomShopEquipment(weaponOnly: false, price: 120);
        break;
      case 'sell_potion':
        _sellToShop('potion');
        break;
      case 'sell_mana_potion':
        _sellToShop('mana_potion');
        break;
      case 'sell_equipment':
        _sellOneEquipment();
        break;
      case 'toggle_fog_goal_hint':
        hudMessage = '迷霧出口會把你傳回來，先擊敗迷霧統御者並取得迷霧羅盤。';
        break;
      default:
        break;
    }
  }

  void _buyFromShop(String itemId, int price) {
    if (!spendGold(price, silent: true)) {
      hudMessage = '金幣不足，無法購買。';
      notifyListeners();
      return;
    }
    addItem(itemId, markObtained: true, silent: true);
    hudMessage = '購買 ${itemCatalog[itemId]?.name ?? itemId} 成功，花費 $price 金幣。';
    notifyListeners();
  }

  void _buyRandomShopEquipment({required bool weaponOnly, required int price}) {
    if (!spendGold(price, silent: true)) {
      hudMessage = '金幣不足，無法購買裝備。';
      notifyListeners();
      return;
    }
    final pool = itemCatalog.values.where((item) {
      if (item.hiddenDropOnly) {
        return false;
      }
      if (weaponOnly) {
        return item.type == ItemType.weapon;
      }
      return item.type == ItemType.armor;
    }).toList(growable: false);
    final selected = pool[_random.nextInt(pool.length)];
    addEquipmentDrop(
      selected.id,
      rarity: _random.nextDouble() < 0.2 ? ItemRarity.rare : ItemRarity.uncommon,
      markObtained: true,
    );
    hudMessage = '購買裝備箱成功，獲得 ${selected.name}。';
    notifyListeners();
  }

  void _sellToShop(String itemId) {
    final index = inventory.indexWhere((entry) => entry.itemId == itemId);
    if (index == -1) {
      hudMessage = '你沒有可販售的 ${itemCatalog[itemId]?.name ?? itemId}。';
      notifyListeners();
      return;
    }
    final entry = inventory[index];
    final sellPrice = max(1, _entryValue(entry) ~/ 2);
    consumeItem(itemId, silent: true);
    addGold(sellPrice, silent: true);
    hudMessage = '已販售 ${entry.item.name}，獲得 $sellPrice 金幣。';
    notifyListeners();
  }

  void _sellOneEquipment() {
    final equipmentIndex = inventory.indexWhere((entry) {
      if (!entry.isEquipment) {
        return false;
      }
      if (entry.stableEntryId == equipment.weaponEntryId ||
          entry.stableEntryId == equipment.armorEntryId) {
        return false;
      }
      return true;
    });
    if (equipmentIndex == -1) {
      hudMessage = '沒有可販售的未裝備裝備。';
      notifyListeners();
      return;
    }
    final entry = inventory.removeAt(equipmentIndex);
    final sellPrice = max(6, _entryValue(entry) ~/ 2);
    addGold(sellPrice, silent: true);
    hudMessage = '販售 ${entry.item.name}，獲得 $sellPrice 金幣。';
    notifyListeners();
  }

  void _applyNodeSideEffects(DialogNode node) {
    if (node.setFlagOnEnter case final key?) {
      storyFlags[key] = true;
    }
  }

  void startBattle(String enemyId) {
    final enemy = enemyCatalog[enemyId];
    if (enemy == null) {
      return;
    }
    activeBattle = BattleState(
      enemyId: enemy.id,
      enemyName: enemy.name,
      enemyHp: enemy.maxHp,
      enemyMaxHp: enemy.maxHp,
      log: '${enemy.name} 出現了！',
    );
    notifyListeners();
  }

  void performBattleCommand(BattleCommand command) {
    final battle = activeBattle;
    final enemy = battle == null ? null : enemyCatalog[battle.enemyId];
    if (battle == null || enemy == null) {
      return;
    }

    var updatedPlayerStats = baseStats;
    var nextBattle = battle.copyWith(playerGuarding: false);
    var log = '';

    switch (command) {
      case BattleCommand.attack:
        final damage = clampDamage(effectiveStats.attack, enemy.defense, _random);
        final remainingHp = max(0, battle.enemyHp - damage);
        log = '你造成 $damage 點傷害。';
        nextBattle = nextBattle.copyWith(enemyHp: remainingHp, log: log);
        if (remainingHp == 0) {
          _finishBattle(enemy, won: true, openingLog: log);
          return;
        }
        break;
      case BattleCommand.guard:
        log = '你採取防禦姿態。';
        nextBattle = nextBattle.copyWith(playerGuarding: true, log: log);
        break;
      case BattleCommand.item:
        if (consumeItem('potion')) {
          updatedPlayerStats = baseStats.copyWith(
            hp: min(baseStats.maxHp, baseStats.hp + 25),
          );
          baseStats = updatedPlayerStats;
          log = '你使用了治療藥水，回復 25 HP。';
          nextBattle = nextBattle.copyWith(log: log);
        } else {
          nextBattle = nextBattle.copyWith(log: '沒有可用的治療藥水。');
          activeBattle = nextBattle;
          notifyListeners();
          return;
        }
        break;
      case BattleCommand.run:
        if (!battle.canRun) {
          activeBattle = nextBattle.copyWith(log: '這場戰鬥無法逃跑。');
          notifyListeners();
          return;
        }
        activeBattle = null;
        hudMessage = '你成功脫離戰鬥。';
        notifyListeners();
        return;
    }

    final enemyDamage = clampDamage(
      enemy.attack,
      effectiveStats.defense + (nextBattle.playerGuarding ? 4 : 0),
      _random,
    );
    final remainingPlayerHp = max(0, updatedPlayerStats.hp - enemyDamage);
    baseStats = updatedPlayerStats.copyWith(hp: remainingPlayerHp);
    log = '${nextBattle.log}\n${enemy.name} 造成 $enemyDamage 點傷害。';

    if (remainingPlayerHp == 0) {
      activeBattle = null;
      baseStats = baseStats.copyWith(hp: baseStats.maxHp ~/ 2);
      hudMessage = '你被擊倒了，回到安全地點恢復。';
      notifyListeners();
      return;
    }

    activeBattle = nextBattle.copyWith(log: log, playerGuarding: false);
    notifyListeners();
  }

  void _finishBattle(EnemyDefinition enemy, {required bool won, required String openingLog}) {
    activeBattle = null;
    if (won) {
      if (enemy.rewardItemId case final rewardItemId?) {
        addItem(rewardItemId);
      }
      if (enemy.rewardFlag case final rewardFlag?) {
        storyFlags[rewardFlag] = true;
      }
      hudMessage = '$openingLog\n你擊敗了 ${enemy.name}！';
    } else {
      hudMessage = '戰鬥結束。';
    }
    notifyListeners();
  }

  void addItem(String itemId, {int quantity = 1, bool markObtained = false, bool silent = false}) {
    final item = itemCatalog[itemId];
    if (item == null) {
      return;
    }
    if (item.type == ItemType.weapon || item.type == ItemType.armor) {
      addEquipmentDrop(itemId, rarity: ItemRarity.common, markObtained: markObtained);
      if (!silent) {
        notifyListeners();
      }
      return;
    }
    final index = inventory.indexWhere((entry) => entry.itemId == itemId);
    if (index == -1) {
      inventory.add(
        InventoryEntry(
          itemId: itemId,
          quantity: quantity,
          entryId: '${itemId}_stack',
          justObtained: markObtained,
        ),
      );
    } else {
      final existing = inventory[index];
      inventory[index] = existing.copyWith(
        quantity: existing.quantity + quantity,
        justObtained: markObtained || existing.justObtained,
      );
    }
    if (!silent) {
      notifyListeners();
    }
  }

  bool consumeItem(String itemId, {int quantity = 1, bool silent = false}) {
    final index = inventory.indexWhere((entry) => entry.itemId == itemId);
    if (index == -1) {
      return false;
    }
    final entry = inventory[index];
    if (entry.quantity < quantity) {
      return false;
    }
    final remaining = entry.quantity - quantity;
    if (remaining == 0) {
      inventory.removeAt(index);
    } else {
      inventory[index] = entry.copyWith(quantity: remaining);
    }
    if (!silent) {
      notifyListeners();
    }
    return true;
  }

  void equipItem(String entryId) {
    final entry = _entryById(entryId);
    final item = entry?.item;
    if (entry == null || item == null) {
      return;
    }
    switch (item.type) {
      case ItemType.weapon:
        equipment = equipment.copyWith(weaponEntryId: entry.stableEntryId);
        hudMessage = '已裝備 ${item.name}。';
        break;
      case ItemType.armor:
        equipment = equipment.copyWith(armorEntryId: entry.stableEntryId);
        hudMessage = '已裝備 ${item.name}。';
        break;
      case ItemType.consumable:
      case ItemType.keyItem:
        hudMessage = '${item.name} 無法裝備。';
        break;
    }
    notifyListeners();
  }

  void clearObtainedHighlights() {
    var changed = false;
    for (var i = 0; i < inventory.length; i += 1) {
      if (inventory[i].justObtained) {
        inventory[i] = inventory[i].copyWith(justObtained: false);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }
}

class _AffixRoll {
  const _AffixRoll({
    required this.bonusAttack,
    required this.bonusDefense,
    required this.bonusMaxHp,
    required this.bonusMaxMp,
  });

  final int bonusAttack;
  final int bonusDefense;
  final int bonusMaxHp;
  final int bonusMaxMp;
}

class EquipmentPickupEvent {
  const EquipmentPickupEvent({
    required this.serial,
    required this.itemName,
    required this.rarity,
  });

  final int serial;
  final String itemName;
  final ItemRarity rarity;
}

class ChestRewardDialogState {
  const ChestRewardDialogState({
    required this.chestId,
    required this.itemId,
    required this.itemName,
  });

  final String chestId;
  final String itemId;
  final String itemName;
}
