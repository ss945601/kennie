import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state_controller.dart';
import '../../state/models/game_models.dart';
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
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Consumer<GameStateController>(
          builder: (context, controller, _) {
            final session = controller.activeDialog;
            if (session == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: _DialogTextCard(
                key: _dialogKey,
                session: session,
                onAdvance: controller.advanceDialog,
                onChoiceSelected: controller.chooseDialogChoice,
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
  });

  final DialogSession session;
  final VoidCallback onAdvance;
  final ValueChanged<DialogChoice> onChoiceSelected;

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
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xEE101B2F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.speaker,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                TypewriterText(
                  text: node.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                  onCompleted: () => setState(() => _completed = true),
                ),
                if (_completed && node.choices.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: node.choices
                        .map(
                          (choice) => FilledButton.tonal(
                            onPressed: () => widget.onChoiceSelected(choice),
                            child: Text(choice.label),
                          ),
                        )
                        .toList(),
                  ),
                ] else if (_completed) ...[
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '點擊繼續',
                      style: TextStyle(color: Colors.white54),
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
