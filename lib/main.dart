import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GameWidget(
    game: KennieGame(),
    overlayBuilderMap: {
      'MainMenu': (context, game) => MainMenuOverlay(game: game as KennieGame),
    },
    initialActiveOverlays: const ['MainMenu'],
  ));
}

class KennieGame extends FlameGame {
  bool hasSavedGame = false;

  @override
  Color backgroundColor() => const Color(0xFF0B1330);

  void startGame() {
    hasSavedGame = true;
    overlays.remove('MainMenu');
  }

  void continueGame(BuildContext context) {
    if (hasSavedGame) {
      overlays.remove('MainMenu');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('載入已保存遊戲...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目前沒有可繼續的進度。')),
      );
    }
  }

  void openSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('設定'),
          content: const Text('遊戲音量、畫面與操作設定將在此顯示。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('關閉'),
            ),
          ],
        );
      },
    );
  }

  void exitGame() {
    SystemNavigator.pop();
  }
}

class MainMenuOverlay extends StatelessWidget {
  final KennieGame game;

  const MainMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(0, 0, 0, 0.65),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kennie',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'RPG 解謎冒險',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 36),
              _MenuButton(
                label: '開始遊戲',
                onPressed: game.startGame,
              ),
              const SizedBox(height: 16),
              _MenuButton(
                label: '繼續遊戲',
                onPressed: () => game.continueGame(context),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                label: '設定',
                onPressed: () => game.openSettings(context),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                label: '離開',
                onPressed: game.exitGame,
                accent: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool accent;

  const _MenuButton({
    required this.label,
    required this.onPressed,
    this.accent = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent ? const Color(0xFF4C8DFF) : Colors.white24,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
