import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../objects/interactable_entity.dart';

class NpcComponent extends RectangleComponent implements InteractableEntity {
  NpcComponent({
    required super.position,
    required super.size,
    required this.npcId,
    required this.onInteract,
  }) : super(
          paint: Paint()..color = Colors.greenAccent,
        ) {
    _syncPriority();
  }

  final String npcId;
  final Future<void> Function() onInteract;

  @override
  String get interactionLabel => '與 $npcId 對話';

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
