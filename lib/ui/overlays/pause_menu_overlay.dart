import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/rpg_game.dart';
import '../../state/game_state_controller.dart';
import '../../state/models/game_models.dart';
import '../responsive_overlay.dart';

class PauseMenuOverlay extends StatelessWidget {
  const PauseMenuOverlay({
    super.key,
    required this.game,
  });

  final RpgGame game;

  @override
  Widget build(BuildContext context) {
    final ui = OverlayUiConfig.of(context);
    return ColoredBox(
      color: const Color(0xA0000000),
      child: SafeArea(
        child: Padding(
          padding: ui.all(12, compactValue: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ui.stackedLayout ? 600 : 780,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Card(
                color: const Color(0xF0121826),
                child: Padding(
                  padding: ui.all(14, compactValue: 9),
                  child: Consumer<GameStateController>(
                    builder: (context, controller, _) {
                      final stats = controller.effectiveStats;
                      InventoryEntry? equippedWeapon;
                      InventoryEntry? equippedArmor;
                      for (final entry in controller.inventory) {
                        if (entry.stableEntryId == controller.equipment.weaponEntryId) {
                          equippedWeapon = entry;
                        }
                        if (entry.stableEntryId == controller.equipment.armorEntryId) {
                          equippedArmor = entry;
                        }
                      }

                      final potionCount = controller.inventory
                          .where((entry) => entry.itemId == 'potion')
                          .fold<int>(0, (total, entry) => total + entry.quantity);
                      final manaPotionCount = controller.inventory
                          .where((entry) => entry.itemId == 'mana_potion')
                          .fold<int>(0, (total, entry) => total + entry.quantity);

                      return DefaultTabController(
                        length: 3,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ui.stackedLayout) ...[
                              Text(
                                '冒險暫停',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: ui.font(20, compactValue: 16),
                                    ),
                              ),
                              SizedBox(height: ui.value(8, compactValue: 6)),
                              Row(
                                children: [
                                  _goldPill(controller: controller, ui: ui),
                                  const Spacer(),
                                  OutlinedButton(
                                    onPressed: controller.closePauseMenu,
                                    child: Text(
                                      '返回戰場',
                                      style: TextStyle(fontSize: ui.font(12, compactValue: 10)),
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '冒險暫停',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: ui.font(20, compactValue: 16),
                                          ),
                                    ),
                                  ),
                                  _goldPill(controller: controller, ui: ui),
                                  OutlinedButton(
                                    onPressed: controller.closePauseMenu,
                                    child: Text(
                                      '返回戰場',
                                      style: TextStyle(fontSize: ui.font(12, compactValue: 10)),
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(height: ui.value(10, compactValue: 7)),
                            TabBar(
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white70,
                              indicatorColor: Colors.white,
                              labelStyle: TextStyle(
                                fontSize: ui.font(13, compactValue: 11),
                                fontWeight: FontWeight.w600,
                              ),
                              unselectedLabelStyle: TextStyle(
                                fontSize: ui.font(12, compactValue: 10.5),
                                fontWeight: FontWeight.w500,
                              ),
                              labelPadding: EdgeInsets.symmetric(
                                horizontal: ui.value(8, compactValue: 4),
                              ),
                              indicatorWeight: 2,
                              tabs: const [
                                Tab(text: '操作'),
                                Tab(text: '背包'),
                                Tab(text: '戰鬥資料'),
                              ],
                            ),
                            SizedBox(height: ui.value(8, compactValue: 6)),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  SingleChildScrollView(
                                    padding: EdgeInsets.only(right: ui.value(2, compactValue: 0)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: ui.value(8, compactValue: 6),
                                          runSpacing: ui.value(8, compactValue: 6),
                                          children: [
                                            FilledButton(
                                              onPressed: game.saveGame,
                                              child: Text(
                                                '存檔',
                                                style: TextStyle(fontSize: ui.font(12, compactValue: 10)),
                                              ),
                                            ),
                                            FilledButton.tonal(
                                              onPressed: game.loadGame,
                                              child: Text(
                                                '讀檔',
                                                style: TextStyle(fontSize: ui.font(12, compactValue: 10)),
                                              ),
                                            ),
                                            FilledButton.tonal(
                                              onPressed: controller.usePotionQuick,
                                              child: Text(
                                                '藥水 x$potionCount',
                                                style: TextStyle(fontSize: ui.font(12, compactValue: 10)),
                                              ),
                                            ),
                                            FilledButton.tonal(
                                              onPressed: controller.useManaPotionQuick,
                                              child: Text(
                                                '魔力藥水 x$manaPotionCount',
                                                style: TextStyle(fontSize: ui.font(12, compactValue: 10)),
                                              ),
                                            ),
                                            OutlinedButton(
                                              onPressed: controller.returnToTitleMenu,
                                              child: Text(
                                                '回初始選單',
                                                style: TextStyle(fontSize: ui.font(12, compactValue: 10)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: ui.value(16, compactValue: 12)),
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: const Color(0x991C2434),
                                            borderRadius: BorderRadius.circular(
                                              ui.radius(14, compactValue: 12),
                                            ),
                                            border: Border.all(color: Colors.white12),
                                          ),
                                          child: Padding(
                                            padding: ui.all(12, compactValue: 10),
                                            child: Text(
                                              '快速提示\n• J 近戰、K 火球\n• 靠近怪物會有碰撞傷害\n• 受擊會震退，注意站位',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                height: 1.5,
                                                fontSize: ui.font(14, compactValue: 11),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ListView.separated(
                                    primary: false,
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: ClampingScrollPhysics(),
                                    ),
                                    itemCount: controller.inventory.length,
                                    separatorBuilder: (_, _) => const Divider(color: Colors.white12),
                                    itemBuilder: (context, index) {
                                      final entry = controller.inventory[index];
                                      final item = entry.item;
                                      final isEquipped =
                                          controller.equipment.weaponEntryId == entry.stableEntryId ||
                                          controller.equipment.armorEntryId == entry.stableEntryId;
                                      final rarityColor = switch (entry.rarity) {
                                        ItemRarity.common => Colors.white,
                                        ItemRarity.uncommon => const Color(0xFFB0FFC0),
                                        ItemRarity.rare => const Color(0xFF8FD5FF),
                                        ItemRarity.epic => const Color(0xFFE4A4FF),
                                        ItemRarity.legendary => const Color(0xFFFFD27B),
                                      };
                                      final highlightedColor =
                                          entry.justObtained ? const Color(0xFFFF5E5E) : rarityColor;
                                      final affixText = <String>[
                                        if (entry.bonusAttack > 0) 'ATK+${entry.bonusAttack}',
                                        if (entry.bonusDefense > 0) 'DEF+${entry.bonusDefense}',
                                        if (entry.bonusMaxHp > 0) 'HP+${entry.bonusMaxHp}',
                                        if (entry.bonusMaxMp > 0) 'MP+${entry.bonusMaxMp}',
                                      ].join('  ');

                                      return ListTile(
                                        dense: ui.compact,
                                        visualDensity: ui.compact
                                            ? VisualDensity.compact
                                            : VisualDensity.standard,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          '${entry.justObtained ? '!! ' : ''}${item.name}${isEquipped ? ' (已裝備)' : ''}',
                                          style: TextStyle(
                                            color: highlightedColor,
                                            fontSize: ui.font(14, compactValue: 12),
                                          ),
                                        ),
                                        subtitle: Text(
                                          affixText.isEmpty
                                              ? item.description
                                              : '${item.description}\n$affixText',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: ui.font(12, compactValue: 10.5),
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'x${entry.quantity}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: ui.font(14, compactValue: 11),
                                              ),
                                            ),
                                            SizedBox(width: ui.value(8, compactValue: 4)),
                                            if (item.type == ItemType.weapon ||
                                                item.type == ItemType.armor)
                                              TextButton(
                                                onPressed: () =>
                                                    controller.equipItem(entry.stableEntryId),
                                                child: Text(
                                                  '裝備',
                                                  style: TextStyle(
                                                    fontSize: ui.font(11, compactValue: 9.5),
                                                  ),
                                                ),
                                              )
                                            else if (item.type == ItemType.consumable)
                                              TextButton(
                                                onPressed: item.id == 'mana_potion'
                                                    ? controller.useManaPotionQuick
                                                    : controller.usePotionQuick,
                                                child: Text(
                                                  '使用',
                                                  style: TextStyle(
                                                    fontSize: ui.font(11, compactValue: 9.5),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  SingleChildScrollView(
                                    padding: EdgeInsets.only(right: ui.value(2, compactValue: 0)),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0x991C2434),
                                        borderRadius: BorderRadius.circular(
                                          ui.radius(18, compactValue: 14),
                                        ),
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: Padding(
                                        padding: ui.all(16, compactValue: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '戰鬥資料',
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    color: Colors.white,
                                                    fontSize: ui.compact ? 18 : null,
                                                  ),
                                            ),
                                            SizedBox(height: ui.value(12, compactValue: 8)),
                                            _InfoLine(
                                              label: '等級',
                                              value: 'Lv.${controller.level}',
                                              compact: ui.compact,
                                            ),
                                            _InfoLine(
                                              label: '經驗值',
                                              value:
                                                  '${controller.experience}/${controller.nextLevelExperience}',
                                              compact: ui.compact,
                                            ),
                                            _InfoLine(
                                              label: 'HP',
                                              value: '${stats.hp}/${stats.maxHp}',
                                              compact: ui.compact,
                                            ),
                                            _InfoLine(
                                              label: 'MP',
                                              value: '${stats.mp}/${stats.maxMp}',
                                              compact: ui.compact,
                                            ),
                                            _InfoLine(
                                              label: '攻擊',
                                              value: '${stats.attack}',
                                              compact: ui.compact,
                                            ),
                                            _InfoLine(
                                              label: '防禦',
                                              value: '${stats.defense}',
                                              compact: ui.compact,
                                            ),
                                            SizedBox(height: ui.value(12, compactValue: 8)),
                                            Text(
                                              '裝備',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    color: Colors.white,
                                                    fontSize: ui.compact ? 15 : null,
                                                  ),
                                            ),
                                            SizedBox(height: ui.value(8, compactValue: 6)),
                                            _InfoLine(
                                              label: '武器',
                                              value: equippedWeapon == null
                                                  ? '-'
                                                  : _equipmentLabel(equippedWeapon),
                                              compact: ui.compact,
                                            ),
                                            _InfoLine(
                                              label: '防具',
                                              value: equippedArmor == null
                                                  ? '-'
                                                  : _equipmentLabel(equippedArmor),
                                              compact: ui.compact,
                                            ),
                                            SizedBox(height: ui.value(12, compactValue: 8)),
                                            Text(
                                              '提示',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    color: Colors.white,
                                                    fontSize: ui.compact ? 15 : null,
                                                  ),
                                            ),
                                            SizedBox(height: ui.value(8, compactValue: 6)),
                                            Text(
                                              '主動怪會在視野內追擊你，被動怪只有在接戰後才會反撲。用拉打維持血量。',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                height: 1.5,
                                                fontSize: ui.font(14, compactValue: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _goldPill extends StatelessWidget {
  const _goldPill({
    required this.controller,
    required this.ui,
  });

  final GameStateController controller;
  final OverlayUiConfig ui;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: ui.value(10, compactValue: 6)),
      padding: EdgeInsets.symmetric(
        horizontal: ui.value(10, compactValue: 8),
        vertical: ui.value(6, compactValue: 4),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2F22),
        borderRadius: BorderRadius.circular(ui.radius(10, compactValue: 8)),
        border: Border.all(color: const Color(0x77D7B95C)),
      ),
      child: Text(
        '金幣 ${controller.gold}',
        style: TextStyle(
          color: const Color(0xFFFFE79A),
          fontSize: ui.font(14, compactValue: 11),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 3 : 6),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 44 : 56,
            child: Text(
              label,
              style: TextStyle(color: Colors.white54, fontSize: compact ? 10 : 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.white, fontSize: compact ? 10.5 : 14),
            ),
          ),
        ],
      ),
    );
  }
}

String _equipmentLabel(InventoryEntry entry) {
  final affixText = <String>[
    if (entry.bonusAttack > 0) 'ATK+${entry.bonusAttack}',
    if (entry.bonusDefense > 0) 'DEF+${entry.bonusDefense}',
    if (entry.bonusMaxHp > 0) 'HP+${entry.bonusMaxHp}',
    if (entry.bonusMaxMp > 0) 'MP+${entry.bonusMaxMp}',
  ].join('/');
  if (affixText.isEmpty) {
    return entry.item.name;
  }
  return '${entry.item.name} [$affixText]';
}
