import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state_controller.dart';
import '../../state/models/game_models.dart';
import '../responsive_overlay.dart';

class BattleOverlay extends StatelessWidget {
  const BattleOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = OverlayUiConfig.of(context);
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
              padding: ui.all(16, compactValue: 10),
              child: Column(
                children: [
                  Flex(
                    direction: ui.stackedLayout ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _BattlePanel(
                          title: '玩家',
                          body: 'HP ${controller.baseStats.hp}/${controller.baseStats.maxHp}\nMP ${controller.baseStats.mp}/${controller.baseStats.maxMp}\nATK ${stats.attack} / DEF ${stats.defense}',
                          compact: ui.compact,
                        ),
                      ),
                      SizedBox(width: ui.stackedLayout ? 0 : ui.value(12, compactValue: 8), height: ui.stackedLayout ? ui.value(12, compactValue: 8) : 0),
                      Expanded(
                        child: _BattlePanel(
                          title: battle.enemyName,
                          body: 'HP ${battle.enemyHp}/${battle.enemyMaxHp}',
                          compact: ui.compact,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ui.value(16, compactValue: 10)),
                  _BattlePanel(title: '戰鬥紀錄', body: battle.log, expand: true, compact: ui.compact),
                  SizedBox(height: ui.value(16, compactValue: 10)),
                  Wrap(
                    spacing: ui.value(8, compactValue: 6),
                    runSpacing: ui.value(8, compactValue: 6),
                    children: [
                      FilledButton(
                        onPressed: () => controller.performBattleCommand(BattleCommand.attack),
                        child: Text('攻擊', style: TextStyle(fontSize: ui.font(14, compactValue: 11))),
                      ),
                      FilledButton.tonal(
                        onPressed: () => controller.performBattleCommand(BattleCommand.guard),
                        child: Text('防禦', style: TextStyle(fontSize: ui.font(14, compactValue: 11))),
                      ),
                      FilledButton.tonal(
                        onPressed: () => controller.performBattleCommand(BattleCommand.item),
                        child: Text('道具', style: TextStyle(fontSize: ui.font(14, compactValue: 11))),
                      ),
                      OutlinedButton(
                        onPressed: battle.canRun ? () => controller.performBattleCommand(BattleCommand.run) : null,
                        child: Text('逃跑', style: TextStyle(fontSize: ui.font(14, compactValue: 11))),
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
    required this.compact,
    this.expand = false,
  });

  final String title;
  final String body;
  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: compact ? 16 : null,
                ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(body, style: TextStyle(color: Colors.white70, height: 1.35, fontSize: compact ? 11 : 14)),
        ],
      ),
    );
    return expand ? Expanded(child: content) : content;
  }
}
