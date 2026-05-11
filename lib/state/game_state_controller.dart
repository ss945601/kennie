import 'dart:math';

import 'package:flutter/foundation.dart';

import 'models/game_models.dart';
import 'services/save_repository.dart';

class GameStateController extends ChangeNotifier {
  GameStateController({required SaveRepository saveRepository})
      : _saveRepository = saveRepository;

  final SaveRepository _saveRepository;
  final Random _random = Random();

  bool showTitleMenu = true;
  bool hasSaveFile = false;
  bool isPauseMenuOpen = false;
  double transitionOpacity = 1;
  String currentMapId = 'village';
  String currentSpawnId = 'village_square';
  double playerX = 608;
  double playerY = 544;
  int level = 1;
  int experience = 0;
  int nextLevelExperience = 30;
  PlayerStats baseStats = const PlayerStats(
    maxHp: 64,
    hp: 64,
    maxMp: 30,
    mp: 30,
    attack: 12,
    defense: 6,
  );
  EquipmentLoadout equipment = const EquipmentLoadout(
    weaponId: 'bronze_sword',
    armorId: 'cloth_armor',
  );
  final Map<String, bool> storyFlags = <String, bool>{};
  final List<InventoryEntry> inventory = <InventoryEntry>[
    const InventoryEntry(itemId: 'potion', quantity: 2),
    const InventoryEntry(itemId: 'bronze_sword', quantity: 1),
    const InventoryEntry(itemId: 'cloth_armor', quantity: 1),
  ];

  DialogSession? activeDialog;
  BattleState? activeBattle;
  String hudMessage = '方向鍵移動，J 近戰，K 火球，Space 互動，Esc 開選單';

  Future<void> initialize() async {
    hasSaveFile = await _saveRepository.hasSave();
    transitionOpacity = 0;
    notifyListeners();
  }

  PlayerStats get effectiveStats {
    final weapon = equipment.weaponId == null ? null : itemCatalog[equipment.weaponId!];
    final armor = equipment.armorId == null ? null : itemCatalog[equipment.armorId!];
    return baseStats.copyWith(
      attack: baseStats.attack + (weapon?.attackBonus ?? 0),
      defense: baseStats.defense + (armor?.defenseBonus ?? 0),
    );
  }

  bool get isFieldInputLocked =>
      showTitleMenu || isPauseMenuOpen || activeDialog != null || transitionOpacity > 0.05;

  bool get isOverlayBusy => activeDialog != null || isPauseMenuOpen;

  bool flag(String key) => storyFlags[key] ?? false;

  void setFlag(String key, bool value) {
    storyFlags[key] = value;
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
    playerX = 608;
    playerY = 544;
    level = 1;
    experience = 0;
    nextLevelExperience = 30;
    transitionOpacity = 0;
    storyFlags
      ..clear()
      ..addAll({
        'intro_seen': false,
        'has_key_01': false,
        'merchant_gift_claimed': false,
      });
    inventory
      ..clear()
      ..addAll(const [
        InventoryEntry(itemId: 'potion', quantity: 2),
        InventoryEntry(itemId: 'bronze_sword', quantity: 1),
        InventoryEntry(itemId: 'cloth_armor', quantity: 1),
      ]);
    baseStats = const PlayerStats(maxHp: 64, hp: 64, maxMp: 30, mp: 30, attack: 12, defense: 6);
    equipment = const EquipmentLoadout(weaponId: 'bronze_sword', armorId: 'cloth_armor');
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
    showTitleMenu = false;
    hudMessage = '已載入存檔。';
    notifyListeners();
    return true;
  }

  Future<void> saveGame() async {
    final snapshot = GameSnapshot(
      currentMapId: currentMapId,
      currentSpawnId: currentSpawnId,
      playerX: playerX,
      playerY: playerY,
      level: level,
      experience: experience,
      nextLevelExperience: nextLevelExperience,
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
    hudMessage = '存檔讀取完成。';
    notifyListeners();
    return true;
  }

  void _applySnapshot(GameSnapshot snapshot) {
    currentMapId = snapshot.currentMapId;
    currentSpawnId = snapshot.currentSpawnId;
    playerX = snapshot.playerX;
    playerY = snapshot.playerY;
    level = snapshot.level;
    experience = snapshot.experience;
    nextLevelExperience = snapshot.nextLevelExperience;
    storyFlags
      ..clear()
      ..addAll(snapshot.storyFlags);
    inventory
      ..clear()
      ..addAll(snapshot.inventory);
    equipment = snapshot.equipment;
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

  void onEnemyDefeated(EnemyDefinition enemy, {String? defeatedFlag, String? messagePrefix}) {
    if (enemy.rewardItemId case final rewardItemId?) {
      addItem(rewardItemId);
    }
    if (enemy.rewardFlag case final rewardFlag?) {
      storyFlags[rewardFlag] = true;
    }
    if (defeatedFlag != null) {
      storyFlags[defeatedFlag] = true;
    }
    gainExperience(enemy.experienceReward);
    final prefix = messagePrefix == null ? '' : '$messagePrefix ';
    hudMessage = '$prefix擊敗 ${enemy.name}，獲得 ${enemy.experienceReward} EXP。';
    notifyListeners();
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
    if (choice.setFlagKey case final key?) {
      storyFlags[key] = true;
    }
    if (choice.giveItemId case final itemId?) {
      addItem(itemId);
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

  void addItem(String itemId, {int quantity = 1}) {
    final index = inventory.indexWhere((entry) => entry.itemId == itemId);
    if (index == -1) {
      inventory.add(InventoryEntry(itemId: itemId, quantity: quantity));
    } else {
      final existing = inventory[index];
      inventory[index] = existing.copyWith(quantity: existing.quantity + quantity);
    }
    notifyListeners();
  }

  bool consumeItem(String itemId, {int quantity = 1}) {
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
    notifyListeners();
    return true;
  }

  void equipItem(String itemId) {
    final item = itemCatalog[itemId];
    if (item == null) {
      return;
    }
    switch (item.type) {
      case ItemType.weapon:
        equipment = equipment.copyWith(weaponId: itemId);
        hudMessage = '已裝備 ${item.name}。';
        break;
      case ItemType.armor:
        equipment = equipment.copyWith(armorId: itemId);
        hudMessage = '已裝備 ${item.name}。';
        break;
      case ItemType.consumable:
      case ItemType.keyItem:
        hudMessage = '${item.name} 無法裝備。';
        break;
    }
    notifyListeners();
  }
}
