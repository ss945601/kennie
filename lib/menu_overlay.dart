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
        Image.asset('assets/images/menu_bg.jpg', fit: BoxFit.cover),
        Container(
          color: const Color.fromRGBO(0, 0, 0, 0.65),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Spacer(),
                      Expanded(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Kennie',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: const Color.fromARGB(255, 231, 234, 180),
                                      fontSize: 40,
                                      letterSpacing: 1.5,
                                      decoration: TextDecoration.none,
                                    ),
                              ),
                              TextSpan(
                                text: 'の大冒險',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 28,
                                      letterSpacing: 1.5,
                                      decoration: TextDecoration.none,
                                    ),
                              ),
                            ],
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 32,
                                  letterSpacing: 1.5,
                                  decoration: TextDecoration.none,
                                ),
                          ),
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
                              child: Text(
                                '開始遊戲',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      decoration: TextDecoration.none,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            NesButton(
                              type: NesButtonType.primary,
                              onPressed: () => onContinueGame(context),
                              buttonWidth: double.infinity,
                              child: Text(
                                '繼續遊戲',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      decoration: TextDecoration.none,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            NesButton(
                              type: NesButtonType.warning,
                              onPressed: () => onOpenSettings(context),
                              buttonWidth: double.infinity,
                              child: Text(
                                '設定',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      decoration: TextDecoration.none,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            NesButton(
                              type: NesButtonType.error,
                              onPressed: onExitGame,
                              buttonWidth: double.infinity,
                              child: Text(
                                '離開',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      decoration: TextDecoration.none,
                                      color: Colors.white,
                                      fontSize: 16,
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

// removed unused _MenuButton in favor of `NesButton` components
