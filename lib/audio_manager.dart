import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  AudioPlayer? _menuPlayer;
  AudioPlayer? _actionPlayer;
  AudioPlayer? _swordPlayer;
  AudioPlayer? _fireballPlayer;
  double _menuVolume = 0.55;
  bool _menuBgmPlaying = false;
  bool _audioDisabled = false;

  static const Duration _audioOpTimeout = Duration(seconds: 3);

  double get menuVolume => _menuVolume;

  Future<void> init() async {
    if (_audioDisabled) {
      return;
    }

    _menuPlayer ??= AudioPlayer(playerId: 'title_menu_bgm');
    _actionPlayer ??= AudioPlayer(playerId: 'ui_action_sfx');
    _swordPlayer ??= AudioPlayer(playerId: 'sword_hit_sfx');
    _fireballPlayer ??= AudioPlayer(playerId: 'fire_ball_sfx');

    try {
      await _menuPlayer!.setReleaseMode(ReleaseMode.loop).timeout(_audioOpTimeout);
      await _menuPlayer!.setVolume(_menuVolume).timeout(_audioOpTimeout);
      await _actionPlayer!.setReleaseMode(ReleaseMode.stop).timeout(_audioOpTimeout);
      await _swordPlayer!.setReleaseMode(ReleaseMode.stop).timeout(_audioOpTimeout);
      await _fireballPlayer!.setReleaseMode(ReleaseMode.stop).timeout(_audioOpTimeout);
      await _actionPlayer!.setVolume(0.82).timeout(_audioOpTimeout);
      await _swordPlayer!.setVolume(0.95).timeout(_audioOpTimeout);
      await _fireballPlayer!.setVolume(0.92).timeout(_audioOpTimeout);
    } on TimeoutException {
      _disableAudio();
    } catch (_) {
      _disableAudio();
    }
  }

  Future<void> playActionSfx() => _playSfx(_actionPlayer, 'audio/action.mov');

  Future<void> playSwordHitSfx() => _playSfx(_swordPlayer, 'audio/sword_hit.mov');

  Future<void> playFireBallSfx() => _playSfx(_fireballPlayer, 'audio/fire_ball.mov');

  Future<void> _playSfx(AudioPlayer? player, String assetPath) async {
    await init();
    if (_audioDisabled || player == null) {
      return;
    }
    try {
      await player.stop().timeout(_audioOpTimeout);
      await player.play(AssetSource(assetPath)).timeout(_audioOpTimeout);
    } on TimeoutException {
      _disableAudio();
    } catch (_) {
      _disableAudio();
    }
  }

  Future<void> playMenuBgm() async {
    await init();
    if (_audioDisabled || _menuBgmPlaying || _menuPlayer == null) {
      return;
    }

    try {
      await _menuPlayer!.play(AssetSource('bgm/menu.mp3')).timeout(_audioOpTimeout);
      _menuBgmPlaying = true;
    } on TimeoutException {
      _disableAudio();
    } catch (_) {
      _disableAudio();
    }
  }

  Future<void> stopMenuBgm() async {
    if (_audioDisabled || _menuPlayer == null || !_menuBgmPlaying) {
      return;
    }

    try {
      await _menuPlayer!.stop().timeout(_audioOpTimeout);
    } on TimeoutException {
      _disableAudio();
      return;
    } catch (_) {
      _disableAudio();
      return;
    }

    _menuBgmPlaying = false;
  }

  Future<void> setMenuVolume(double value) async {
    _menuVolume = value.clamp(0.0, 1.0);
    if (_audioDisabled || _menuPlayer == null) {
      return;
    }

    try {
      await _menuPlayer!.setVolume(_menuVolume).timeout(_audioOpTimeout);
    } on TimeoutException {
      _disableAudio();
    } catch (_) {
      _disableAudio();
    }
  }

  Future<void> dispose() async {
    _menuBgmPlaying = false;

    try {
      await _menuPlayer?.dispose().timeout(_audioOpTimeout);
      await _actionPlayer?.dispose().timeout(_audioOpTimeout);
      await _swordPlayer?.dispose().timeout(_audioOpTimeout);
      await _fireballPlayer?.dispose().timeout(_audioOpTimeout);
    } catch (_) {}

    _menuPlayer = null;
    _actionPlayer = null;
    _swordPlayer = null;
    _fireballPlayer = null;
  }

  void _disableAudio() {
    _audioDisabled = true;
    _menuBgmPlaying = false;
  }
}
