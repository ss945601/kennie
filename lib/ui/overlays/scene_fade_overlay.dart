import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state_controller.dart';

class SceneFadeOverlay extends StatelessWidget {
  const SceneFadeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Consumer<GameStateController>(
        builder: (context, controller, _) {
          return AnimatedOpacity(
            opacity: controller.transitionOpacity,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: const ColoredBox(color: Colors.black),
          );
        },
      ),
    );
  }
}
