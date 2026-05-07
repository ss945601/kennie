import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  AudioPlayer? _menuPlayer;
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

    try {
      await _menuPlayer!.setReleaseMode(ReleaseMode.loop).timeout(_audioOpTimeout);
      await _menuPlayer!.setVolume(_menuVolume).timeout(_audioOpTimeout);
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
    } catch (_) {}

    _menuPlayer = null;
  }

  void _disableAudio() {
    _audioDisabled = true;
    _menuBgmPlaying = false;
  }
}
