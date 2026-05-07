import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'menu_overlay.dart';
import 'game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    theme: flutterNesTheme(),
    home: GameWidget(
      game: KennieGame(),
      overlayBuilderMap: {
        'MainMenu': (context, game) {
          final kennieGame = game as KennieGame;
          return MainMenuOverlay(
            onStartGame: kennieGame.startGame,
            onContinueGame: kennieGame.continueGame,
            onOpenSettings: kennieGame.openSettings,
            onExitGame: kennieGame.exitGame,
          );
        },
      },
      initialActiveOverlays: const ['MainMenu'],
    ),
  ));
}

