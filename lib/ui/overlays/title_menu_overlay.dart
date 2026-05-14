import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

import '../../audio_manager.dart';
import '../../game/overlay_ids.dart';
import '../../game/rpg_game.dart';
import '../../platform/web_display_helper.dart';
import '../responsive_overlay.dart';

class TitleMenuOverlay extends StatelessWidget {
  const TitleMenuOverlay({
    super.key,
    required this.game,
  });

  final RpgGame game;

  @override
  Widget build(BuildContext context) {
    final ui = OverlayUiConfig.of(context);
    final size = ui.size;
    final buttonFontSize = ui.font(14, compactValue: 10.5);
    return Theme(
      data: flutterNesTheme(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/menu_bg.jpg', fit: BoxFit.cover),
          Container(
            color: const Color.fromRGBO(0, 0, 0, 0.3),
            height: size.height,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: ui.symmetric(
                  vertical: 24,
                  horizontal: 16,
                  compactVertical: 12,
                  compactHorizontal: 12,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: size.width,
                      maxHeight: size.height * 0.8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: ui.value(36, compactValue: 8)),
                        Expanded(
                          flex: 3,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final titleScale = (constraints.maxWidth / (ui.compact ? 520 : 680)).clamp(0.52, 1.4);
                              return AutoSizeText.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Kennie',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: const Color.fromARGB(255, 224, 229, 238),
                                          fontSize: 38 * titleScale,
                                          letterSpacing: ui.compact ? 0.5 : 1.2,
                                            decoration: TextDecoration.none,
                                          ),
                                    ),
                                    TextSpan(
                                      text: 'の大冒險',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: const Color.fromARGB(255, 224, 229, 238),
                                          fontSize: 22 * titleScale,
                                          letterSpacing: ui.compact ? 0.4 : 1,
                                            decoration: TextDecoration.none,
                                          ),
                                    ),
                                  ],
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.white,
                                        fontSize: 24 * titleScale,
                                        letterSpacing: ui.compact ? 0.4 : 1,
                                        decoration: TextDecoration.none,
                                      ),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                minFontSize: 10,
                                stepGranularity: 1,
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: 90,
                          child: NesContainer(
                            padding: ui.all(8, compactValue: 5),
                            width: ui.compact ? size.width * 0.92 : 700,
                            height: MediaQuery.of(context).size.height * 0.6  ,
                            backgroundColor: Colors.transparent,
                            child: Row(
                              children: [
                                Expanded(
                                  child: NesButton(
                                    type: NesButtonType.success,
                                    onPressed: () async {
                                      unawaited(AudioManager.instance.playActionSfx());
                                      await enterLandscapeFullscreen();
                                      game.startNewGame();
                                    },
                                    buttonWidth: double.infinity,
                                    child: AutoSizeText(
                                      '開始遊戲',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            decoration: TextDecoration.none,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: buttonFontSize,
                                          ),
                                      maxLines: 1,
                                      minFontSize: 20,
                                    ),
                                  ),
                                ),
                                SizedBox(width: ui.value(8, compactValue: 4)),
                                Expanded(
                                  child: NesButton(
                                    type: NesButtonType.primary,
                                    onPressed: () async {
                                      unawaited(AudioManager.instance.playActionSfx());
                                      await enterLandscapeFullscreen();
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
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: buttonFontSize,
                                          ),
                                      maxLines: 1,
                                      minFontSize: 20,
                                    ),
                                  ),
                                ),
                                SizedBox(width: ui.value(8, compactValue: 4)),
                                Expanded(
                                  child: NesButton(
                                    type: NesButtonType.warning,
                                    onPressed: () {
                                      unawaited(AudioManager.instance.playActionSfx());
                                      game.overlays.add(OverlayIds.titleSettings);
                                    },
                                    buttonWidth: double.infinity,
                                    child: AutoSizeText(
                                      '設定',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            decoration: TextDecoration.none,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: buttonFontSize,
                                          ),
                                      maxLines: 1,
                                      minFontSize: 20,
                                    ),
                                  ),
                                ),
                                SizedBox(width: ui.value(8, compactValue: 4)),
                                Expanded(
                                  child: NesButton(
                                    type: NesButtonType.error,
                                    onPressed: () {
                                      unawaited(AudioManager.instance.playActionSfx());
                                      game.exitGame();
                                    },
                                    buttonWidth: double.infinity,
                                    child: AutoSizeText(
                                      '離開',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            decoration: TextDecoration.none,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: buttonFontSize,
                                          ),
                                      maxLines: 1,
                                      minFontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
