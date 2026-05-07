import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'game.dart';
import 'audio_manager.dart';

class SettingsOverlay extends StatefulWidget {
  final KennieGame game;
  const SettingsOverlay({super.key, required this.game});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  double _volume = AudioManager.instance.volume;

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
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
                            onChanged: (v) async {
                              setState(() => _volume = v);
                              await AudioManager.instance.setVolume(v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      NesButton(
                        type: NesButtonType.primary,
                        buttonWidth: 120,
                        onPressed: () {
                          widget.game.overlays.remove('Settings');
                        },
                        child: AutoSizeText(
                          '關閉',
                          maxLines: 1,
                          minFontSize: 10,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
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
    );
  }
}
