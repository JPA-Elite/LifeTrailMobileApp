import 'dart:ui' show Rect, Offset;

import 'package:flame/components.dart';

/// Implemented by seats the player can sit on (benches, pews, chairs…).
/// [isSeat] lets the action button show "Sit" instead of the raw label.
/// [touchRect] is the world-space zone the player's feet must overlap for
/// the action button to appear (touch-only, no long-range popups).
abstract class Interactable {
  String get interactLabel;
  String get interactId;
  Vector2 get interactPosition;

  /// Overlap zone for touch detection. Defaults to a 96px box around the
  /// anchor so doors and small props trigger on body contact.
  Rect get touchRect => Rect.fromCenter(
    center: Offset(interactPosition.x, interactPosition.y),
    width: 96,
    height: 96,
  );

  bool get isSeat => false;
  Future<void> onInteract(LifeInteractContext ctx);
}

class LifeInteractContext {
  final void Function(String message) showMessage;

  /// Walk through a building door: swaps the town out for its interior.
  /// Awaitable so the scene has finished loading when the interact ends.
  final Future<void> Function(String locationId) enterLocation;

  /// Opens the action menu of the location the player is currently inside.
  final void Function(String locationId) openLocationMenu;

  /// Leaves the current interior and returns to the town.
  final Future<void> Function() exitLocation;

  /// Sitting on a bench/pew/chair: rests and restores a bit of energy.
  final void Function() sitDown;

  final void Function(String npcId) talkTo;
  final void Function(String itemId) pickUp;

  const LifeInteractContext({
    required this.showMessage,
    required this.enterLocation,
    required this.openLocationMenu,
    required this.exitLocation,
    required this.sitDown,
    required this.talkTo,
    required this.pickUp,
  });
}
