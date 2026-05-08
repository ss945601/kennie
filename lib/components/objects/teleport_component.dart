import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TeleportComponent extends RectangleComponent {
  TeleportComponent({
    required super.position,
    required super.size,
    required this.targetMapId,
    required this.targetSpawnId,
    this.requiredStoryFlag,
    this.blockedMessage,
  }) : super(
          paint: Paint()..color = Colors.transparent,
          priority: 50,
        );

  final String targetMapId;
  final String targetSpawnId;
  final String? requiredStoryFlag;
  final String? blockedMessage;
}
