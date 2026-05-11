import 'package:flame/components.dart';

import '../../state/models/game_models.dart';

class PlayerAttackEffect extends PositionComponent {
  PlayerAttackEffect({
    required this.facing,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(44),
          anchor: Anchor.center,
          priority: 2500,
        );

  final FacingDirection facing;

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

  String get _assetPath => switch (facing) {
        FacingDirection.up => 'player/attack_effect_top.png',
        FacingDirection.down => 'player/attack_effect_bottom.png',
        FacingDirection.left => 'player/attack_effect_left.png',
        FacingDirection.right => 'player/attack_effect_right.png',
      };
}
