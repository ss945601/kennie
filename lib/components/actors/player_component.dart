import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/models/game_models.dart';

class PlayerComponent extends RectangleComponent {
  PlayerComponent()
      : super(
          size: Vector2(20, 28),
          anchor: Anchor.topLeft,
          paint: Paint()..color = Colors.blueAccent,
        ) {
    _syncPriority();
  }

  final double moveSpeed = 120;
  Vector2 movement = Vector2.zero();
  FacingDirection facing = FacingDirection.down;

  dynamic get _game => findGame();

  static const spriteAnimationPaths = <FacingDirection, String>{
    FacingDirection.up: 'assets/sprites/player_up.png',
    FacingDirection.down: 'assets/sprites/player_down.png',
    FacingDirection.left: 'assets/sprites/player_left.png',
    FacingDirection.right: 'assets/sprites/player_right.png',
  };

  Rect get bodyRect => Rect.fromLTWH(position.x, position.y, size.x, size.y);

  Rect get interactionProbe {
    const distance = 16.0;
    switch (facing) {
      case FacingDirection.up:
        return Rect.fromLTWH(position.x, position.y - distance, size.x, distance + 8);
      case FacingDirection.down:
        return Rect.fromLTWH(position.x, position.y + size.y - 8, size.x, distance + 8);
      case FacingDirection.left:
        return Rect.fromLTWH(position.x - distance, position.y + 4, distance + 8, size.y - 8);
      case FacingDirection.right:
        return Rect.fromLTWH(position.x + size.x - 8, position.y + 4, distance + 8, size.y - 8);
    }
  }

  void updateMovementFromKeys(
    Set<LogicalKeyboardKey> keysPressed, {
    required bool inputLocked,
  }) {
    if (inputLocked) {
      movement = Vector2.zero();
      return;
    }

    final horizontal = (keysPressed.contains(LogicalKeyboardKey.arrowRight) ? 1 : 0) -
        (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ? 1 : 0);
    final vertical = (keysPressed.contains(LogicalKeyboardKey.arrowDown) ? 1 : 0) -
        (keysPressed.contains(LogicalKeyboardKey.arrowUp) ? 1 : 0);

    movement = Vector2(horizontal.toDouble(), vertical.toDouble());
    if (movement.x != 0 && movement.y != 0) {
      movement.normalize();
    }

    if (horizontal < 0) {
      facing = FacingDirection.left;
    } else if (horizontal > 0) {
      facing = FacingDirection.right;
    } else if (vertical < 0) {
      facing = FacingDirection.up;
    } else if (vertical > 0) {
      facing = FacingDirection.down;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_game.controller.isFieldInputLocked || movement == Vector2.zero()) {
      _syncPriority();
      return;
    }

    final delta = movement.normalized() * moveSpeed * dt;
    final nextRect = bodyRect.shift(Offset(delta.x, delta.y));
    if (_game.worldMapManager.canMoveTo(nextRect)) {
      position += delta;
      _game.controller.setPlayerPosition(position.x, position.y);
    }
    _syncPriority();
  }

  void snapTo(Vector2 targetPosition) {
    position = targetPosition;
    _game.controller.setPlayerPosition(position.x, position.y);
    _syncPriority();
  }

  void _syncPriority() {
    priority = (position.y + size.y).round();
  }
}
