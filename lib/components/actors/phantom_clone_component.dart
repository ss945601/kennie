import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../state/models/game_models.dart';
import 'player_component.dart';

enum _PhantomVisualState {
  idleUp,
  idleDown,
  idleLeft,
  idleRight,
  runUp,
  runDown,
  runLeft,
  runRight,
}

class PhantomCloneComponent extends PositionComponent {
  PhantomCloneComponent({required this.player})
    : super(size: Vector2.all(44), anchor: Anchor.topLeft, priority: 2395);

  final PlayerComponent player;

  late final SpriteAnimationGroupComponent<_PhantomVisualState> _sprite;
  Vector2 _aimDirection = Vector2(0, 1);
  Vector2 _movementDelta = Vector2.zero();
  Vector2? _combatTarget;
  double _orbitAngle = 0;
  int _maxHp = 1;
  int _currentHp = 1;
  int _attackPower = 1;
  int _defensePower = 0;

  bool get isAlive => _currentHp > 0;
  int get attackPower => _attackPower;
  int get defensePower => _defensePower;

  Rect get bodyRect =>
      Rect.fromLTWH(position.x + 11, position.y + 16, size.x - 22, size.y - 20);

  Vector2 get visualCenter =>
      Vector2(position.x + size.x / 2, position.y + size.y / 2);

  Vector2 get aimDirection => _aimDirection.clone();

  Vector2 get attackOrigin {
    final center = bodyRect.center;
    return Vector2(
      center.dx + _aimDirection.x * 10,
      center.dy + _aimDirection.y * 10,
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = SpriteAnimationGroupComponent<_PhantomVisualState>(
      size: size,
      anchor: Anchor.topLeft,
      animations: {
        _PhantomVisualState.idleUp: await _loadAnimation(
          'player/knight_idle.png',
        ),
        _PhantomVisualState.idleDown: await _loadAnimation(
          'player/knight_idle.png',
        ),
        _PhantomVisualState.idleLeft: await _loadAnimation(
          'player/knight_idle_left.png',
        ),
        _PhantomVisualState.idleRight: await _loadAnimation(
          'player/knight_idle.png',
        ),
        _PhantomVisualState.runUp: await _loadAnimation(
          'player/knight_run.png',
        ),
        _PhantomVisualState.runDown: await _loadAnimation(
          'player/knight_run.png',
        ),
        _PhantomVisualState.runLeft: await _loadAnimation(
          'player/knight_run_left.png',
        ),
        _PhantomVisualState.runRight: await _loadAnimation(
          'player/knight_run.png',
        ),
      },
      current: _PhantomVisualState.idleDown,
      paint: Paint()..color = const Color(0x88DDEBFF),
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

  void syncStats(PlayerStats stats, {bool restoreHp = false}) {
    final nextMaxHp = math.max(1, (stats.maxHp / 2).round());
    final hpRatio = _maxHp <= 0 ? 1.0 : (_currentHp / _maxHp).clamp(0.0, 1.0);
    _maxHp = nextMaxHp;
    _attackPower = math.max(1, (stats.attack / 2).round());
    _defensePower = math.max(0, (stats.defense / 2).round());
    if (restoreHp) {
      _currentHp = _maxHp;
    } else {
      _currentHp = math.max(1, math.min(_maxHp, (_maxHp * hpRatio).round()));
    }
  }

  void setCombatTarget(Vector2? targetPosition) {
    _combatTarget = targetPosition?.clone();
  }

  bool receiveDamage(int damage) {
    if (!isAlive) {
      return false;
    }
    _currentHp = math.max(0, _currentHp - damage);
    return _currentHp == 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _orbitAngle += dt * 1.6;
    final orbitOffset = Vector2(
      math.cos(_orbitAngle) * 34,
      math.sin(_orbitAngle * 1.35) * 16 - 20,
    );
    final desiredTopLeft =
        player.position +
        Vector2(
          player.size.x / 2 - size.x / 2,
          player.size.y / 2 - size.y / 2,
        ) +
        orbitOffset;
    final delta = desiredTopLeft - position;
    if (delta.length2 > 1) {
      final step = math.min(delta.length, 210 * dt);
      _movementDelta = delta.normalized() * step;
      position += _movementDelta;
    } else {
      _movementDelta = Vector2.zero();
    }

    final aimSource =
        _combatTarget ?? (player.visualCenter + player.aimDirection * 14);
    final aimDelta = aimSource - visualCenter;
    if (aimDelta.length2 > 0.001) {
      _aimDirection = aimDelta.normalized();
    }
    _syncAnimation();
    priority = (bodyRect.bottom).round() - 1;
  }

  void _syncAnimation() {
    if (!_sprite.isMounted) {
      return;
    }
    final moving = _movementDelta.length2 > 4;
    final visualFacing = _visualFacing(_aimDirection);
    _sprite.current = switch ((moving, visualFacing)) {
      (false, FacingDirection.up) => _PhantomVisualState.idleUp,
      (false, FacingDirection.down) => _PhantomVisualState.idleDown,
      (false, FacingDirection.left) => _PhantomVisualState.idleLeft,
      (false, FacingDirection.right) => _PhantomVisualState.idleRight,
      (true, FacingDirection.up) => _PhantomVisualState.runUp,
      (true, FacingDirection.down) => _PhantomVisualState.runDown,
      (true, FacingDirection.left) => _PhantomVisualState.runLeft,
      (true, FacingDirection.right) => _PhantomVisualState.runRight,
      (_, FacingDirection.upRight) => _PhantomVisualState.idleUp,
      (_, FacingDirection.downRight) => _PhantomVisualState.idleRight,
      (_, FacingDirection.downLeft) => _PhantomVisualState.idleLeft,
      (_, FacingDirection.upLeft) => _PhantomVisualState.idleUp,
    };
  }

  FacingDirection _visualFacing(Vector2 direction) {
    if (direction.x.abs() >= direction.y.abs()) {
      return direction.x >= 0 ? FacingDirection.right : FacingDirection.left;
    }
    return direction.y >= 0 ? FacingDirection.down : FacingDirection.up;
  }
}
