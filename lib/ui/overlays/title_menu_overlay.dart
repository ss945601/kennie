import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

import '../../game/overlay_ids.dart';
import '../../game/rpg_game.dart';

class TitleMenuOverlay extends StatelessWidget {
  const TitleMenuOverlay({
    super.key,
    required this.game,
  });

  final RpgGame game;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: flutterNesTheme(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/menu_bg.jpg', fit: BoxFit.cover),
          Container(
            color: const Color.fromRGBO(0, 0, 0, 0.3),
            height: MediaQuery.of(context).size.height,
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
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const SizedBox(height: 48),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final titleScale = (constraints.maxWidth / 500).clamp(0.8, 2.0);
                              return AutoSizeText.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Kennie',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: const Color.fromARGB(255, 224, 229, 238),
                                            fontSize: 46 * titleScale,
                                            letterSpacing: 1.5,
                                            decoration: TextDecoration.none,
                                          ),
                                    ),
                                    TextSpan(
                                      text: 'の大冒險',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: const Color.fromARGB(255, 224, 229, 238),
                                            fontSize: 28 * titleScale,
                                            letterSpacing: 1.5,
                                            decoration: TextDecoration.none,
                                          ),
                                    ),
                                  ],
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                        NesContainer(
                          padding: const EdgeInsets.all(8),
                          width: 300,
                          backgroundColor: Colors.transparent,
                          child: Column(
                            children: [
                              NesButton(
                                type: NesButtonType.success,
                                onPressed: game.startNewGame,
                                buttonWidth: double.infinity,
                                child: AutoSizeText(
                                  '開始遊戲',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                                onPressed: () async {
                                  final loaded = await game.continueGame();
                                  if (!context.mounted || loaded) {
                                    return;
                                  }
                                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                    const SnackBar(content: Text('目前沒有可繼續的進度。')),
                                  );
                                },
                                buttonWidth: double.infinity,
                                child: AutoSizeText(
                                  '繼續遊戲',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                                onPressed: () {
                                  game.overlays.add(OverlayIds.titleSettings);
                                },
                                buttonWidth: double.infinity,
                                child: AutoSizeText(
                                  '設定',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                                onPressed: game.exitGame,
                                buttonWidth: double.infinity,
                                child: AutoSizeText(
                                  '離開',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
      ),
    );
  }
}
