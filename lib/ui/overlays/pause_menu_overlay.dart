import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/rpg_game.dart';
import '../../state/game_state_controller.dart';
import '../../state/models/game_models.dart';

class PauseMenuOverlay extends StatelessWidget {
  const PauseMenuOverlay({
    super.key,
    required this.game,
  });

  final RpgGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xA0000000),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Card(
            color: const Color(0xF0121826),
            child: Padding(
              padding: const EdgeInsets.all(22),
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
                                  ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: controller.closePauseMenu,
                            child: const Text('返回戰場'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilledButton(
                                      onPressed: game.saveGame,
                                      child: const Text('存檔'),
                                    ),
                                    FilledButton.tonal(
                                      onPressed: game.loadGame,
                                      child: const Text('讀檔'),
                                    ),
                                    FilledButton.tonal(
                                      onPressed: controller.usePotionQuick,
                                      child: Text('藥水 x$potionCount'),
                                    ),
                                    OutlinedButton(
                                      onPressed: controller.returnToTitleMenu,
                                      child: const Text('回初始選單'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  '背包',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 240,
                                  child: ListView.separated(
                                    itemCount: controller.inventory.length,
                                    separatorBuilder: (_, _) => const Divider(color: Colors.white12),
                                    itemBuilder: (context, index) {
                                      final entry = controller.inventory[index];
                                      final item = entry.item;
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(item.name, style: const TextStyle(color: Colors.white)),
                                        subtitle: Text(item.description, style: const TextStyle(color: Colors.white70)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('x${entry.quantity}', style: const TextStyle(color: Colors.white)),
                                            const SizedBox(width: 8),
                                            if (item.type == ItemType.weapon || item.type == ItemType.armor)
                                              TextButton(
                                                onPressed: () => controller.equipItem(item.id),
                                                child: const Text('裝備'),
                                              )
                                            else if (item.type == ItemType.consumable)
                                              TextButton(
                                                onPressed: controller.usePotionQuick,
                                                child: const Text('使用'),
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
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0x991C2434),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '戰鬥資料',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 12),
                                    _InfoLine(label: '等級', value: 'Lv.${controller.level}'),
                                    _InfoLine(
                                      label: '經驗值',
                                      value: '${controller.experience}/${controller.nextLevelExperience}',
                                    ),
                                    _InfoLine(label: 'HP', value: '${stats.hp}/${stats.maxHp}'),
                                    _InfoLine(label: '攻擊', value: '${stats.attack}'),
                                    _InfoLine(label: '防禦', value: '${stats.defense}'),
                                    const SizedBox(height: 12),
                                    Text(
                                      '裝備',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 8),
                                    _InfoLine(
                                      label: '武器',
                                      value: itemCatalog[controller.equipment.weaponId]?.name ?? '-',
                                    ),
                                    _InfoLine(
                                      label: '防具',
                                      value: itemCatalog[controller.equipment.armorId]?.name ?? '-',
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '提示',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '主動怪會在視野內追擊你，被動怪只有在接戰後才會反撲。用拉打維持血量。',
                                      style: TextStyle(color: Colors.white70, height: 1.5),
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
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
