import 'dart:ui';

import 'package:flame/components.dart';

import '../../components/actors/enemy_component.dart';

class PlayerFireballEffect extends PositionComponent {
  PlayerFireballEffect({
    required this.direction,
    required Vector2 position,
    required this.canTravelTo,
    required this.findEnemyHit,
    required this.onEnemyHit,
  }) : super(
          position: position,
      size: Vector2.all(42),
          anchor: Anchor.center,
          priority: 2520,
        );

  final Vector2 direction;
  final bool Function(Rect targetRect) canTravelTo;
  final EnemyComponent? Function(Rect targetRect) findEnemyHit;
  final void Function(EnemyComponent enemy, Vector2 hitDirection) onEnemyHit;

  final double _speed = 272;
  final double _maxDistance = 330;
  double _traveledDistance = 0;
  bool _resolved = false;

  Vector2 get _direction => direction.normalized();

  String get _assetPath {
    if (direction.x.abs() >= direction.y.abs()) {
      return direction.x >= 0
          ? 'player/fireball_right.png'
          : 'player/fireball_left.png';
    }
    return direction.y >= 0
        ? 'player/fireball_bottom.png'
        : 'player/fireball_top.png';
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(
      SpriteAnimationComponent(
        animation: await SpriteAnimation.load(
          _assetPath,
          SpriteAnimationData.sequenced(
            amount: 3,
            stepTime: 0.55,
            textureSize: Vector2.all(23),
          ),
        ),
        size: size,
        anchor: Anchor.center,
        position: size / 2,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_resolved) {
      return;
    }

    final delta = _direction * _speed * dt;
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
    _traveledDistance += delta.length;

    final enemy = findEnemyHit(nextRect);
    if (enemy != null) {
      _resolved = true;
      onEnemyHit(enemy, _direction);
      removeFromParent();
      return;
    }

    if (_traveledDistance >= _maxDistance) {
      _resolved = true;
      removeFromParent();
    }
  }
}
