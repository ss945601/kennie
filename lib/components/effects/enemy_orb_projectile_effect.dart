import 'dart:ui';

import 'package:flame/components.dart';

class EnemyOrbProjectileEffect extends PositionComponent {
  EnemyOrbProjectileEffect({
    required Vector2 position,
    required this.direction,
    required this.canTravelTo,
    required this.onHitTarget,
    double speed = 190,
    double maxDistance = 260,
  }) : _speed = speed,
       _maxDistance = maxDistance,
       super(
         position: position,
         size: Vector2.all(14),
         anchor: Anchor.center,
         priority: 2510,
       );

  final Vector2 direction;
  final bool Function(Rect targetRect) canTravelTo;
  final bool Function(Rect targetRect, Vector2 hitDirection) onHitTarget;

  final double _speed;
  final double _maxDistance;
  double _travelled = 0;
  bool _resolved = false;

  Vector2 get _normalizedDirection =>
      direction.length2 == 0 ? Vector2(0, 1) : direction.normalized();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(
      CircleComponent(
        radius: size.x / 2,
        anchor: Anchor.center,
        position: size / 2,
        paint: Paint()..color = const Color(0xFFD86A3A),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_resolved) {
      return;
    }

    final delta = _normalizedDirection * (_speed * dt);
    final nextPosition = position + delta;
    final nextRect = Rect.fromCenter(
      center: Offset(nextPosition.x, nextPosition.y),
      width: size.x * 0.72,
      height: size.y * 0.72,
    );

    if (!canTravelTo(nextRect)) {
      _resolved = true;
      removeFromParent();
      return;
    }

    position = nextPosition;
    _travelled += delta.length;

    if (onHitTarget(nextRect, _normalizedDirection)) {
      _resolved = true;
      removeFromParent();
      return;
    }

    if (_travelled >= _maxDistance) {
      _resolved = true;
      removeFromParent();
    }
  }
}
