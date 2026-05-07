import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

typedef ContinueGameCallback = void Function(BuildContext context);

typedef SettingsCallback = void Function(BuildContext context);

class MainMenuOverlay extends StatelessWidget {
  final VoidCallback onStartGame;
  final ContinueGameCallback onContinueGame;
  final SettingsCallback onOpenSettings;
  final VoidCallback onExitGame;

  const MainMenuOverlay({
    super.key,
    required this.onStartGame,
    required this.onContinueGame,
    required this.onOpenSettings,
    required this.onExitGame,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/menu_bg.jpg',
          fit: BoxFit.cover,
        ),
        Container(
          color: const Color.fromRGBO(0, 0, 0, 0.65),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth:500, maxHeight: MediaQuery.of(context).size.height * 0.8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Spacer(),
                      Expanded(
                        child: Text(
                          'Kennie の 大冒險',
                          style: const TextStyle(
                            // Using monospace fallback so app builds without bundled font
                            fontFamily: 'monospace',
                            color: Colors.white,
                            fontSize: 50,
                            letterSpacing: 1.5,
                            decoration: TextDecoration.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Spacer(),
                      NesContainer(
                        padding: const EdgeInsets.all(8),
                        backgroundColor: Colors.transparent,
                        child: Column(
                          children: [
                            NesButton(
                              type: NesButtonType.success,
                              onPressed: onStartGame,
                              buttonWidth: double.infinity,
                              child: const Text(
                                '開始遊戲',
                                style: TextStyle(
                                  fontFamily: 'PressStart2P',
                                  fontFamilyFallback: ['monospace'],
                                  decoration: TextDecoration.none,
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            NesButton(
                              type: NesButtonType.primary,
                              onPressed: () => onContinueGame(context),
                              buttonWidth: double.infinity,
                              child: const Text(
                                '繼續遊戲',
                                style: TextStyle(
                                  fontFamily: 'PressStart2P',
                                  fontFamilyFallback: ['monospace'],
                                  decoration: TextDecoration.none,
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            NesButton(
                              type: NesButtonType.warning,
                              onPressed: () => onOpenSettings(context),
                              buttonWidth: double.infinity,
                              child: const Text(
                                '設定',
                                style: TextStyle(
                                  fontFamily: 'PressStart2P',
                                  fontFamilyFallback: ['monospace'],
                                  decoration: TextDecoration.none,
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            NesButton(
                              type: NesButtonType.error,
                              onPressed: onExitGame,
                              buttonWidth: double.infinity,
                              child: const Text(
                                '離開',
                                style: TextStyle(
                                  fontFamily: 'PressStart2P',
                                  fontFamilyFallback: ['monospace'],
                                  decoration: TextDecoration.none,
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool accent;
  final Color? accentColor;

  const _MenuButton({
    required this.label,
    required this.onPressed, required this.accent, this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = accent ? (accentColor ?? const Color(0xFF4C8DFF)) : Colors.white24;
    return SizedBox(
      width: double.infinity,
        child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: onPressed,
            child: Text(
          label,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white),
        ),
      ),
    );
  }
}
