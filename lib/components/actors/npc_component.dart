import 'dart:ui';

import 'package:flame/components.dart';

import '../objects/interactable_entity.dart';

class NpcComponent extends PositionComponent implements InteractableEntity {
  NpcComponent({
    required super.position,
    required super.size,
    required this.npcId,
    required this.interactionLabel,
    required this.spritePath,
    required this.onInteract,
    this.idleFrames = 2,
  }) {
    _syncPriority();
  }

  final String npcId;
  @override
  final String interactionLabel;
  final String spritePath;
  final int idleFrames;
  final Future<void> Function() onInteract;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final usesCharacterSheet = spritePath.startsWith('characters/');
    await add(
      SpriteAnimationComponent(
        animation: await SpriteAnimation.load(
          spritePath,
          SpriteAnimationData.sequenced(
            amount: idleFrames,
            stepTime: 0.18,
            textureSize: usesCharacterSheet ? Vector2.all(32) : Vector2.all(16),
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
    _syncPriority();
  }

  void _syncPriority() {
    priority = (position.y + size.y).round();
  }
}
