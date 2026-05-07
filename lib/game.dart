import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KennieGame extends FlameGame {
  final AudioPlayer _menuBgmPlayer = AudioPlayer();
  bool _isMenuBgmPlaying = false;
  bool hasSavedGame = false;

  @override
  Color backgroundColor() => const Color(0xFF0B1330);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await playMenuBgm();
  }

  Future<void> playMenuBgm() async {
    if (_isMenuBgmPlaying) {
      return;
    }
    _isMenuBgmPlaying = true;
    await _menuBgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _menuBgmPlayer.play(AssetSource('bgm/menu.mp3'), volume: 0.55);
  }

  Future<void> stopMenuBgm() async {
    if (!_isMenuBgmPlaying) {
      return;
    }
    _isMenuBgmPlaying = false;
    await _menuBgmPlayer.stop();
  }

  void startGame() {
    hasSavedGame = true;
    overlays.remove('MainMenu');
    stopMenuBgm();
  }

  void continueGame(BuildContext context) {
    if (hasSavedGame) {
      overlays.remove('MainMenu');
      stopMenuBgm();
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('設定'),
          content: const Text('遊戲音量、畫面與操作設定將在此顯示。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('關閉'),
            ),
          ],
        );
      },
    );
  }

  void exitGame() {
    SystemNavigator.pop();
  }
}
