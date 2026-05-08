import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../game/rpg_game.dart';
import '../../state/models/game_models.dart';
import 'player_component.dart';

class EnemyComponent extends PositionComponent {
  EnemyComponent({
    required Vector2 position,
    required Vector2 size,
    required this.definition,
    required this.player,
    required this.canMoveTo,
    required this.onAttackPlayer,
    required this.onDefeated,
  })  : _spawnPosition = position.clone(),
        super(position: position, size: size);

  final EnemyDefinition definition;
  final PlayerComponent player;
  final bool Function(Rect targetRect) canMoveTo;
  final Future<void> Function(EnemyComponent enemy) onAttackPlayer;
  final Future<void> Function(EnemyComponent enemy) onDefeated;
  final Vector2 _spawnPosition;
  late final int _maxHp;
  late int _currentHp;
  late final SpriteAnimationComponent _sprite;
  double _attackCooldownRemaining = 0;
  bool _provoked = false;
  bool _facingLeft = false;

  Rect get bodyRect => Rect.fromLTWH(position.x + 10, position.y + 14, size.x - 20, size.y - 18);
  int get currentHp => _currentHp;
  int get maxHp => _maxHp;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _maxHp = definition.maxHp;
    _currentHp = definition.maxHp;
    _sprite = SpriteAnimationComponent(
      animation: await SpriteAnimation.load(
        definition.spriteSheet,
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.12,
          textureSize: definition.spriteSheet.contains('/') ? Vector2.all(16) : Vector2.all(64),
        ),
      ),
      size: size,
      anchor: Anchor.topLeft,
    );
    await add(_sprite);
  }

  Future<bool> receiveDamage(int damage) async {
    _provoked = true;
    _currentHp = math.max(0, _currentHp - damage);
    if (_currentHp == 0) {
      await onDefeated(this);
      return true;
    }
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_attackCooldownRemaining > 0) {
      _attackCooldownRemaining = math.max(0, _attackCooldownRemaining - dt);
    }
    if (player.parent == null || findGame()?.camera == null) {
      priority = (position.y + size.y).round();
      return;
    }

    final game = findGame();
    final locked = game is RpgGame && game.controller.isFieldInputLocked;
    if (!locked) {
      _updateCombatMovement(dt);
    }
    _sprite.scale.x = _facingLeft ? -1 : 1;
    priority = (position.y + size.y).round();
  }

  void _updateCombatMovement(double dt) {
    final targetOffset = player.position - position;
    final distanceToPlayer = targetOffset.length;
    final shouldChase = _provoked || (definition.aggressive && distanceToPlayer <= definition.aggroRange);

    if (shouldChase) {
      _provoked = true;
      if (distanceToPlayer <= definition.attackRange) {
        if (_attackCooldownRemaining <= 0) {
          _attackCooldownRemaining = definition.attackCooldown;
          unawaited(onAttackPlayer(this));
        }
        return;
      }
      _moveToward(player.position, dt, definition.moveSpeed);
      return;
    }

    final distanceToSpawn = position.distanceTo(_spawnPosition);
    if (distanceToSpawn > 6) {
      _moveToward(_spawnPosition, dt, definition.moveSpeed * 0.6);
    }
  }

  void _moveToward(Vector2 target, double dt, double speed) {
    final direction = target - position;
    if (direction.length2 == 0) {
      return;
    }
    direction.normalize();
    _facingLeft = direction.x < 0;
    final delta = direction * speed * dt;
    final nextRect = bodyRect.shift(Offset(delta.x, delta.y));
    if (canMoveTo(nextRect)) {
      position += delta;
    }
  }
}