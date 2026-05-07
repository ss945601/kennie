import 'dart:ui';

abstract interface class InteractableEntity {
  String get interactionLabel;
  Rect get interactionBounds;
  Future<void> interact();
}
