import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state_controller.dart';
import '../../state/models/game_models.dart';

class BattleOverlay extends StatelessWidget {
  const BattleOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xCC120D18),
      child: SafeArea(
        child: Consumer<GameStateController>(
          builder: (context, controller, _) {
            final battle = controller.activeBattle;
            if (battle == null) {
              return const SizedBox.shrink();
            }
            final stats = controller.effectiveStats;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _BattlePanel(
                          title: '玩家',
                          body: 'HP ${controller.baseStats.hp}/${controller.baseStats.maxHp}\nATK ${stats.attack} / DEF ${stats.defense}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BattlePanel(
                          title: battle.enemyName,
                          body: 'HP ${battle.enemyHp}/${battle.enemyMaxHp}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _BattlePanel(title: '戰鬥紀錄', body: battle.log, expand: true),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => controller.performBattleCommand(BattleCommand.attack),
                        child: const Text('攻擊'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => controller.performBattleCommand(BattleCommand.guard),
                        child: const Text('防禦'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => controller.performBattleCommand(BattleCommand.item),
                        child: const Text('道具'),
                      ),
                      OutlinedButton(
                        onPressed: battle.canRun ? () => controller.performBattleCommand(BattleCommand.run) : null,
                        child: const Text('逃跑'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BattlePanel extends StatelessWidget {
  const _BattlePanel({
    required this.title,
    required this.body,
    this.expand = false,
  });

  final String title;
  final String body;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: Colors.white70, height: 1.4)),
        ],
      ),
    );
    return expand ? Expanded(child: content) : content;
  }
}
