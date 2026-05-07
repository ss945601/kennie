import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

import '../../audio_manager.dart';
import '../../game/overlay_ids.dart';
import '../../game/rpg_game.dart';

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
    return Theme(
      data: flutterNesTheme(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black54),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: NesContainer(
                padding: const EdgeInsets.all(12),
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
                          ),
                    ),
                    const SizedBox(height: 12),
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
                                ),
                          ),
                        ),
                        SizedBox(
                          width: 200,
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
                    const SizedBox(height: 4),
                    Text(
                      '選單 BGM 已接回，這裡可直接調整標題音量。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        NesButton(
                          type: NesButtonType.primary,
                          buttonWidth: 120,
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
        ],
      ),
    );
  }
}
