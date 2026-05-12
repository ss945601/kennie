import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../actors/player_component.dart';

class PlayerLegendAuraEffect extends PositionComponent {
  PlayerLegendAuraEffect({required this.player})
    : super(
        position: Vector2.zero(),
        size: Vector2.all(72),
        anchor: Anchor.center,
        priority: 2405,
      );

  final PlayerComponent player;

  late final CircleComponent _outerRing;
  late final CircleComponent _innerCore;
  double _elapsed = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _outerRing = CircleComponent(
      radius: 22,
      anchor: Anchor.center,
      paint: Paint()
        ..color = const Color(0x66FFE082)
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    _innerCore = CircleComponent(
      radius: 12,
      anchor: Anchor.center,
      paint: Paint()
        ..color = const Color(0x88FFF3C4)
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    await add(_outerRing);
    await add(_innerCore);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!player.isMounted) {
      removeFromParent();
      return;
    }

    final body = player.bodyRect;
    position = Vector2(body.center.dx, body.center.dy);

    _elapsed += dt;
    final pulse = (math.sin(_elapsed * 6.2) + 1) * 0.5;
    _outerRing.scale = Vector2.all(0.92 + pulse * 0.22);
    _innerCore.scale = Vector2.all(0.9 + pulse * 0.14);

    _outerRing.paint = Paint()
      ..color = Color.fromARGB(
        (74 + pulse * 90).round(),
        255,
        224,
        130,
      )
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    _innerCore.paint = Paint()
      ..color = Color.fromARGB(
        (96 + pulse * 110).round(),
        255,
        243,
        196,
      )
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  }
}
