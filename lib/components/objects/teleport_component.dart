import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TeleportComponent extends RectangleComponent {
  TeleportComponent({
    required super.position,
    required super.size,
    required this.targetMapId,
    required this.targetSpawnId,
  }) : super(
          paint: Paint()..color = Colors.red.withValues(alpha: 0.5),
          priority: 50,
        );

  final String targetMapId;
  final String targetSpawnId;
}
