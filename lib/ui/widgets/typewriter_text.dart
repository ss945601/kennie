import 'dart:async';

import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charactersPerTick = 2,
    this.tick = const Duration(milliseconds: 22),
    this.onCompleted,
  });

  final String text;
  final TextStyle? style;
  final int charactersPerTick;
  final Duration tick;
  final VoidCallback? onCompleted;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  int _visibleCharacters = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _restart();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get isComplete => _visibleCharacters >= widget.text.length;

  void completeImmediately() {
    _timer?.cancel();
    setState(() => _visibleCharacters = widget.text.length);
    widget.onCompleted?.call();
  }

  void _restart() {
    _timer?.cancel();
    _visibleCharacters = 0;
    if (widget.text.isEmpty) {
      widget.onCompleted?.call();
      return;
    }
    _timer = Timer.periodic(widget.tick, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _visibleCharacters = (_visibleCharacters + widget.charactersPerTick)
            .clamp(0, widget.text.length);
      });
      if (isComplete) {
        timer.cancel();
        widget.onCompleted?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.text.substring(0, _visibleCharacters.clamp(0, widget.text.length));
    return Text(
      visibleText,
      style: widget.style,
    );
  }
}
