import 'package:flame/components.dart';

class EnemyAttackEffect extends PositionComponent {
  EnemyAttackEffect({required Vector2 position})
    : super(
        position: position,
        size: Vector2.all(34),
        anchor: Anchor.center,
        priority: 2550,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final burst = SpriteAnimationComponent(
      animation: await SpriteAnimation.load(
        'player/explosion_fire.png',
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.05,
          textureSize: Vector2.all(16),
          loop: false,
        ),
      ),
      position: size / 2,
      size: size,
      anchor: Anchor.center,
    );
    burst.animationTicker?.onComplete = removeFromParent;
    await add(burst);
  }
}
