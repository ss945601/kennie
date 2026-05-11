import 'package:flame/components.dart';

class PlayerAttackEffect extends PositionComponent {
  PlayerAttackEffect({
    required this.direction,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(44),
          anchor: Anchor.center,
          priority: 2500,
        );

  final Vector2 direction;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final slash = SpriteAnimationComponent(
      animation: await SpriteAnimation.load(
        _assetPath,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.045,
          textureSize: Vector2.all(16),
          loop: false,
        ),
      ),
      position: size / 2,
      size: size,
      anchor: Anchor.center,
    );
    slash.animationTicker?.onComplete = removeFromParent;
    await add(slash);
  }

  String get _assetPath {
    if (direction.x.abs() >= direction.y.abs()) {
      return direction.x >= 0
          ? 'player/attack_effect_right.png'
          : 'player/attack_effect_left.png';
    }
    return direction.y >= 0
        ? 'player/attack_effect_bottom.png'
        : 'player/attack_effect_top.png';
  }
}
