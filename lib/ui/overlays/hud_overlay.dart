import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio_manager.dart';
import '../../game/rpg_game.dart';
import '../responsive_overlay.dart';
import '../../state/game_state_controller.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final RpgGame game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HudStatusOverlay(game: game),
        HudControlsOverlay(game: game),
      ],
    );
  }
}

class HudStatusOverlay extends StatefulWidget {
  const HudStatusOverlay({super.key, required this.game});

  final RpgGame game;

  @override
  State<HudStatusOverlay> createState() => _HudStatusOverlayState();
}

class _HudStatusOverlayState extends State<HudStatusOverlay> {
  bool _collapsed = false;

  void _toggleCollapsed() {
    unawaited(AudioManager.instance.playActionSfx());
    setState(() {
      _collapsed = !_collapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<GameStateController>(
        builder: (context, controller, _) {
          final ui = OverlayUiConfig.of(context, enableTouchHeuristics: true);
          final stats = controller.effectiveStats;
          final potionCount = controller.inventory
              .where((entry) => entry.itemId == 'potion')
              .fold<int>(0, (total, entry) => total + entry.quantity);
          final expProgress = controller.nextLevelExperience == 0
              ? 0.0
              : (controller.experience / controller.nextLevelExperience).clamp(
                  0.0,
                  1.0,
                );
          final fontSize = ui.font(14, compactValue: 12);
          final metaFontSize = ui.font(12, compactValue: 10);
          final panelGap = ui.value(12, compactValue: 8);

          return Padding(
            padding: ui.all(12, compactValue: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Panel(
                  compact: ui.compact,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleCollapsed,
                        child: Container(
                          width: ui.value(78, compactValue: 64),
                          height: ui.value(78, compactValue: 64),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white30,
                              width: 1.6,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/kennie.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      if (!_collapsed) ...[
                        SizedBox(width: ui.value(10, compactValue: 8)),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width * 0.33,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${controller.playerName}  Lv.${controller.level}  ${controller.currentMapId.toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: fontSize,
                                ),
                              ),
                              SizedBox(height: ui.value(4, compactValue: 3)),
                              LinearProgressIndicator(
                                value: stats.maxHp == 0 ? 0 : stats.hp / stats.maxHp,
                                minHeight: ui.value(10, compactValue: 7),
                                backgroundColor: Colors.white12,
                                color: const Color(0xFFE25B5B),
                              ),
                              SizedBox(height: ui.value(4, compactValue: 3)),
                              LinearProgressIndicator(
                                value: stats.maxMp == 0 ? 0 : stats.mp / stats.maxMp,
                                minHeight: ui.value(8, compactValue: 6),
                                backgroundColor: Colors.white10,
                                color: const Color(0xFF4E8FF0),
                              ),
                              SizedBox(height: ui.value(4, compactValue: 3)),
                              LinearProgressIndicator(
                                value: expProgress,
                                minHeight: ui.value(8, compactValue: 6),
                                backgroundColor: Colors.white10,
                                color: const Color(0xFF7AE582),
                              ),
                              SizedBox(height: ui.value(6, compactValue: 4)),
                              Wrap(
                                spacing: ui.value(12, compactValue: 8),
                                runSpacing: ui.value(4, compactValue: 2),
                                children: <Widget>[
                                  Text(
                                    'HP ${stats.hp}/${stats.maxHp}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: metaFontSize,
                                    ),
                                  ),
                                  Text(
                                    'MP ${stats.mp}/${stats.maxMp}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: metaFontSize,
                                    ),
                                  ),
                                  Text(
                                    'ATK ${stats.attack}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: metaFontSize,
                                    ),
                                  ),
                                  Text(
                                    'DEF ${stats.defense}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: metaFontSize,
                                    ),
                                  ),
                                  Text(
                                    '藥水 x$potionCount',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: metaFontSize,
                                    ),
                                  ),
                                  Text(
                                    'EXP ${controller.experience}/${controller.nextLevelExperience}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: metaFontSize,
                                    ),
                                  ),
                                  Text(
                                    '金幣 ${controller.gold}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: metaFontSize,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      IconButton(onPressed: _toggleCollapsed, icon: !_collapsed ? Icon(Icons.arrow_left) : Icon(Icons.arrow_right) )
                    ],
                  ),
                ),
                if (!_collapsed) ...[
                  SizedBox(height: panelGap),
                  _Panel(
                    compact: ui.compact,
                    color: const Color(0xB2182438),
                    child: Text(
                      controller.hudMessage,
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: metaFontSize,
                      ),
                    ),
                  ),
                  SizedBox(height: ui.value(10, compactValue: 6)),
                  _Panel(
                    compact: ui.compact,
                    color: const Color(0x99121820),
                    child: Text(
                      ui.touchControls
                          ? '左下搖桿移動  按住右下火球搖桿瞄準，放開施放  右上暫停'
                          : 'J/Enter 近戰  K/2 火球  H/1 藥水  Space 互動  Esc 選單',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: ui.font(12, compactValue: 9.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class HudControlsOverlay extends StatelessWidget {
  const HudControlsOverlay({super.key, required this.game});

  final RpgGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<GameStateController>(
        builder: (context, controller, _) {
          final ui = OverlayUiConfig.of(context, enableTouchHeuristics: true);
          final potionCount = controller.inventory
              .where((entry) => entry.itemId == 'potion')
              .fold<int>(0, (total, entry) => total + entry.quantity);
          final manaPotionCount = controller.inventory
              .where((entry) => entry.itemId == 'mana_potion')
              .fold<int>(0, (total, entry) => total + entry.quantity);
          if (!ui.touchControls) {
            return const SizedBox.shrink();
          }

          return Stack(
            children: [
              Positioned(
                right: ui.value(64, compactValue: 48),
                top: ui.value(12, compactValue: 8),
                child: _TouchActionButton(
                  icon: Icons.pause_rounded,
                  label: '選單',
                  compact: ui.compact,
                  onPressed: () {
                    unawaited(AudioManager.instance.playActionSfx());
                    game.handlePauseToggle();
                  },
                ),
              ),
              Positioned(
                left: ui.value(16, compactValue: 8),
                bottom: ui.value(20, compactValue: 8),
                child: _VirtualJoystick(
                  onChanged: game.updateTouchMovement,
                  onEnd: game.stopTouchMovement,
                  enabled: !controller.isFieldInputLocked,
                  compact: ui.compact,
                ),
              ),
              Positioned(
                right: ui.value(64, compactValue: 48),
                bottom: ui.value(25, compactValue: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _TouchActionButton(
                      icon: Icons.back_hand_rounded,
                      label: '互動',
                      compact: ui.compact,
                      onPressed: controller.isFieldInputLocked
                          ? null
                          : () {
                              unawaited(AudioManager.instance.playActionSfx());
                              game.handleInteraction();
                            },
                    ),
                    _buildPotionButtons(potionCount, ui, controller, manaPotionCount),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ArcAttackButton(
                          compact: ui.compact,
                          onPressed: controller.isFieldInputLocked
                              ? null
                          : game.handleAttack,
                        ),
                        SizedBox(width: ui.value(4, compactValue: 2)),
                        _RangedAimJoystick(
                          compact: ui.compact,
                          enabled: !controller.isFieldInputLocked,
                          label: '技能',
                          sizeMultiplier: 1.2,
                          onCast: (direction) {
                            unawaited(game.handleFireball(direction: direction));
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: ui.value(12, compactValue: 8)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Row _buildPotionButtons(int potionCount, OverlayUiConfig ui, GameStateController controller, int manaPotionCount) {
    return Row(
                    children: [
                      _TouchActionButton(
                        iconAssetPath: 'assets/images/items/potion_life.png',
                        label: 'x$potionCount',
                        accentColor: const Color(0xFF3A7E61),
                        compact: ui.compact,
                        onPressed: controller.isFieldInputLocked
                            ? null
                            : () {
                                unawaited(AudioManager.instance.playActionSfx());
                                game.handleQuickPotion();
                              },
                      ),
                      SizedBox(height: ui.value(10, compactValue: 6)),
                      _TouchActionButton(
                        iconAssetPath: 'assets/images/items/potion_mana.png',
                        label: 'x$manaPotionCount',
                        accentColor: const Color(0xFF2F5EA5),
                        compact: ui.compact,
                        onPressed: controller.isFieldInputLocked
                            ? null
                            : () {
                                unawaited(
                                  AudioManager.instance.playActionSfx(),
                                );
                                game.handleQuickManaPotion();
                              },
                      ),
                    ],
                  );
  }
}

class _ArcAttackButton extends StatelessWidget {
  const _ArcAttackButton({
    required this.onPressed,
    this.compact = false,
  });

  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final size = compact ? 110.0 : 132.0;
    final geometry = _ArcAttackGeometry.fromSize(Size.square(size));
    final contentCenter = geometry.contentCenter;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _ArcAttackButtonPainter(enabled: enabled),
              ),
              Positioned(
                left: contentCenter.dx,
                top: contentCenter.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.gavel_rounded,
                        color: Colors.white,
                        size: compact ? 22 : 28,
                      ),
                      SizedBox(height: compact ? 1 : 3),
                      Text(
                        '攻擊',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 10 : 12,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcAttackButtonPainter extends CustomPainter {
  const _ArcAttackButtonPainter({required this.enabled});

  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _ArcAttackGeometry.fromSize(size);
    final path = _buildPath(geometry);
    final fill = Paint()
      ..color = enabled
          ? Colors.red
          : Colors.red
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = enabled
          ? Colors.white70
          : Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    final dividerPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final middleAngle = geometry.middleAngle;
    final p1 = Offset(
      geometry.center.dx + math.cos(middleAngle) * geometry.innerRadius,
      geometry.center.dy + math.sin(middleAngle) * geometry.innerRadius,
    );
    final p2 = Offset(
      geometry.center.dx + math.cos(middleAngle) * geometry.outerRadius,
      geometry.center.dy + math.sin(middleAngle) * geometry.outerRadius,
    );
    canvas.drawLine(p1, p2, dividerPaint);
  }

  Path _buildPath(_ArcAttackGeometry geometry) {
    final outerRect = Rect.fromCircle(
      center: geometry.center,
      radius: geometry.outerRadius,
    );
    final innerRect = Rect.fromCircle(
      center: geometry.center,
      radius: geometry.innerRadius,
    );

    return Path()
      ..arcTo(outerRect, geometry.startAngle, geometry.sweepAngle, false)
      ..arcTo(
        innerRect,
        geometry.startAngle + geometry.sweepAngle,
        -geometry.sweepAngle,
        false,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant _ArcAttackButtonPainter oldDelegate) {
    return oldDelegate.enabled != enabled;
  }
}

class _ArcAttackGeometry {
  const _ArcAttackGeometry({
    required this.center,
    required this.outerRadius,
    required this.innerRadius,
    required this.startAngle,
    required this.sweepAngle,
  });

  final Offset center;
  final double outerRadius;
  final double innerRadius;
  final double startAngle;
  final double sweepAngle;

  factory _ArcAttackGeometry.fromSize(Size size) {
    return _ArcAttackGeometry(
      center: Offset(size.width, size.height * 0.52),
      outerRadius: size.width * 0.6,
      innerRadius: size.width * 0.15,
      startAngle: 2.35,
      sweepAngle: 1.42,
    );
  }

  double get middleAngle => startAngle + sweepAngle * 0.5;

  Offset get contentCenter {
    final radius = innerRadius + (outerRadius - innerRadius) * 0.58;
    return Offset(
      center.dx + math.cos(middleAngle) * radius,
      center.dy + math.sin(middleAngle) * radius,
    );
  }
}

class _RangedAimJoystick extends StatefulWidget {
  const _RangedAimJoystick({
    required this.enabled,
    required this.onCast,
    required this.label,
    this.sizeMultiplier = 1,
    this.compact = false,
  });

  final bool enabled;
  final ValueChanged<Vector2> onCast;
  final String label;
  final double sizeMultiplier;
  final bool compact;

  @override
  State<_RangedAimJoystick> createState() => _RangedAimJoystickState();
}

class _RangedAimJoystickState extends State<_RangedAimJoystick> {
  Offset _knobOffset = Offset.zero;
  bool _isAiming = false;
  int? _activePointer;

  double get _baseSize =>
    (widget.compact ? 70 : 88) * widget.sizeMultiplier;
  double get _knobSize =>
    (widget.compact ? 26 : 32) * widget.sizeMultiplier;
  double get _travelRadius =>
    (widget.compact ? 18 : 23) * widget.sizeMultiplier;

  Vector2 get _castDirection {
    if (_knobOffset == Offset.zero) {
      return Vector2(0, -1);
    }
    return Vector2(_knobOffset.dx, _knobOffset.dy).normalized();
  }

  @override
  void didUpdateWidget(covariant _RangedAimJoystick oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) {
      _resetStick(notifyParent: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final frameColor = const Color(0xFFAA3A30);
    final baseColor = _isAiming
        ? const Color(0x66B63B2C)
        : const Color(0x5533221F);

    return Opacity(
      opacity: widget.enabled ? 1 : 0.55,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: widget.enabled
            ? (event) {
                if (_activePointer != null) {
                  return;
                }
                _activePointer = event.pointer;
                _isAiming = true;
                _updateStick(event.localPosition);
              }
            : null,
        onPointerMove: widget.enabled
            ? (event) {
                if (_activePointer != event.pointer) {
                  return;
                }
                _updateStick(event.localPosition);
              }
            : null,
        onPointerUp: widget.enabled
            ? (event) {
                if (_activePointer != event.pointer) {
                  return;
                }
                _releaseCast();
              }
            : null,
        onPointerCancel: widget.enabled
            ? (event) {
                if (_activePointer != event.pointer) {
                  return;
                }
                _resetStick();
              }
            : null,
        child: SizedBox(
          width: _baseSize,
          height: _baseSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: baseColor,
                  border: Border.all(color: frameColor.withValues(alpha: 0.8)),
                ),
                child: SizedBox(width: _baseSize, height: _baseSize),
              ),
              Transform.translate(
                offset: _knobOffset,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xCCF15E42),
                    border: Border.all(color: Colors.white70),
                  ),
                  child: SizedBox(width: _knobSize, height: _knobSize),
                ),
              ),
              Positioned(
                bottom: 2,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.compact ? 8.5 : 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateStick(Offset localPosition) {
    if (!mounted) {
      return;
    }
    final center = Offset(_baseSize / 2, _baseSize / 2);
    var delta = localPosition - center;
    final distance = delta.distance;
    if (distance > _travelRadius) {
      final scale = _travelRadius / distance;
      delta = Offset(delta.dx * scale, delta.dy * scale);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isAiming = true;
      _knobOffset = delta;
    });
  }

  void _resetStick({bool notifyParent = true}) {
    if (!mounted) {
      return;
    }
    _activePointer = null;
    if (!_isAiming && _knobOffset == Offset.zero) {
      return;
    }
    setState(() {
      _isAiming = false;
      _knobOffset = Offset.zero;
    });
  }

  void _releaseCast() {
    if (!mounted) {
      return;
    }
    if (_isAiming) {
      widget.onCast(_castDirection);
    }
    _resetStick();
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.color = const Color(0xCC111827),
    this.compact = false,
  });

  final Widget child;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 12,
          vertical: compact ? 5 : 8,
        ),
        child: child,
      ),
    );
  }
}

class _TouchActionButton extends StatelessWidget {
  const _TouchActionButton({
    this.icon,
    this.iconAssetPath,
    required this.label,
    required this.onPressed,
    this.accentColor = const Color(0xCC111827),
    this.compact = false,
  }) : assert(icon != null || iconAssetPath != null);

  final IconData? icon;
  final String? iconAssetPath;
  final String label;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 16.0 : 22.0;
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: accentColor,
        disabledBackgroundColor: accentColor.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 16,
          vertical: compact ? 8 : 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 18),
          side: const BorderSide(color: Colors.white24),
        ),
      ),
      icon: iconAssetPath != null
          ? Image.asset(
              iconAssetPath!,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            )
          : Icon(icon, size: iconSize),
      label: Text(
        label,
        style: TextStyle(fontSize: compact ? 10 : 14),
      ),
    );
  }
}

class _VirtualJoystick extends StatefulWidget {
  const _VirtualJoystick({
    required this.onChanged,
    required this.onEnd,
    required this.enabled,
    this.compact = false,
  });

  final ValueChanged<Vector2> onChanged;
  final VoidCallback onEnd;
  final bool enabled;
  final bool compact;

  @override
  State<_VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<_VirtualJoystick> {
  Offset _knobOffset = Offset.zero;

  double get _baseSize => widget.compact ? 160 : 206;
  double get _knobSize => widget.compact ? 70 : 92;
  double get _travelRadius => widget.compact ? 45 : 66;

  @override
  void didUpdateWidget(covariant _VirtualJoystick oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) {
      _resetStick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.6,
      child: GestureDetector(
        onPanStart: widget.enabled
            ? (details) => _updateStick(details.globalPosition)
            : null,
        onPanUpdate: widget.enabled
            ? (details) => _updateStick(details.globalPosition)
            : null,
        onPanEnd: widget.enabled ? (_) => _resetStick() : null,
        onPanCancel: widget.enabled ? _resetStick : null,
        child: SizedBox(
          width: _baseSize,
          height: _baseSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x66111827),
                  border: Border.all(color: Colors.white24),
                ),
                child: SizedBox(width: _baseSize, height: _baseSize),
              ),
              Transform.translate(
                offset: _knobOffset,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xCC2E4059),
                    border: Border.all(color: Colors.white38),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(width: _knobSize, height: _knobSize),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateStick(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }
    final local = renderBox.globalToLocal(globalPosition);
    final center = Offset(renderBox.size.width / 2, renderBox.size.height / 2);
    var delta = local - center;
    final distance = delta.distance;
    if (distance > _travelRadius) {
      final scale = _travelRadius / distance;
      delta = Offset(delta.dx * scale, delta.dy * scale);
    }

    setState(() {
      _knobOffset = delta;
    });

    widget.onChanged(
      Vector2(delta.dx / _travelRadius, delta.dy / _travelRadius),
    );
  }

  void _resetStick() {
    if (_knobOffset == Offset.zero) {
      widget.onEnd();
      return;
    }
    setState(() {
      _knobOffset = Offset.zero;
    });
    widget.onEnd();
  }
}
