import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'audio_manager.dart';

class KennieGame extends FlameGame {
  bool hasSavedGame = false;

  @override
  Color backgroundColor() => const Color(0xFF0B1330);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await AudioManager.instance.init();
    await AudioManager.instance.playMenuBgm();
  }

  void startGame() {
    hasSavedGame = true;
    overlays.remove('MainMenu');
    AudioManager.instance.stopMenuBgm();
  }

  void continueGame(BuildContext context) {
    if (hasSavedGame) {
      overlays.remove('MainMenu');
      AudioManager.instance.stopMenuBgm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AutoSizeText(
            '載入已保存遊戲...',
            maxLines: 1,
            minFontSize: 10,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AutoSizeText(
            '目前沒有可繼續的進度。',
            maxLines: 1,
            minFontSize: 10,
          ),
        ),
      );
    }
  }

  void openSettings(BuildContext context) {
    // Use overlays so settings UI is handled in its own file
    overlays.add('Settings');
  }

  void exitGame() {
    SystemNavigator.pop();
  }
}
