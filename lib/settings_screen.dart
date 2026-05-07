import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
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
                  const NesRunningText(text: '設定'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: NesRunningText(text:'BGM 音量')),
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
                      NesButton.text(
                        type: NesButtonType.primary,
                        text: '關閉',
                        onPressed: () {
                          widget.game.overlays.remove('Settings');
                        },
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
