import 'package:bonfire/base/listener_game_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'game/overlay_ids.dart';
import 'game/rpg_game.dart';
import 'state/game_state_controller.dart';
import 'state/services/save_repository.dart';
import 'ui/overlays/battle_overlay.dart';
import 'ui/overlays/chest_reward_overlay.dart';
import 'ui/overlays/dialog_overlay.dart';
import 'ui/overlays/ending_overlay.dart';
import 'ui/overlays/hud_overlay.dart';
import 'ui/overlays/opening_overlay.dart';
import 'ui/overlays/pause_menu_overlay.dart';
import 'ui/overlays/scene_fade_overlay.dart';
import 'ui/overlays/title_menu_overlay.dart';
import 'ui/overlays/title_settings_overlay.dart';

class KennieApp extends StatefulWidget {
  const KennieApp({super.key});

  @override
  State<KennieApp> createState() => _KennieAppState();
}

class _KennieAppState extends State<KennieApp> {
  late final GameStateController _controller;
  RpgGame? _game;

  @override
  void initState() {
    super.initState();
    _controller = GameStateController(saveRepository: SaveRepository());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game ??= RpgGame(
      context: context,
      controller: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fontFallback = <String>[
      'PingFang SC',
      'PingFang TC',
      'Hiragino Sans GB',
      'Noto Sans CJK SC',
      'Noto Sans CJK TC',
      'Heiti SC',
      'Arial Unicode MS',
    ];

    final theme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF070B14),
      textTheme: ThemeData.dark().textTheme.apply(
            fontFamilyFallback: fontFallback,
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
      primaryTextTheme: ThemeData.dark().primaryTextTheme.apply(
            fontFamilyFallback: fontFallback,
          ),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6D8F3B), brightness: Brightness.dark),
      useMaterial3: true,
    );

    return ChangeNotifierProvider.value(
      value: _controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(
          body: ListenerGameWidget<RpgGame>(
            game: _game!,
            overlayBuilderMap: {
              OverlayIds.titleMenu: (context, game) => TitleMenuOverlay(game: game),
              OverlayIds.opening: (context, game) => OpeningOverlay(game: game),
              OverlayIds.ending: (context, game) => EndingOverlay(game: game),
              OverlayIds.titleSettings: (context, game) => TitleSettingsOverlay(game: game),
              OverlayIds.hud: (context, game) => HudOverlay(game: game),
              OverlayIds.dialog: (context, game) => const DialogOverlay(),
              OverlayIds.chestReward: (context, game) => const ChestRewardOverlay(),
              OverlayIds.pauseMenu: (context, game) => PauseMenuOverlay(game: game),
              OverlayIds.battle: (context, game) => const BattleOverlay(),
              OverlayIds.fade: (context, game) => const SceneFadeOverlay(),
            },
            initialActiveOverlays: const [OverlayIds.fade, OverlayIds.titleMenu],
          ),
        ),
      ),
    );
  }
}
