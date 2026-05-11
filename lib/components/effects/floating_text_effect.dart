import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class FloatingTextEffect extends PositionComponent {
  FloatingTextEffect({
    required this.text,
    required Vector2 position,
    this.color = const Color(0xFFFFE08A),
    this.fontSize = 14,
    this.duration = 0.9,
    this.riseSpeed = 34,
  }) : _life = duration,
       super(
         position: position,
         anchor: Anchor.center,
         priority: 2600,
       );

  final String text;
  final Color color;
  final double fontSize;
  final double duration;
  final double riseSpeed;

  double _life;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(
      TextComponent(
        text: text,
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            shadows: const [
              Shadow(color: Color(0xCC000000), blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    position.add(Vector2(0, -riseSpeed * dt));
    if (_life <= 0) {
      removeFromParent();
    }
  }
}