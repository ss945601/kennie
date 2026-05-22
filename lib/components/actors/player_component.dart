import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../effects/player_afterimage_effect.dart';
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

  static const double _baseMoveSpeed = 120;
  final double attackCooldown = 0.32;
  final double fireballCooldown = 0.72;
  Vector2 movement = Vector2.zero();
  FacingDirection facing = FacingDirection.down;
  Vector2 _aimDirection = Vector2(0, 1);
  late final SpriteAnimationGroupComponent<_PlayerVisualState> _sprite;
  double _attackCooldownRemaining = 0;
  double _fireballCooldownRemaining = 0;
  double _attackWindowRemaining = 0;
  Vector2 _knockbackDirection = Vector2.zero();
  double _knockbackRemaining = 0;
  double _knockbackTotal = 0;
  final double _knockbackMinSpeed = 92;
  final double _knockbackMaxSpeed = 320;
  double _afterimageCooldownRemaining = 0;

  dynamic get _game => findGame();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = SpriteAnimationGroupComponent<_PlayerVisualState>(
      size: size,
      anchor: Anchor.topLeft,
      animations: {
        _PlayerVisualState.idleUp: await _loadAnimation(
          'player/knight_idle.png',
        ),
        _PlayerVisualState.idleDown: await _loadAnimation(
          'player/knight_idle.png',
        ),
        _PlayerVisualState.idleLeft: await _loadAnimation(
          'player/knight_idle_left.png',
        ),
        _PlayerVisualState.idleRight: await _loadAnimation(
          'player/knight_idle.png',
        ),
        _PlayerVisualState.runUp: await _loadAnimation('player/knight_run.png'),
        _PlayerVisualState.runDown: await _loadAnimation(
          'player/knight_run.png',
        ),
        _PlayerVisualState.runLeft: await _loadAnimation(
          'player/knight_run_left.png',
        ),
        _PlayerVisualState.runRight: await _loadAnimation(
          'player/knight_run.png',
        ),
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

  Vector2 get visualCenter =>
      Vector2(position.x + size.x / 2, position.y + size.y / 2);

  Vector2 get aimDirection => _aimDirection.clone();

  void setAimDirection(Vector2 direction) {
    if (direction.length2 == 0) {
      return;
    }
    _aimDirection = direction.normalized();
    facing = _vectorToFacing(_aimDirection);
  }

  Vector2 get facingVector => aimDirection;

  double get moveSpeed =>
      _baseMoveSpeed * _game.controller.playerMoveSpeedMultiplier;

  Vector2 get attackEffectOrigin {
    final center = bodyRect.center;
    const distance = 10.0;
    return Vector2(
      center.dx + facingVector.x * distance,
      center.dy + facingVector.y * distance,
    );
  }

  Vector2 get fireballOrigin {
    final center = bodyRect.center;
    const distance = 18.0;
    return Vector2(
      center.dx + facingVector.x * distance,
      center.dy + facingVector.y * distance,
    );
  }

  Rect get interactionProbe {
    const forwardDistance = 18.0;
    final center = bodyRect.center;
    final probeCenter = Offset(
      center.dx + facingVector.x * forwardDistance,
      center.dy + facingVector.y * forwardDistance,
    );
    return Rect.fromCenter(center: probeCenter, width: 28, height: 28);
  }

  Rect get attackHitbox {
    const forwardDistance = 24.0;
    final center = bodyRect.center;
    final hitCenter = Offset(
      center.dx + facingVector.x * forwardDistance,
      center.dy + facingVector.y * forwardDistance,
    );
    return Rect.fromCenter(center: hitCenter, width: 34, height: 34);
  }

  bool get isAttackActive => _attackWindowRemaining > 0;

  bool tryAttack() {
    if (_attackCooldownRemaining > 0 ||
        _fireballCooldownRemaining > 0 ||
        _game.controller.isFieldInputLocked) {
      return false;
    }
    movement = Vector2.zero();
    _attackCooldownRemaining = attackCooldown;
    _attackWindowRemaining = 0.12;
    return true;
  }

  bool tryCastFireball() {
    if (_attackCooldownRemaining > 0 ||
        _fireballCooldownRemaining > 0 ||
        _game.controller.isFieldInputLocked) {
      return false;
    }
    movement = Vector2.zero();
    _fireballCooldownRemaining = fireballCooldown;
    return true;
  }

  void updateMovementFromKeys(
    Set<LogicalKeyboardKey> keysPressed, {
    required bool inputLocked,
  }) {
    final horizontal =
        (keysPressed.contains(LogicalKeyboardKey.arrowRight) ? 1 : 0) -
        (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ? 1 : 0);
    final vertical =
        (keysPressed.contains(LogicalKeyboardKey.arrowDown) ? 1 : 0) -
        (keysPressed.contains(LogicalKeyboardKey.arrowUp) ? 1 : 0);

    updateMovementFromVector(
      Vector2(horizontal.toDouble(), vertical.toDouble()),
      inputLocked: inputLocked,
    );
  }

  void updateMovementFromVector(
    Vector2 nextMovement, {
    required bool inputLocked,
  }) {
    if (inputLocked) {
      movement = Vector2.zero();
      return;
    }

    movement = nextMovement.clone();
    if (movement.x != 0 && movement.y != 0) {
      movement.normalize();
    }

    if (movement != Vector2.zero()) {
      _aimDirection = movement.normalized();
      facing = _vectorToFacing(_aimDirection);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_attackCooldownRemaining > 0) {
      _attackCooldownRemaining = (_attackCooldownRemaining - dt).clamp(
        0,
        attackCooldown,
      );
    }
    if (_fireballCooldownRemaining > 0) {
      _fireballCooldownRemaining = (_fireballCooldownRemaining - dt).clamp(
        0,
        fireballCooldown,
      );
    }
    if (_attackWindowRemaining > 0) {
      _attackWindowRemaining = (_attackWindowRemaining - dt).clamp(0, 0.12);
    }
    if (_afterimageCooldownRemaining > 0) {
      _afterimageCooldownRemaining = (_afterimageCooldownRemaining - dt).clamp(
        0,
        1,
      );
    }

    if (_knockbackRemaining > 0 && _knockbackDirection.length2 > 0) {
      final progress = (_knockbackTotal <= 0)
          ? 0.0
          : (_knockbackRemaining / _knockbackTotal).clamp(0.0, 1.0);
      final eased = progress * progress;
      final speed =
          _knockbackMinSpeed +
          (_knockbackMaxSpeed - _knockbackMinSpeed) * eased;
      final step = math.min(speed * dt, _knockbackRemaining);
      final delta = _knockbackDirection * step;
      final nextRect = bodyRect.shift(Offset(delta.x, delta.y));
      if (_game.worldMapManager.canPlayerMoveTo(nextRect)) {
        position += delta;
        _knockbackRemaining -= step;
      } else {
        _knockbackRemaining = 0;
      }
      if (_knockbackRemaining <= 0.001) {
        _knockbackRemaining = 0;
        _knockbackTotal = 0;
      }
      _game.controller.setPlayerPosition(position.x, position.y);
    }

    _syncAnimation();
    if (_game.controller.isFieldInputLocked || movement == Vector2.zero()) {
      _syncPriority();
      return;
    }

    final delta = movement.normalized() * moveSpeed * dt;
    final nextRect = bodyRect.shift(Offset(delta.x, delta.y));
    if (_game.worldMapManager.canPlayerMoveTo(nextRect)) {
      final previousPosition = position.clone();
      position += delta;
      _game.controller.setPlayerPosition(position.x, position.y);
      _maybeSpawnAfterimage(previousPosition);
    }
    _syncPriority();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final stats = _game.controller.effectiveStats;
    final hpFraction =
        stats.maxHp <= 0 ? 0.0 : (stats.hp / stats.maxHp).clamp(0.0, 1.0);
    final mpFraction =
        stats.maxMp <= 0 ? 0.0 : (stats.mp / stats.maxMp).clamp(0.0, 1.0);

    final barWidth = size.x - 6;
    const barHeight = 3.0;
    const barX = 3.0;
    const hpBarY = -10.0;
    const mpBarY = -5.0;

    canvas.drawRect(
      Rect.fromLTWH(barX, hpBarY, barWidth, barHeight),
      Paint()..color = const Color(0xAA000000),
    );
    canvas.drawRect(
      Rect.fromLTWH(barX, mpBarY, barWidth, barHeight),
      Paint()..color = const Color(0xAA000000),
    );

    if (hpFraction > 0) {
      canvas.drawRect(
        Rect.fromLTWH(barX, hpBarY, barWidth * hpFraction, barHeight),
        Paint()..color = const Color(0xFFE25B5B),
      );
    }
    if (mpFraction > 0) {
      canvas.drawRect(
        Rect.fromLTWH(barX, mpBarY, barWidth * mpFraction, barHeight),
        Paint()..color = const Color(0xFF4E8FF0),
      );
    }
  }

  void snapTo(Vector2 targetPosition) {
    position = targetPosition;
    _game.controller.setPlayerPosition(position.x, position.y);
    _syncPriority();
  }

  void applyKnockback(Vector2 direction, {double distance = 12}) {
    if (distance <= 0 || direction.length2 == 0) {
      return;
    }
    _knockbackDirection = direction.normalized();
    _knockbackRemaining = (_knockbackRemaining + distance).clamp(0, 52);
    _knockbackTotal = math.max(_knockbackTotal, _knockbackRemaining);
  }

  void _syncAnimation() {
    if (!_sprite.isMounted) {
      return;
    }
    final running =
        movement != Vector2.zero() && !_game.controller.isFieldInputLocked;
    final visualFacing = _visualFacing(_aimDirection);
    _sprite.current = switch ((running, visualFacing)) {
      (false, FacingDirection.up) => _PlayerVisualState.idleUp,
      (false, FacingDirection.down) => _PlayerVisualState.idleDown,
      (false, FacingDirection.left) => _PlayerVisualState.idleLeft,
      (false, FacingDirection.right) => _PlayerVisualState.idleRight,
      (true, FacingDirection.up) => _PlayerVisualState.runUp,
      (true, FacingDirection.down) => _PlayerVisualState.runDown,
      (true, FacingDirection.left) => _PlayerVisualState.runLeft,
      (true, FacingDirection.right) => _PlayerVisualState.runRight,
      (_, FacingDirection.upRight) => _PlayerVisualState.idleUp,
      (_, FacingDirection.downRight) => _PlayerVisualState.idleRight,
      (_, FacingDirection.downLeft) => _PlayerVisualState.idleLeft,
      (_, FacingDirection.upLeft) => _PlayerVisualState.idleUp,
    };
  }

  FacingDirection _vectorToFacing(Vector2 direction) {
    final angle = direction.screenAngle();
    final normalized = (angle + 6.283185307179586) % 6.283185307179586;
    final octant =
        ((normalized + 0.39269908169872414) / 0.7853981633974483).floor() % 8;
    return switch (octant) {
      0 => FacingDirection.right,
      1 => FacingDirection.downRight,
      2 => FacingDirection.down,
      3 => FacingDirection.downLeft,
      4 => FacingDirection.left,
      5 => FacingDirection.upLeft,
      6 => FacingDirection.up,
      _ => FacingDirection.upRight,
    };
  }

  FacingDirection _visualFacing(Vector2 direction) {
    if (direction.x.abs() >= direction.y.abs()) {
      return direction.x >= 0 ? FacingDirection.right : FacingDirection.left;
    }
    return direction.y >= 0 ? FacingDirection.down : FacingDirection.up;
  }

  void _syncPriority() {
    priority = (bodyRect.bottom).round();
  }

  void _maybeSpawnAfterimage(Vector2 previousPosition) {
    if (!_game.controller.hasPhantomCloakEquipped ||
        _afterimageCooldownRemaining > 0 ||
        parent == null) {
      return;
    }
    _afterimageCooldownRemaining = 0.08;
    parent!.add(
      PlayerAfterimageEffect(
        assetPath: _currentAfterimageAssetPath,
        position: previousPosition,
        size: size.clone(),
      ),
    );
  }

  String get _currentAfterimageAssetPath {
    final running =
        movement != Vector2.zero() && !_game.controller.isFieldInputLocked;
    final visualFacing = _visualFacing(_aimDirection);
    if (running) {
      return switch (visualFacing) {
        FacingDirection.left => 'player/knight_run_left.png',
        FacingDirection.right ||
        FacingDirection.down ||
        FacingDirection.up ||
        FacingDirection.upRight ||
        FacingDirection.downRight ||
        FacingDirection.downLeft ||
        FacingDirection.upLeft => 'player/knight_run.png',
      };
    }
    return switch (visualFacing) {
      FacingDirection.left => 'player/knight_idle_left.png',
      FacingDirection.right ||
      FacingDirection.down ||
      FacingDirection.up ||
      FacingDirection.upRight ||
      FacingDirection.downRight ||
      FacingDirection.downLeft ||
      FacingDirection.upLeft => 'player/knight_idle.png',
    };
  }
}
