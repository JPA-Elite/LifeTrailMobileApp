import 'package:flame/components.dart';

abstract class Interactable {
  String get interactLabel;
  String get interactId;
  Vector2 get interactPosition;
  Future<void> onInteract(LifeInteractContext ctx);
}

class LifeInteractContext {
  final void Function(String message) showMessage;
  final void Function(String locationId) enterLocation;
  final void Function(String npcId) talkTo;
  final void Function(String itemId) pickUp;

  const LifeInteractContext({
    required this.showMessage,
    required this.enterLocation,
    required this.talkTo,
    required this.pickUp,
  });
}
