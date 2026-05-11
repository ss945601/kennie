import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:just_audio/just_audio.dart' as ja;

class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  ap.AudioPlayer? _menuPlayer;
  ap.AudioPlayer? _fieldBgmPlayer;
  _SfxBank? _actionBank;
  _SfxBank? _swordBank;
  _SfxBank? _fireballBank;
  double _menuVolume = 0.55;
  bool _menuBgmPlaying = false;
  _FieldBgmTrack? _activeFieldTrack;

  static const Duration _audioOpTimeout = Duration(seconds: 3);

  double get menuVolume => _menuVolume;

  Future<void> init() async {
    _menuPlayer ??= ap.AudioPlayer(playerId: 'title_menu_bgm');
    _fieldBgmPlayer ??= ap.AudioPlayer(playerId: 'field_bgm');

    _actionBank ??= await _createSfxBank(
      assetPath: 'assets/audio/action.wav',
      voices: 6,
      volume: 0.82,
    );
    _swordBank ??= await _createSfxBank(
      assetPath: 'assets/audio/sword_hit.wav',
      voices: 5,
      volume: 0.95,
    );
    _fireballBank ??= await _createSfxBank(
      assetPath: 'assets/audio/fire_ball.wav',
      voices: 5,
      volume: 0.92,
    );

    await _safeAudioOp(() async {
      await _menuPlayer!.setReleaseMode(ap.ReleaseMode.loop).timeout(_audioOpTimeout);
      await _menuPlayer!.setVolume(_menuVolume).timeout(_audioOpTimeout);
    });
    await _safeAudioOp(() async {
      await _fieldBgmPlayer!.setReleaseMode(ap.ReleaseMode.loop).timeout(_audioOpTimeout);
      await _fieldBgmPlayer!.setVolume(0.52).timeout(_audioOpTimeout);
    });
  }

  Future<_SfxBank?> _createSfxBank({
    required String assetPath,
    required int voices,
    required double volume,
  }) async {
    final players = <ja.AudioPlayer>[];
    try {
      for (var i = 0; i < voices; i += 1) {
        final player = ja.AudioPlayer(handleAudioSessionActivation: false);
        await player.setLoopMode(ja.LoopMode.off).timeout(_audioOpTimeout);
        await player.setVolume(volume).timeout(_audioOpTimeout);
        await player.setAsset(assetPath).timeout(_audioOpTimeout);
        players.add(player);
      }
      return _SfxBank(players);
    } catch (_) {
      for (final player in players) {
        try {
          await player.dispose().timeout(_audioOpTimeout);
        } catch (_) {}
      }
      return null;
    }
  }

  Future<void> _safeAudioOp(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      // Do not block other players if one operation fails.
    }
  }

  Future<void> playActionSfx() => _playSfx(_actionBank, 'assets/audio/action.wav', 0.82);

  Future<void> playSwordHitSfx() => _playSfx(_swordBank, 'assets/audio/sword_hit.wav', 0.95);

  Future<void> playFireBallSfx() => _playSfx(_fireballBank, 'assets/audio/fire_ball.wav', 0.92);

  Future<void> _playSfx(_SfxBank? bank, String assetPath, double volume) async {
    await init();
    if (bank != null) {
      try {
        final player = bank.takeNextPlayer();
        await player.seek(Duration.zero).timeout(_audioOpTimeout);
        await player.play().timeout(_audioOpTimeout);
        return;
      } catch (_) {
        // Fall through to one-shot fallback player.
      }
    }
    await _playSfxWithFallbackPlayer(assetPath, volume);
  }

  Future<void> _playSfxWithFallbackPlayer(String assetPath, double volume) async {
    final fallback = ja.AudioPlayer(handleAudioSessionActivation: false);
    try {
      await fallback.setVolume(volume).timeout(_audioOpTimeout);
      await fallback.setLoopMode(ja.LoopMode.off).timeout(_audioOpTimeout);
      await fallback.setAsset(assetPath).timeout(_audioOpTimeout);
      await fallback.play().timeout(_audioOpTimeout);
      unawaited(
        Future<void>.delayed(const Duration(seconds: 2), () async {
          try {
            await fallback.dispose().timeout(_audioOpTimeout);
          } catch (_) {}
        }),
      );
    } catch (_) {
      try {
        await fallback.dispose().timeout(_audioOpTimeout);
      } catch (_) {}
    }
  }

  Future<void> playMenuBgm() async {
    await init();
    if (_menuBgmPlaying || _menuPlayer == null) {
      return;
    }

    try {
      await _menuPlayer!.play(ap.AssetSource('bgm/menu.mp3')).timeout(_audioOpTimeout);
      _menuBgmPlaying = true;
    } catch (_) {
      _menuBgmPlaying = false;
    }
  }

  Future<void> playGameBgm() => _playFieldBgm(_FieldBgmTrack.game);

  Future<void> playBossBgm() => _playFieldBgm(_FieldBgmTrack.boss);

  Future<void> _playFieldBgm(_FieldBgmTrack track) async {
    await init();
    if (_fieldBgmPlayer == null) {
      return;
    }
    if (_activeFieldTrack == track) {
      return;
    }
    final source = switch (track) {
      _FieldBgmTrack.game => 'bgm/game_bgm.mp3',
      _FieldBgmTrack.boss => 'bgm/fight_boss.mp3',
    };
    try {
      await _fieldBgmPlayer!.play(ap.AssetSource(source)).timeout(_audioOpTimeout);
      _activeFieldTrack = track;
    } catch (_) {
      _activeFieldTrack = null;
    }
  }

  Future<void> stopFieldBgm() async {
    if (_fieldBgmPlayer == null || _activeFieldTrack == null) {
      return;
    }
    try {
      await _fieldBgmPlayer!.stop().timeout(_audioOpTimeout);
      _activeFieldTrack = null;
    } catch (_) {
      _activeFieldTrack = null;
    }
  }

  Future<void> stopMenuBgm() async {
    if (_menuPlayer == null || !_menuBgmPlaying) {
      return;
    }

    try {
      await _menuPlayer!.stop().timeout(_audioOpTimeout);
    } catch (_) {
      _menuBgmPlaying = false;
      return;
    }

    _menuBgmPlaying = false;
  }

  Future<void> setMenuVolume(double value) async {
    _menuVolume = value.clamp(0.0, 1.0);
    if (_menuPlayer == null) {
      return;
    }

    try {
      await _menuPlayer!.setVolume(_menuVolume).timeout(_audioOpTimeout);
    } catch (_) {
      // Ignore and keep previous volume.
    }
  }

  Future<void> dispose() async {
    _menuBgmPlaying = false;
    _activeFieldTrack = null;

    try {
      await _menuPlayer?.dispose().timeout(_audioOpTimeout);
      await _fieldBgmPlayer?.dispose().timeout(_audioOpTimeout);
      await _actionBank?.dispose().timeout(_audioOpTimeout);
      await _swordBank?.dispose().timeout(_audioOpTimeout);
      await _fireballBank?.dispose().timeout(_audioOpTimeout);
    } catch (_) {}

    _menuPlayer = null;
    _fieldBgmPlayer = null;
    _actionBank = null;
    _swordBank = null;
    _fireballBank = null;
  }

}

enum _FieldBgmTrack { game, boss }

class _SfxBank {
  _SfxBank(this.players);

  final List<ja.AudioPlayer> players;
  int _cursor = 0;

  ja.AudioPlayer takeNextPlayer() {
    if (players.isEmpty) {
      throw StateError('No SFX players available');
    }
    final player = players[_cursor];
    _cursor = (_cursor + 1) % players.length;
    return player;
  }

  Future<void> dispose() async {
    for (final player in players) {
      try {
        await player.dispose();
      } catch (_) {}
    }
  }
}
