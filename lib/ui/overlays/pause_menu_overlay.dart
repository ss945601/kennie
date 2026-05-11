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
        child: Center(
          child: SingleChildScrollView(
            padding: ui.all(16, compactValue: 10),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ui.stackedLayout ? 640 : 860),
              child: Card(
                color: const Color(0xF0121826),
                child: Padding(
                  padding: ui.all(22, compactValue: 12),
                  child: Consumer<GameStateController>(
                    builder: (context, controller, _) {
                      final stats = controller.effectiveStats;
                      final potionCount = controller.inventory
                          .where((entry) => entry.itemId == 'potion')
                          .fold<int>(0, (total, entry) => total + entry.quantity);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '冒險暫停',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: ui.compact ? 20 : null,
                                      ),
                                ),
                              ),
                              OutlinedButton(
                                onPressed: controller.closePauseMenu,
                                child: Text('返回戰場', style: TextStyle(fontSize: ui.compact ? 12 : null)),
                              ),
                            ],
                          ),
                          SizedBox(height: ui.value(16, compactValue: 10)),
                          Flex(
                            direction: ui.stackedLayout ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: ui.stackedLayout ? 0 : 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: ui.value(8, compactValue: 6),
                                      runSpacing: ui.value(8, compactValue: 6),
                                      children: [
                                        FilledButton(
                                          onPressed: game.saveGame,
                                          child: Text('存檔', style: TextStyle(fontSize: ui.compact ? 12 : null)),
                                        ),
                                        FilledButton.tonal(
                                          onPressed: game.loadGame,
                                          child: Text('讀檔', style: TextStyle(fontSize: ui.compact ? 12 : null)),
                                        ),
                                        FilledButton.tonal(
                                          onPressed: controller.usePotionQuick,
                                          child: Text('藥水 x$potionCount', style: TextStyle(fontSize: ui.compact ? 12 : null)),
                                        ),
                                        OutlinedButton(
                                          onPressed: controller.returnToTitleMenu,
                                          child: Text('回初始選單', style: TextStyle(fontSize: ui.compact ? 12 : null)),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: ui.value(18, compactValue: 12)),
                                    Text(
                                      '背包',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Colors.white,
                                            fontSize: ui.compact ? 15 : null,
                                          ),
                                    ),
                                    SizedBox(height: ui.value(8, compactValue: 6)),
                                    SizedBox(
                                      height: ui.value(240, compactValue: 180),
                                      child: ListView.separated(
                                        itemCount: controller.inventory.length,
                                        separatorBuilder: (_, _) => const Divider(color: Colors.white12),
                                        itemBuilder: (context, index) {
                                          final entry = controller.inventory[index];
                                          final item = entry.item;
                                          return ListTile(
                                            dense: ui.compact,
                                            visualDensity: ui.compact ? VisualDensity.compact : VisualDensity.standard,
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(
                                              item.name,
                                              style: TextStyle(color: Colors.white, fontSize: ui.font(14, compactValue: 12)),
                                            ),
                                            subtitle: Text(
                                              item.description,
                                              style: TextStyle(color: Colors.white70, fontSize: ui.font(12, compactValue: 10.5)),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'x${entry.quantity}',
                                                  style: TextStyle(color: Colors.white, fontSize: ui.font(14, compactValue: 11)),
                                                ),
                                                SizedBox(width: ui.value(8, compactValue: 4)),
                                                if (item.type == ItemType.weapon || item.type == ItemType.armor)
                                                  TextButton(
                                                    onPressed: () => controller.equipItem(item.id),
                                                    child: Text('裝備', style: TextStyle(fontSize: ui.compact ? 11 : null)),
                                                  )
                                                else if (item.type == ItemType.consumable)
                                                  TextButton(
                                                    onPressed: controller.usePotionQuick,
                                                    child: Text('使用', style: TextStyle(fontSize: ui.compact ? 11 : null)),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: ui.stackedLayout ? 0 : 20, height: ui.stackedLayout ? 12 : 0),
                              Expanded(
                                flex: ui.stackedLayout ? 0 : 2,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0x991C2434),
                                    borderRadius: BorderRadius.circular(ui.radius(18, compactValue: 14)),
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
                                        _InfoLine(label: '等級', value: 'Lv.${controller.level}', compact: ui.compact),
                                        _InfoLine(
                                          label: '經驗值',
                                          value: '${controller.experience}/${controller.nextLevelExperience}',
                                          compact: ui.compact,
                                        ),
                                        _InfoLine(label: 'HP', value: '${stats.hp}/${stats.maxHp}', compact: ui.compact),
                                        _InfoLine(label: 'MP', value: '${stats.mp}/${stats.maxMp}', compact: ui.compact),
                                        _InfoLine(label: '攻擊', value: '${stats.attack}', compact: ui.compact),
                                        _InfoLine(label: '防禦', value: '${stats.defense}', compact: ui.compact),
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
                                          value: itemCatalog[controller.equipment.weaponId]?.name ?? '-',
                                          compact: ui.compact,
                                        ),
                                        _InfoLine(
                                          label: '防具',
                                          value: itemCatalog[controller.equipment.armorId]?.name ?? '-',
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
                        ],
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
            child: Text(label, style: TextStyle(color: Colors.white54, fontSize: compact ? 10 : 14)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.white, fontSize: compact ? 10.5 : 14)),
          ),
        ],
      ),
    );
  }
}
