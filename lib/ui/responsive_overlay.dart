import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OverlayUiConfig {
  const OverlayUiConfig._({
    required this.size,
    required this.touchControls,
  });

  final Size size;
  final bool touchControls;

  static OverlayUiConfig of(
    BuildContext context, {
    bool enableTouchHeuristics = false,
  }) {
    return OverlayUiConfig._(
      size: MediaQuery.sizeOf(context),
      touchControls: enableTouchHeuristics && shouldShowTouchControls(context),
    );
  }

  static bool shouldShowTouchControls(BuildContext context) {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return true;
    }
    if (kIsWeb) {
      return MediaQuery.sizeOf(context).shortestSide < 900;
    }
    return false;
  }

  bool get compact => touchControls || size.height < 560 || size.width < 900;

  bool get stackedLayout => size.width < 980;

  double get compactScale {
    if (!compact) {
      return 1;
    }
    if (touchControls) {
      if (size.height < 420 || size.width < 740) {
        return 0.78;
      }
      return 0.86;
    }
    if (size.height < 520 || size.width < 820) {
      return 0.9;
    }
    return 0.95;
  }

  double value(double normal, {double? compactValue}) {
    final base = compact ? (compactValue ?? normal) : normal;
    return compact ? base * compactScale : base;
  }

  double font(double normal, {double? compactValue}) {
    final base = compact ? (compactValue ?? normal) : normal;
    return compact ? base * compactScale : base;
  }

  double radius(double normal, {double? compactValue}) {
    final base = compact ? (compactValue ?? normal) : normal;
    return compact ? base * compactScale : base;
  }

  EdgeInsets all(double normal, {double? compactValue}) {
    return EdgeInsets.all(value(normal, compactValue: compactValue));
  }

  EdgeInsets symmetric({
    required double horizontal,
    required double vertical,
    double? compactHorizontal,
    double? compactVertical,
  }) {
    return EdgeInsets.symmetric(
      horizontal: value(horizontal, compactValue: compactHorizontal),
      vertical: value(vertical, compactValue: compactVertical),
    );
  }
}