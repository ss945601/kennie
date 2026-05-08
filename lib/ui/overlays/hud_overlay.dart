import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state_controller.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        child: Consumer<GameStateController>(
          builder: (context, controller, _) {
            final stats = controller.effectiveStats;
            final potionCount = controller.inventory
                .where((entry) => entry.itemId == 'potion')
                .fold<int>(0, (total, entry) => total + entry.quantity);
            final expProgress = controller.nextLevelExperience == 0
                ? 0.0
                : (controller.experience / controller.nextLevelExperience).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Panel(
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/health_ui.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lv.${controller.level}  ${controller.currentMapId.toUpperCase()}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: stats.maxHp == 0 ? 0 : stats.hp / stats.maxHp,
                                minHeight: 10,
                                backgroundColor: Colors.white12,
                                color: const Color(0xFFE25B5B),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: expProgress,
                                minHeight: 8,
                                backgroundColor: Colors.white10,
                                color: const Color(0xFF7AE582),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: <Widget>[
                                  Text('HP ${stats.hp}/${stats.maxHp}', style: const TextStyle(color: Colors.white)),
                                  Text('ATK ${stats.attack}', style: const TextStyle(color: Colors.white)),
                                  Text('DEF ${stats.defense}', style: const TextStyle(color: Colors.white)),
                                  Text('藥水 x$potionCount', style: const TextStyle(color: Colors.white)),
                                  Text('EXP ${controller.experience}/${controller.nextLevelExperience}',
                                      style: const TextStyle(color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Panel(
                    color: const Color(0xB2182438),
                    child: Text(
                      controller.hudMessage,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _Panel(
                    color: Color(0x99121820),
                    child: Text(
                      'J/Enter 攻擊  H/1 藥水  Space 互動  Esc 選單',
                      style: TextStyle(color: Colors.white54),
                    ),
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

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.color = const Color(0xCC111827),
  });

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: child,
      ),
    );
  }
}
