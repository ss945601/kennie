import 'dart:ui';

import 'package:flame/components.dart';

import '../objects/interactable_entity.dart';

class EnemyComponent extends PositionComponent implements InteractableEntity {
  EnemyComponent({
    required super.position,
    required super.size,
    required this.enemyId,
    required this.interactionLabel,
    required this.onInteract,
  });

  final String enemyId;

  @override
  final String interactionLabel;

  final Future<void> Function() onInteract;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(
      SpriteAnimationComponent(
        animation: await SpriteAnimation.load(
          'enemy/goblin_run_right.png',
          SpriteAnimationData.sequenced(
            amount: 6,
            stepTime: 0.12,
            textureSize: Vector2.all(16),
          ),
        ),
        size: size,
        anchor: Anchor.topLeft,
      ),
    );
  }

  @override
  Rect get interactionBounds => toAbsoluteRect();

  @override
  Future<void> interact() => onInteract();

  @override
  void update(double dt) {
    super.update(dt);
    priority = (position.y + size.y).round();
  }
}