import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlayerAfterimageEffect extends PositionComponent {
  PlayerAfterimageEffect({
    required this.assetPath,
    required Vector2 position,
    required Vector2 size,
  }) : _life = _duration,
       super(
         position: position,
         size: size,
         anchor: Anchor.topLeft,
         priority: 2390,
       );

  final String assetPath;

  static const double _duration = 0.22;
  static const Color _baseTint = Color(0x88AEE9FF);
  double _life;
  late final SpriteComponent _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = SpriteComponent(
      sprite: await Sprite.load(
        assetPath,
        srcPosition: Vector2.zero(),
        srcSize: Vector2.all(16),
      ),
      size: size,
      anchor: Anchor.topLeft,
      paint: Paint()..color = _baseTint,
    );
    await add(_sprite);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    position.add(Vector2(0, -10 * dt));
    final alpha = (_life / _duration).clamp(0.0, 1.0);
    _sprite.paint = Paint()
      ..color = Color.fromARGB(
        (_baseTint.alpha * alpha).round(),
        _baseTint.red,
        _baseTint.green,
        _baseTint.blue,
      );
    if (_life <= 0) {
      removeFromParent();
    }
  }
}
