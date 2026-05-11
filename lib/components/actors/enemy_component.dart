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
    required this.findPath,
    required this.onAttackPlayer,
    required this.onDefeated,
  })  : _spawnPosition = position.clone(),
        super(position: position, size: size);

  final EnemyDefinition definition;
  final PlayerComponent player;
  final bool Function(EnemyComponent enemy, Rect targetRect) canMoveTo;
  final List<Vector2> Function(Rect fromBodyRect, Rect targetBodyRect)
  findPath;
  final Future<void> Function(EnemyComponent enemy, Vector2 attackDirection)
  onAttackPlayer;
  final Future<void> Function(EnemyComponent enemy) onDefeated;
  final Vector2 _spawnPosition;
  late final int _maxHp;
  late int _currentHp;
  late final SpriteAnimationComponent _sprite;
  double _attackCooldownRemaining = 0;
  bool _provoked = false;
  bool _facingLeft = false;
  final List<Vector2> _pathWaypoints = <Vector2>[];
  double _pathRefreshRemaining = 0;
  Vector2 _knockbackDirection = Vector2.zero();
  double _knockbackRemaining = 0;
  double _knockbackTotal = 0;
  final double _knockbackMinSpeed = 80;
  final double _knockbackMaxSpeed = 270;
  double _attackTelegraphRemaining = 0;
  double _attackTelegraphDuration = 0;
  double _attackTelegraphAmplitude = 0;
  double _attackTelegraphFrequency = 0;
  Completer<void>? _attackTelegraphCompleter;

  Rect get bodyRect => Rect.fromLTWH(position.x + 10, position.y + 14, size.x - 20, size.y - 18);
  int get currentHp => _currentHp;
  int get maxHp => _maxHp;
  bool get isTelegraphingAttack => _attackTelegraphRemaining > 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _maxHp = definition.maxHp;
    _currentHp = definition.maxHp;
    final usesCharacterEnemySheet =
        definition.spriteSheet.startsWith('characters/Enemy/');
    final usesBossSheet =
        definition.spriteSheet.startsWith('characters/Boss/');
    late final SpriteAnimationData animData;
    if (usesBossSheet) {
      // Boss 01.png: 288×384, 3 cols × 4 rows, 96×96 per frame.
      // Use bottom row (demon lord) at srcPosition y=288.
      animData = SpriteAnimationData([
        SpriteAnimationFrameData(
          srcPosition: Vector2(0, 288),
          srcSize: Vector2(96, 96),
          stepTime: 0.15,
        ),
        SpriteAnimationFrameData(
          srcPosition: Vector2(96, 288),
          srcSize: Vector2(96, 96),
          stepTime: 0.15,
        ),
        SpriteAnimationFrameData(
          srcPosition: Vector2(192, 288),
          srcSize: Vector2(96, 96),
          stepTime: 0.15,
        ),
      ]);
    } else {
      animData = SpriteAnimationData.sequenced(
        amount: usesCharacterEnemySheet ? 3 : 6,
        stepTime: 0.12,
        textureSize: usesCharacterEnemySheet
            ? Vector2.all(32)
            : Vector2.all(16),
      );
    }
    _sprite = SpriteAnimationComponent(
      animation: await SpriteAnimation.load(
        definition.spriteSheet,
        animData,
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
    _updateAttackTelegraph(dt);
    if (player.parent == null || findGame()?.camera == null) {
      priority = (position.y + size.y).round();
      return;
    }

    final game = findGame();
    final locked = game is RpgGame && game.controller.isFieldInputLocked;
    if (_knockbackRemaining > 0 && _knockbackDirection.length2 > 0) {
      final progress = (_knockbackTotal <= 0)
          ? 0.0
          : (_knockbackRemaining / _knockbackTotal).clamp(0.0, 1.0);
      final eased = progress * progress;
      final speed = _knockbackMinSpeed +
          (_knockbackMaxSpeed - _knockbackMinSpeed) * eased;
      final step = math.min(speed * dt, _knockbackRemaining);
      final delta = _knockbackDirection * step;
      final nextRect = bodyRect.shift(Offset(delta.x, delta.y));
      if (canMoveTo(this, nextRect)) {
        position += delta;
        _knockbackRemaining -= step;
      } else {
        _knockbackRemaining = 0;
      }
      if (_knockbackRemaining <= 0.001) {
        _knockbackRemaining = 0;
        _knockbackTotal = 0;
      }
      _pathWaypoints.clear();
      _pathRefreshRemaining = 0;
    }
    if (!locked && !isTelegraphingAttack) {
      _updateCombatMovement(dt);
    }
    _sprite.scale.x = _facingLeft ? -1 : 1;
    priority = (position.y + size.y).round();
  }

  Future<bool> playAttackTelegraph({
    double duration = 2.5,
    double amplitude = 6,
    double frequency = 10,
  }) async {
    if (!isMounted || !_sprite.isMounted) {
      return false;
    }
    if (_attackTelegraphCompleter != null) {
      await _attackTelegraphCompleter!.future;
      return isMounted;
    }
    _attackTelegraphDuration = duration;
    _attackTelegraphRemaining = duration;
    _attackTelegraphAmplitude = amplitude;
    _attackTelegraphFrequency = frequency;
    final completer = Completer<void>();
    _attackTelegraphCompleter = completer;
    await completer.future;
    return isMounted;
  }

  void _updateAttackTelegraph(double dt) {
    if (!_sprite.isMounted) {
      return;
    }
    if (_attackTelegraphRemaining <= 0) {
      if (_sprite.position.x != 0) {
        _sprite.position.x = 0;
      }
      return;
    }

    _attackTelegraphRemaining = math.max(0, _attackTelegraphRemaining - dt);
    final elapsed = _attackTelegraphDuration - _attackTelegraphRemaining;
    _sprite.position.x = math.sin(elapsed * _attackTelegraphFrequency * math.pi * 2) *
        _attackTelegraphAmplitude;

    if (_attackTelegraphRemaining <= 0.001) {
      _attackTelegraphRemaining = 0;
      _sprite.position.x = 0;
      _attackTelegraphCompleter?.complete();
      _attackTelegraphCompleter = null;
    }
  }

  void _updateCombatMovement(double dt) {
    final targetOffset = player.bodyRect.center - bodyRect.center;
    final distanceToPlayer = targetOffset.distance;
    final shouldChase = _provoked || (definition.aggressive && distanceToPlayer <= definition.aggroRange);

    if (shouldChase) {
      _provoked = true;
      final meleeReach = definition.attackRange +
          (player.bodyRect.width + bodyRect.width) * 0.22;
      final closeOverlap = bodyRect.inflate(10).overlaps(player.bodyRect);
      if (distanceToPlayer <= meleeReach || closeOverlap) {
        _pathWaypoints.clear();
        _pathRefreshRemaining = 0;
        if (_attackCooldownRemaining <= 0) {
          _attackCooldownRemaining = definition.attackCooldown;
          unawaited(onAttackPlayer(this, _attackDirectionToPlayer()));
        }
        return;
      }

      _pathRefreshRemaining = math.max(0, _pathRefreshRemaining - dt);
      if (_pathRefreshRemaining <= 0 || _pathWaypoints.isEmpty) {
        _pathWaypoints
          ..clear()
          ..addAll(findPath(bodyRect, player.bodyRect));
        _pathRefreshRemaining = 0.28;
      }

      if (_pathWaypoints.isNotEmpty) {
        final waypoint = _pathWaypoints.first;
        _moveTowardBodyCenter(waypoint, dt, definition.moveSpeed);
        if ((bodyRect.center - Offset(waypoint.x, waypoint.y)).distance <= 10) {
          _pathWaypoints.removeAt(0);
        }
      } else {
        _moveToward(player.position, dt, definition.moveSpeed);
      }
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
    if (canMoveTo(this, nextRect)) {
      position += delta;
    }
  }

  void _moveTowardBodyCenter(Vector2 targetCenter, double dt, double speed) {
    final center = bodyRect.center;
    final direction = Vector2(targetCenter.x - center.dx, targetCenter.y - center.dy);
    if (direction.length2 == 0) {
      return;
    }
    direction.normalize();
    _facingLeft = direction.x < 0;
    final maxStep = speed * dt;
    final remaining = (Offset(targetCenter.x, targetCenter.y) - center).distance;
    final step = math.min(maxStep, remaining);
    final delta = direction * step;
    final nextRect = bodyRect.shift(Offset(delta.x, delta.y));
    if (canMoveTo(this, nextRect)) {
      position += delta;
    }
  }

  void applyKnockback(Vector2 direction, {double distance = 10}) {
    if (distance <= 0 || direction.length2 == 0) {
      return;
    }
    _knockbackDirection = direction.normalized();
    _knockbackRemaining = (_knockbackRemaining + distance).clamp(0, 46);
    _knockbackTotal = math.max(_knockbackTotal, _knockbackRemaining);
  }

  Vector2 _attackDirectionToPlayer() {
    final from = bodyRect.center;
    final to = player.bodyRect.center;
    final direction = Vector2(to.dx - from.dx, to.dy - from.dy);
    if (direction.length2 == 0) {
      return _facingLeft ? Vector2(-1, 0) : Vector2(1, 0);
    }
    return direction.normalized();
  }
}