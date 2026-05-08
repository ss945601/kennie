import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../../state/models/game_models.dart';

enum _PlayerVisualState {
  idleUp,
  idleDown,
  idleLeft,
  idleRight,
  runUp,
  runDown,
  runLeft,
  runRight,
}

class PlayerComponent extends PositionComponent {
  PlayerComponent() : super(size: Vector2.all(48), anchor: Anchor.topLeft);

  final double moveSpeed = 120;
  final double attackCooldown = 0.32;
  Vector2 movement = Vector2.zero();
  FacingDirection facing = FacingDirection.down;
  late final SpriteAnimationGroupComponent<_PlayerVisualState> _sprite;
  double _attackCooldownRemaining = 0;
  double _attackWindowRemaining = 0;

  dynamic get _game => findGame();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = SpriteAnimationGroupComponent<_PlayerVisualState>(
      size: size,
      anchor: Anchor.topLeft,
      animations: {
        _PlayerVisualState.idleUp: await _loadAnimation('player/knight_idle.png'),
        _PlayerVisualState.idleDown: await _loadAnimation('player/knight_idle.png'),
        _PlayerVisualState.idleLeft: await _loadAnimation('player/knight_idle_left.png'),
        _PlayerVisualState.idleRight: await _loadAnimation('player/knight_idle.png'),
        _PlayerVisualState.runUp: await _loadAnimation('player/knight_run.png'),
        _PlayerVisualState.runDown: await _loadAnimation('player/knight_run.png'),
        _PlayerVisualState.runLeft: await _loadAnimation('player/knight_run_left.png'),
        _PlayerVisualState.runRight: await _loadAnimation('player/knight_run.png'),
      },
      current: _PlayerVisualState.idleDown,
    );
    await add(_sprite);
  }

  Future<SpriteAnimation> _loadAnimation(String path) {
    return SpriteAnimation.load(
      path,
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.1,
        textureSize: Vector2.all(16),
      ),
    );
  }

  Rect get bodyRect => Rect.fromLTWH(position.x + 12, position.y + 18, 24, 24);

  Rect get interactionProbe {
    const distance = 16.0;
    final body = bodyRect;
    switch (facing) {
      case FacingDirection.up:
        return Rect.fromLTWH(body.left, body.top - distance, body.width, distance + 8);
      case FacingDirection.down:
        return Rect.fromLTWH(body.left, body.bottom - 8, body.width, distance + 8);
      case FacingDirection.left:
        return Rect.fromLTWH(body.left - distance, body.top + 4, distance + 8, body.height - 8);
      case FacingDirection.right:
        return Rect.fromLTWH(body.right - 8, body.top + 4, distance + 8, body.height - 8);
    }
  }

  Rect get attackHitbox {
    const distance = 28.0;
    final body = bodyRect;
    switch (facing) {
      case FacingDirection.up:
        return Rect.fromLTWH(body.left - 4, body.top - distance, body.width + 8, distance + 4);
      case FacingDirection.down:
        return Rect.fromLTWH(body.left - 4, body.bottom - 4, body.width + 8, distance + 4);
      case FacingDirection.left:
        return Rect.fromLTWH(body.left - distance, body.top - 2, distance + 4, body.height + 4);
      case FacingDirection.right:
        return Rect.fromLTWH(body.right - 4, body.top - 2, distance + 4, body.height + 4);
    }
  }

  bool get isAttackActive => _attackWindowRemaining > 0;

  bool tryAttack() {
    if (_attackCooldownRemaining > 0 || _game.controller.isFieldInputLocked) {
      return false;
    }
    movement = Vector2.zero();
    _attackCooldownRemaining = attackCooldown;
    _attackWindowRemaining = 0.12;
    return true;
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
    if (_attackCooldownRemaining > 0) {
      _attackCooldownRemaining = (_attackCooldownRemaining - dt).clamp(0, attackCooldown);
    }
    if (_attackWindowRemaining > 0) {
      _attackWindowRemaining = (_attackWindowRemaining - dt).clamp(0, 0.12);
    }
    _syncAnimation();
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

  void _syncAnimation() {
    if (!_sprite.isMounted) {
      return;
    }
    final running = movement != Vector2.zero() && !_game.controller.isFieldInputLocked;
    _sprite.current = switch ((running, facing)) {
      (false, FacingDirection.up) => _PlayerVisualState.idleUp,
      (false, FacingDirection.down) => _PlayerVisualState.idleDown,
      (false, FacingDirection.left) => _PlayerVisualState.idleLeft,
      (false, FacingDirection.right) => _PlayerVisualState.idleRight,
      (true, FacingDirection.up) => _PlayerVisualState.runUp,
      (true, FacingDirection.down) => _PlayerVisualState.runDown,
      (true, FacingDirection.left) => _PlayerVisualState.runLeft,
      (true, FacingDirection.right) => _PlayerVisualState.runRight,
    };
  }

  void _syncPriority() {
    priority = (bodyRect.bottom).round();
  }
}
