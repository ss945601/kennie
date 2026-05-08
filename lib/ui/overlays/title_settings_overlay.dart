import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

import '../../audio_manager.dart';
import '../../game/overlay_ids.dart';
import '../../game/rpg_game.dart';
import '../responsive_overlay.dart';

class TitleSettingsOverlay extends StatefulWidget {
  const TitleSettingsOverlay({
    super.key,
    required this.game,
  });

  final RpgGame game;

  @override
  State<TitleSettingsOverlay> createState() => _TitleSettingsOverlayState();
}

class _TitleSettingsOverlayState extends State<TitleSettingsOverlay> {
  double _volume = AudioManager.instance.menuVolume;

  @override
  Widget build(BuildContext context) {
    final ui = OverlayUiConfig.of(context);
    return Theme(
      data: flutterNesTheme(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black54),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ui.value(420, compactValue: 300)),
              child: NesContainer(
                padding: ui.all(12, compactValue: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AutoSizeText(
                      '設定',
                      maxLines: 1,
                      minFontSize: 10,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.black,
                            decoration: TextDecoration.none,
                            fontSize: ui.font(16, compactValue: 12),
                          ),
                    ),
                    SizedBox(height: ui.value(12, compactValue: 8)),
                    Row(
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            'BGM 音量',
                            maxLines: 1,
                            minFontSize: 10,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.black,
                                  decoration: TextDecoration.none,
                                  fontSize: ui.font(16, compactValue: 11),
                                ),
                          ),
                        ),
                        SizedBox(
                          width: ui.value(200, compactValue: 132),
                          child: Material(
                            type: MaterialType.transparency,
                            child: Slider(
                              value: _volume,
                              min: 0,
                              max: 1,
                              onChanged: (value) async {
                                setState(() => _volume = value);
                                await AudioManager.instance.setMenuVolume(value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ui.value(4, compactValue: 3)),
                    Text(
                      '選單 BGM 已接回，這裡可直接調整標題音量。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black87,
                            fontSize: ui.font(12, compactValue: 10),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ui.value(8, compactValue: 6)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        NesButton(
                          type: NesButtonType.primary,
                          buttonWidth: ui.value(120, compactValue: 92),
                          onPressed: () {
                            widget.game.overlays.remove(OverlayIds.titleSettings);
                          },
                          child: AutoSizeText(
                            '關閉',
                            maxLines: 1,
                            minFontSize: 10,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.black,
                                  decoration: TextDecoration.none,
                                  fontSize: ui.font(16, compactValue: 11),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
