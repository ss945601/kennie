import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/rpg_game.dart';
import '../responsive_overlay.dart';
import '../../state/game_state_controller.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({
    super.key,
    required this.game,
  });

  final RpgGame game;

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
              : (controller.experience / controller.nextLevelExperience).clamp(0.0, 1.0);
          final imageSize = ui.value(72, compactValue: 52);
          final fontSize = ui.font(14, compactValue: 12);
          final metaFontSize = ui.font(12, compactValue: 10);
          final panelGap = ui.value(12, compactValue: 8);

          return Stack(
            children: [
              IgnorePointer(
                ignoring: true,
                child: Padding(
                  padding: ui.all(12, compactValue: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Panel(
                        compact: ui.compact,
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/health_ui.png',
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: ui.value(10, compactValue: 8)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lv.${controller.level}  ${controller.currentMapId.toUpperCase()}',
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
                                        style: TextStyle(color: Colors.white, fontSize: metaFontSize),
                                      ),
                                      Text(
                                        'ATK ${stats.attack}',
                                        style: TextStyle(color: Colors.white, fontSize: metaFontSize),
                                      ),
                                      Text(
                                        'DEF ${stats.defense}',
                                        style: TextStyle(color: Colors.white, fontSize: metaFontSize),
                                      ),
                                      Text(
                                        '藥水 x$potionCount',
                                        style: TextStyle(color: Colors.white, fontSize: metaFontSize),
                                      ),
                                      Text(
                                        'EXP ${controller.experience}/${controller.nextLevelExperience}',
                                        style: TextStyle(color: Colors.white, fontSize: metaFontSize),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: panelGap),
                      _Panel(
                        compact: ui.compact,
                        color: const Color(0xB2182438),
                        child: Text(
                          controller.hudMessage,
                          style: TextStyle(color: Colors.white70, fontSize: metaFontSize),
                        ),
                      ),
                      SizedBox(height: ui.value(10, compactValue: 6)),
                      _Panel(
                        compact: ui.compact,
                        color: const Color(0x99121820),
                        child: Text(
                          ui.touchControls
                              ? '左下搖桿移動  右下攻擊/互動/藥水  右上暫停'
                              : 'J/Enter 攻擊  H/1 藥水  Space 互動  Esc 選單',
                          style: TextStyle(color: Colors.white54, fontSize: ui.font(12, compactValue: 9.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (ui.touchControls) ...[
                Positioned(
                  top: ui.value(12, compactValue: 8),
                  right: ui.value(12, compactValue: 8),
                  child: _TouchActionButton(
                    icon: Icons.pause_rounded,
                    label: '選單',
                    compact: ui.compact,
                    onPressed: game.handlePauseToggle,
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
                  right: ui.value(16, compactValue: 8),
                  bottom: ui.value(20, compactValue: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TouchActionButton(
                            icon: Icons.back_hand_rounded,
                            label: '互動',
                            compact: ui.compact,
                            onPressed: controller.isFieldInputLocked ? null : () => game.handleInteraction(),
                          ),
                          SizedBox(width: ui.value(12, compactValue: 8)),
                          _TouchActionButton(
                            icon: Icons.gavel_rounded,
                            label: '攻擊',
                            accentColor: const Color(0xFFC24C32),
                            compact: ui.compact,
                            onPressed: controller.isFieldInputLocked ? null : () => game.handleAttack(),
                          ),
                        ],
                      ),
                      SizedBox(height: ui.value(12, compactValue: 8)),
                      _TouchActionButton(
                        icon: Icons.auto_awesome,
                        label: '藥水 x$potionCount',
                        accentColor: const Color(0xFF3A7E61),
                        compact: ui.compact,
                        onPressed: controller.isFieldInputLocked ? null : game.handleQuickPotion,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
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
        padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12, vertical: compact ? 5 : 8),
        child: child,
      ),
    );
  }
}

class _TouchActionButton extends StatelessWidget {
  const _TouchActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.accentColor = const Color(0xCC111827),
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
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
      icon: Icon(icon, size: compact ? 16 : 22),
      label: Text(label, style: TextStyle(fontSize: compact ? 10 : 14)),
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

  double get _baseSize => widget.compact ? 78 : 128;
  double get _knobSize => widget.compact ? 32 : 52;
  double get _travelRadius => widget.compact ? 22 : 38;

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
        onPanStart: widget.enabled ? (details) => _updateStick(details.globalPosition) : null,
        onPanUpdate: widget.enabled ? (details) => _updateStick(details.globalPosition) : null,
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
      Vector2(
        delta.dx / _travelRadius,
        delta.dy / _travelRadius,
      ),
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
