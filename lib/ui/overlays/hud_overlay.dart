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
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xCC111827),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: DefaultTextStyle(
                        style: const TextStyle(color: Colors.white),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Map: ${controller.currentMapId}'),
                            const SizedBox(width: 16),
                            Text('HP ${stats.hp}/${stats.maxHp}'),
                            const SizedBox(width: 16),
                            Text('ATK ${stats.attack}'),
                            const SizedBox(width: 16),
                            Text('DEF ${stats.defense}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xB2182438),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        controller.hudMessage,
                        style: const TextStyle(color: Colors.white70),
                      ),
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
