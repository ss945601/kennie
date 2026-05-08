import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';

import 'interactable_entity.dart';

class ChestComponent extends PositionComponent implements InteractableEntity {
  ChestComponent({
    required super.position,
    required super.size,
    required this.chestId,
    required this.onInteract,
  }) {
    _syncPriority();
  }

  final String chestId;
  final Future<void> Function() onInteract;
  bool opened = false;
  late final SpriteAnimationComponent _sprite;
  late final SpriteAnimation _closedAnimation;
  late final SpriteAnimation _openingAnimation;
  late final SpriteAnimation _openedAnimation;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final frames = await Future.wait(
      List<Future<Sprite>>.generate(
        4,
        (index) => Sprite.load(
          'items/chest_spritesheet.png',
          srcPosition: Vector2(index * 16, 0),
          srcSize: Vector2.all(16),
        ),
      ),
    );
    _closedAnimation = SpriteAnimation.spriteList([frames.first], stepTime: 1);
    _openingAnimation = SpriteAnimation.spriteList(frames, stepTime: 0.08, loop: false);
    _openedAnimation = SpriteAnimation.spriteList([frames.last], stepTime: 1);
    _sprite = SpriteAnimationComponent(
      animation: opened ? _openedAnimation : _closedAnimation,
      size: size,
      anchor: Anchor.topLeft,
    );
    await add(_sprite);
  }

  @override
  String get interactionLabel => opened ? '已開啟的寶箱' : '打開寶箱';

  @override
  Rect get interactionBounds => toAbsoluteRect();

  @override
  Future<void> interact() async {
    if (opened) {
      return;
    }
    await onInteract();
    opened = true;
    _sprite.animation = _openingAnimation;
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        if (isMounted) {
          _sprite.animation = _openedAnimation;
        }
      }),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _syncPriority();
  }

  void _syncPriority() {
    priority = (position.y + size.y).round();
  }
}
