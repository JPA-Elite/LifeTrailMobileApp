import 'package:flame/components.dart';

abstract class Interactable {
  String get interactLabel;
  String get interactId;
  Vector2 get interactPosition;
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

  final void Function(String npcId) talkTo;
  final void Function(String itemId) pickUp;

  const LifeInteractContext({
    required this.showMessage,
    required this.enterLocation,
    required this.openLocationMenu,
    required this.exitLocation,
    required this.talkTo,
    required this.pickUp,
  });
}
