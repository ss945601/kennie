import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
          color: const Color.fromRGBO(0, 0, 0, 0.3),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Spacer(),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final titleScale = (constraints.maxWidth / 500)
                                .clamp(0.8, 2.0);
                            return AutoSizeText.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Kennie',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: const Color.fromARGB(255, 224, 229, 238),
                                          fontSize: 46 * titleScale,
                                          letterSpacing: 1.5,
                                          decoration: TextDecoration.none,
                                        ),
                                  ),
                                  TextSpan(
                                    text: 'の大冒險',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: const Color.fromARGB(255, 224, 229, 238),
                                          fontSize: 28 * titleScale,
                                          letterSpacing: 1.5,
                                          decoration: TextDecoration.none,
                                        ),
                                  ),
                                ],
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 32 * titleScale,
                                      letterSpacing: 1.5,
                                      decoration: TextDecoration.none,
                                    ),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              minFontSize: 12,
                              stepGranularity: 1,
                            );
                          },
                        ),
                      ),
                      Spacer(),
                      NesContainer(
                        padding: const EdgeInsets.all(8),
                        width: 300,
                        backgroundColor: Colors.transparent,
                        child: Column(
                          children: [
                            NesButton(
                              type: NesButtonType.success,
                              onPressed: onStartGame,
                              buttonWidth: double.infinity,
                              child: AutoSizeText(
                                '開始遊戲',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      decoration: TextDecoration.none,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                maxLines: 1,
                                minFontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            NesButton(
                              type: NesButtonType.primary,
                              onPressed: () => onContinueGame(context),
                              buttonWidth: double.infinity,
                              child: AutoSizeText(
                                '繼續遊戲',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      decoration: TextDecoration.none,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                maxLines: 1,
                                minFontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            NesButton(
                              type: NesButtonType.warning,
                              onPressed: () => onOpenSettings(context),
                              buttonWidth: double.infinity,
                              child: AutoSizeText(
                                '設定',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      decoration: TextDecoration.none,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                maxLines: 1,
                                minFontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            NesButton(
                              type: NesButtonType.error,
                              onPressed: onExitGame,
                              buttonWidth: double.infinity,
                              child: AutoSizeText(
                                '離開',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      decoration: TextDecoration.none,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                maxLines: 1,
                                minFontSize: 10,
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
