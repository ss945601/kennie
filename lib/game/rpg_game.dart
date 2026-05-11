import 'dart:async';

import 'package:bonfire/bonfire.dart';
import 'package:bonfire/base/bonfire_with_collision.dart';
import 'package:bonfire/map/empty_map.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../audio_manager.dart';
import '../components/actors/player_component.dart';
import '../map/world_map_manager.dart';
import '../state/game_state_controller.dart';
import 'overlay_ids.dart';

class RpgGame extends BonfireWithCollision {
  RpgGame({
    required super.context,
    required this.controller,
  }) : super(
          configDefault: BonfireCollisionConfigDefault(),
          map: EmptyWorldMap(size: Vector2.all(1)),
        );

  final GameStateController controller;
  late final PlayerComponent hero;
  late final WorldMapManager worldMapManager;
  bool _isChangingScene = false;
  bool _wasOnTitleMenu = true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    unawaited(AudioManager.instance.init());
    hero = PlayerComponent();
    worldMapManager = WorldMapManager(
      player: hero,
      controller: controller,
      onTeleportTriggered: requestTeleport,
    );
    await world.add(worldMapManager);
    controller.addListener(_syncOverlays);
    camera.viewfinder.zoom = 1.2;
    await controller.initialize();
    _syncOverlays();
  }

  @override
  void onRemove() {
    controller.removeListener(_syncOverlays);
    unawaited(AudioManager.instance.dispose());
    super.onRemove();
  }

  Future<void> startNewGame() async {
    controller.startNewGame();
    await _runTransition(() async {
      await worldMapManager.loadMap(
        controller.currentMapId,
        spawnId: controller.currentSpawnId,
      );
      camera.follow(hero);
    });
  }

  Future<bool> continueGame() async {
    final didLoad = await controller.continueFromSave();
    if (!didLoad) {
      return false;
    }
    await _runTransition(() async {
      await worldMapManager.loadMap(
        controller.currentMapId,
        spawnId: controller.currentSpawnId,
        explicitPlayerPosition: Vector2(controller.playerX, controller.playerY),
      );
      camera.follow(hero);
    });
    return true;
  }

  Future<void> saveGame() => controller.saveGame();

  Future<void> loadGame() async {
    final loaded = await controller.loadGame();
    if (!loaded) {
      return;
    }
    await _runTransition(() async {
      await worldMapManager.loadMap(
        controller.currentMapId,
        spawnId: controller.currentSpawnId,
        explicitPlayerPosition: Vector2(controller.playerX, controller.playerY),
      );
      camera.follow(hero);
    });
  }

  void exitGame() {
    SystemNavigator.pop();
  }

  Future<void> requestTeleport(String mapId, String spawnId) async {
    if (_isChangingScene) {
      return;
    }
    controller.setHudMessage('場景切換中...');
    await _runTransition(() async {
      await worldMapManager.loadMap(mapId, spawnId: spawnId);
      camera.follow(hero);
    });
  }

  Future<void> handleInteraction() => worldMapManager.interactInFrontOfPlayer();

  Future<void> handleAttack() => worldMapManager.playerAttack();

  Future<void> handleFireball({Vector2? direction}) {
    if (direction != null) {
      hero.setAimDirection(direction);
    }
    return worldMapManager.playerCastFireball(direction: direction);
  }

  void updateTouchMovement(Vector2 movement) {
    if (!hero.isMounted) {
      return;
    }
    hero.updateMovementFromVector(
      movement,
      inputLocked: controller.isFieldInputLocked,
    );
  }

  void stopTouchMovement() {
    updateTouchMovement(Vector2.zero());
  }

  void handleQuickPotion() {
    controller.usePotionQuick();
  }

  void handlePauseToggle() {
    controller.togglePauseMenu();
  }

  Future<void> _runTransition(Future<void> Function() action) async {
    _isChangingScene = true;
    controller.setTransitionOpacity(1);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    await action();
    controller.setTransitionOpacity(0);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    _isChangingScene = false;
  }

  void _syncOverlays() {
    if (controller.showTitleMenu) {
      if (!_wasOnTitleMenu) {
        unawaited(AudioManager.instance.stopFieldBgm());
      }
      unawaited(AudioManager.instance.playMenuBgm());
    } else {
      unawaited(AudioManager.instance.stopMenuBgm());
      if (_wasOnTitleMenu) {
        unawaited(AudioManager.instance.playGameBgm());
      }
    }
    _wasOnTitleMenu = controller.showTitleMenu;
    _setOverlay(OverlayIds.fade, true);
    _setOverlay(OverlayIds.titleMenu, controller.showTitleMenu);
    _setOverlay(OverlayIds.hud, !controller.showTitleMenu);
    _setOverlay(OverlayIds.pauseMenu, controller.isPauseMenuOpen);
    _setOverlay(OverlayIds.dialog, controller.activeDialog != null);
    _setOverlay(OverlayIds.chestReward, controller.activeChestRewardDialog != null);
    _setOverlay(OverlayIds.battle, false);
  }

  void _setOverlay(String id, bool visible) {
    if (visible) {
      if (!overlays.isActive(id)) {
        overlays.add(id);
      }
    } else if (overlays.isActive(id)) {
      overlays.remove(id);
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (hero.isMounted) {
      hero.updateMovementFromKeys(
        keysPressed,
        inputLocked: controller.isFieldInputLocked,
      );
    }

    final componentResult = super.onKeyEvent(event, keysPressed);
    final isPressedEvent = event is KeyDownEvent || event is KeyRepeatEvent;
    if (!isPressedEvent) {
      return componentResult;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      controller.togglePauseMenu();
      return KeyEventResult.handled;
    }

    if ((event.logicalKey == LogicalKeyboardKey.keyJ || event.logicalKey == LogicalKeyboardKey.enter) &&
        !controller.isFieldInputLocked) {
      unawaited(handleAttack());
      return KeyEventResult.handled;
    }

    if ((event.logicalKey == LogicalKeyboardKey.keyK || event.logicalKey == LogicalKeyboardKey.digit2) &&
        !controller.isFieldInputLocked) {
      unawaited(handleFireball());
      return KeyEventResult.handled;
    }

    if ((event.logicalKey == LogicalKeyboardKey.keyH || event.logicalKey == LogicalKeyboardKey.digit1) &&
        !controller.isFieldInputLocked) {
      controller.usePotionQuick();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.space && !controller.isFieldInputLocked) {
      unawaited(handleInteraction());
      return KeyEventResult.handled;
    }

    return componentResult;
  }
}
