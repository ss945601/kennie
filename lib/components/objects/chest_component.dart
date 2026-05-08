import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'interactable_entity.dart';

class ChestComponent extends RectangleComponent implements InteractableEntity {
  ChestComponent({
    required super.position,
    required super.size,
    required this.chestId,
    required this.onInteract,
  }) : super(
          paint: Paint()..color = Colors.orangeAccent,
        ) {
    _syncPriority();
  }

  final String chestId;
  final Future<void> Function() onInteract;
  bool opened = false;

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
    paint.color = Colors.orange.withValues(alpha: 0.5);
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
