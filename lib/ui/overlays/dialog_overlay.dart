import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio_manager.dart';
import '../../state/game_state_controller.dart';
import '../../state/models/game_models.dart';
import '../responsive_overlay.dart';
import '../widgets/typewriter_text.dart';

class DialogOverlay extends StatefulWidget {
  const DialogOverlay({super.key});

  @override
  State<DialogOverlay> createState() => _DialogOverlayState();
}

class _DialogOverlayState extends State<DialogOverlay> {
  final GlobalKey<_DialogTextCardState> _dialogKey = GlobalKey<_DialogTextCardState>();

  @override
  Widget build(BuildContext context) {
    final ui = OverlayUiConfig.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Consumer<GameStateController>(
          builder: (context, controller, _) {
            final session = controller.activeDialog;
            if (session == null) {
              return const SizedBox.shrink();
            }
            final showGoldBadge = session.currentNode.speaker == '商人' || session.currentNode.speaker == '迷霧商旅';
            return Padding(
              padding: ui.all(16, compactValue: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showGoldBadge) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ui.value(10, compactValue: 8),
                        vertical: ui.value(6, compactValue: 4),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xB2000000),
                        borderRadius: BorderRadius.circular(ui.radius(12, compactValue: 10)),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        '金幣 ${controller.gold}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: ui.font(12, compactValue: 10),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: ui.value(8, compactValue: 6)),
                  ],
                  _DialogTextCard(
                    key: _dialogKey,
                    session: session,
                    onAdvance: controller.advanceDialog,
                    onChoiceSelected: controller.chooseDialogChoice,
                    compact: ui.compact,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DialogTextCard extends StatefulWidget {
  const _DialogTextCard({
    super.key,
    required this.session,
    required this.onAdvance,
    required this.onChoiceSelected,
    required this.compact,
  });

  final DialogSession session;
  final VoidCallback onAdvance;
  final ValueChanged<DialogChoice> onChoiceSelected;
  final bool compact;

  @override
  State<_DialogTextCard> createState() => _DialogTextCardState();
}

class _DialogTextCardState extends State<_DialogTextCard> {
  bool _completed = false;

  @override
  void didUpdateWidget(covariant _DialogTextCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.currentNodeId != widget.session.currentNodeId) {
      _completed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.session.currentNode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_completed && node.choices.isEmpty) {
            widget.onAdvance();
          }
        },
        borderRadius: BorderRadius.circular(widget.compact ? 10 : 16),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xEE101B2F),
            borderRadius: BorderRadius.circular(widget.compact ? 10 : 16),
            border: Border.all(color: Colors.white24),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.compact ? 10 : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.speaker,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: widget.compact ? 14 : null,
                      ),
                ),
                SizedBox(height: widget.compact ? 5 : 8),
                TypewriterText(
                  text: node.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontSize: widget.compact ? 12 : null,
                      ),
                  onCompleted: () => setState(() => _completed = true),
                ),
                if (_completed && node.choices.isNotEmpty) ...[
                  SizedBox(height: widget.compact ? 8 : 16),
                  Wrap(
                    spacing: widget.compact ? 5 : 8,
                    runSpacing: widget.compact ? 5 : 8,
                    children: node.choices
                        .map(
                          (choice) => FilledButton.tonal(
                            onPressed: () {
                              unawaited(AudioManager.instance.playActionSfx());
                              widget.onChoiceSelected(choice);
                            },
                            child: Text(choice.label, style: TextStyle(fontSize: widget.compact ? 11 : 14)),
                          ),
                        )
                        .toList(),
                  ),
                ] else if (_completed) ...[
                  SizedBox(height: widget.compact ? 6 : 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '點擊繼續',
                      style: TextStyle(color: Colors.white54, fontSize: widget.compact ? 10 : 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
