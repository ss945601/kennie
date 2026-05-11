import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state_controller.dart';
import '../responsive_overlay.dart';

class ChestRewardOverlay extends StatelessWidget {
  const ChestRewardOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = OverlayUiConfig.of(context);
    return Consumer<GameStateController>(
      builder: (context, controller, _) {
        final dialog = controller.activeChestRewardDialog;
        if (dialog == null) {
          return const SizedBox.shrink();
        }
        return ColoredBox(
          color: const Color(0x66000000),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ui.stackedLayout ? 320 : 420),
              child: Card(
                color: const Color(0xF0121826),
                child: Padding(
                  padding: ui.all(14, compactValue: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '寶箱',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: ui.font(18, compactValue: 14),
                            ),
                      ),
                      SizedBox(height: ui.value(8, compactValue: 6)),
                      Text(
                        '獲得 ${dialog.itemName}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ui.font(15, compactValue: 12),
                        ),
                      ),
                      SizedBox(height: ui.value(12, compactValue: 9)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: controller.confirmChestRewardDialog,
                          child: Text(
                            '確定',
                            style: TextStyle(fontSize: ui.font(13, compactValue: 11)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
