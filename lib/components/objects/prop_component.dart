import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PropComponent extends RectangleComponent {
  PropComponent({
    required super.position,
    required super.size,
    required Color color,
  }) : super(
          paint: Paint()..color = color,
        ) {
    _syncPriority();
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
