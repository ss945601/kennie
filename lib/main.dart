import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_overlay.dart';
import 'settings_screen.dart';
import 'game.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    theme: flutterNesTheme().copyWith(
      textTheme: GoogleFonts.pressStart2pTextTheme(),
    ),
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context);
      final shortestSide = mediaQuery.size.shortestSide;
      // Base text scale on window size and clamp to keep UI readable.
      final scale = (shortestSide / 430).clamp(0.75, 1.45);
      return MediaQuery(
        data: mediaQuery.copyWith(textScaler: TextScaler.linear(scale)),
        child: child ?? const SizedBox.shrink(),
      );
    },
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
        'Settings': (context, game) {
          final kennieGame = game as KennieGame;
          return SettingsOverlay(game: kennieGame);
        },
      },
      initialActiveOverlays: const ['MainMenu'],
    ),
  ));
}

