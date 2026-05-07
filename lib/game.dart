import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        const SnackBar(content: Text('載入已保存遊戲...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目前沒有可繼續的進度。')),
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
