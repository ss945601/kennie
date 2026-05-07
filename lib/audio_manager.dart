import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  AudioPlayer? _bgmPlayer;
  double _volume = 0.55;

  AudioManager._();
  static final AudioManager instance = AudioManager._();

  Future<void> init() async {
    _bgmPlayer ??= AudioPlayer();
    await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer!.setVolume(_volume);
  }

  Future<void> playMenuBgm() async {
    await init();
    try {
      await _bgmPlayer!.play(AssetSource('bgm/menu.mp3'));
      await _bgmPlayer!.setVolume(_volume);
    } catch (_) {
      // best-effort: don't crash the app if audio fails
    }
  }

  Future<void> stopMenuBgm() async {
    if (_bgmPlayer == null) return;
    try {
      await _bgmPlayer!.stop();
    } catch (_) {}
  }

  double get volume => _volume;

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    if (_bgmPlayer != null) {
      await _bgmPlayer!.setVolume(_volume);
    }
  }

  Future<void> dispose() async {
    try {
      await _bgmPlayer?.dispose();
    } catch (_) {}
    _bgmPlayer = null;
  }
}
