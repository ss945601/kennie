import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class DamageNumberEffect extends PositionComponent {
  DamageNumberEffect({
    required this.amount,
    required this.isPlayerHit,
    required Vector2 position,
  }) : super(
          position: position,
          anchor: Anchor.center,
          priority: 2600,
        );

  final int amount;
  final bool isPlayerHit;
  double _life = 0.6;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(
      TextComponent(
        text: '-$amount',
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: TextStyle(
            color: isPlayerHit ? const Color(0xFFFF7D7D) : const Color(0xFFFFE08A),
            fontSize: 16,
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
    position.add(Vector2(0, -36 * dt));
    if (_life <= 0) {
      removeFromParent();
    }
  }
}
