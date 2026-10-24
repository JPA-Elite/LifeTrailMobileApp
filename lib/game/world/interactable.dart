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

/// Opt-in marker for seats that should open the dedicated relaxation scene
/// (a full-screen, animated "sit and unwind" experience) instead of the
/// quick seat rest. Kept separate from [Interactable] so the town's doors,
/// NPCs and props don't have to implement it.
abstract interface class RelaxationSeat {
  /// True when tapping this seat opens the relaxation scene.
  bool get opensRelaxScene;
}

/// Opt-in marker for props that open the wardrobe scene (the home closet):
/// a full-screen dress-up room with five tees and five shorts.
abstract interface class Wardrobe {
  /// True when tapping this prop opens the wardrobe scene.
  bool get opensWardrobe;
}

/// Opt-in marker for the living-room television. The full-screen scene
/// offers movies, the internet, the news and cartoons; every selection is
/// an activity that spends energy and advances the clock.
abstract interface class Television {
  bool get opensTvScene;
}

/// Opt-in marker for the kitchen counter: opens the cooking/pantry scene.
abstract interface class CookingStation {
  bool get opensCookingScene;
}

/// Opt-in marker for the dining table: shows cooked meals and lets the
/// player sit down and eat one.
abstract interface class DiningTable {
  bool get opensDiningScene;
}

/// Opt-in marker for windows that can be looked through. The window view
/// repaints the neighbourhood for the current DayPeriod.
abstract interface class WindowView {
  bool get opensWindowView;
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

  /// Sleeping in a bed: fades to black and wakes up next morning at 07:00
  /// with full energy (wired in GameScreen).
  final void Function() sleepInBed;

  /// Using an ATM in the town: opens the withdraw dialog.
  final void Function() useAtm;

  final void Function(String npcId) talkTo;
  final void Function(String itemId) pickUp;

  const LifeInteractContext({
    required this.showMessage,
    required this.enterLocation,
    required this.openLocationMenu,
    required this.exitLocation,
    required this.sitDown,
    required this.sleepInBed,
    required this.useAtm,
    required this.talkTo,
    required this.pickUp,
  });
}
