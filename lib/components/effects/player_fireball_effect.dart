import 'dart:ui';

import 'package:flame/components.dart';

import '../../components/actors/enemy_component.dart';
import '../../state/models/game_models.dart';

class PlayerFireballEffect extends PositionComponent {
  PlayerFireballEffect({
    required this.facing,
    required Vector2 position,
    required this.canTravelTo,
    required this.findEnemyHit,
    required this.onEnemyHit,
  }) : super(
          position: position,
          size: Vector2.all(34),
          anchor: Anchor.center,
          priority: 2520,
        );

  final FacingDirection facing;
  final bool Function(Rect targetRect) canTravelTo;
  final EnemyComponent? Function(Rect targetRect) findEnemyHit;
  final void Function(EnemyComponent enemy) onEnemyHit;

  final double _speed = 248;
  final double _maxDistance = 248;
  double _traveledDistance = 0;
  bool _resolved = false;

  Vector2 get _direction => switch (facing) {
        FacingDirection.up => Vector2(0, -1),
        FacingDirection.down => Vector2(0, 1),
        FacingDirection.left => Vector2(-1, 0),
        FacingDirection.right => Vector2(1, 0),
      };

  String get _assetPath => switch (facing) {
        FacingDirection.up => 'player/fireball_top.png',
        FacingDirection.down => 'player/fireball_bottom.png',
        FacingDirection.left => 'player/fireball_left.png',
        FacingDirection.right => 'player/fireball_right.png',
      };

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(
      SpriteAnimationComponent(
        animation: await SpriteAnimation.load(
          _assetPath,
          SpriteAnimationData.sequenced(
            amount: 4,
            stepTime: 0.055,
            textureSize: Vector2.all(16),
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
      width: size.x * 0.42,
      height: size.y * 0.42,
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
      onEnemyHit(enemy);
      removeFromParent();
      return;
    }

    if (_traveledDistance >= _maxDistance) {
      _resolved = true;
      removeFromParent();
    }
  }
}
