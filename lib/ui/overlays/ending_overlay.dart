import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/rpg_game.dart';

class EndingOverlay extends StatefulWidget {
  const EndingOverlay({super.key, required this.game});

  final RpgGame game;

  @override
  State<EndingOverlay> createState() => _EndingOverlayState();
}

class _EndingOverlayState extends State<EndingOverlay> {
  bool _isFading = false;
  bool _hasTriggeredFinish = false;
  Timer? _timer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startEndingTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEndingTimer() {
    _timer = Timer(const Duration(seconds: 4), _beginFadeOut);
  }

  void _beginFadeOut() {
    if (!mounted || _hasTriggeredFinish) {
      return;
    }
    setState(() {
      _isFading = true;
      _hasTriggeredFinish = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 800), widget.game.controller.finishEndingOverlay);
  }

  void _skipEnding() {
    _timer?.cancel();
    if (_hasTriggeredFinish) {
      return;
    }
    _beginFadeOut();
  }

  KeyEventResult _handleKey(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      _skipEnding();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final endingImage = widget.game.controller.endingImageAsset;
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipEnding,
        child: AnimatedOpacity(
          opacity: _isFading ? 0 : 1,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black,
                padding: const EdgeInsets.all(30.0),
                child: endingImage != null
                    ? Image.asset(
                        endingImage,
                        fit: BoxFit.contain,
                      )
                    : const SizedBox.shrink(),
              ),
              Container(
                color: Colors.black.withOpacity(0.05),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '點擊畫面或按下空白鍵跳過',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
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
