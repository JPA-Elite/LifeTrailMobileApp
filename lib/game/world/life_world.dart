import 'package:flame/components.dart';
import 'interactable.dart';

/// A scene the player can walk around in: either the town map or the inside
/// of one of its buildings.
///
/// Both worlds expose the same surface so [LifeGame] can move the player
/// between them without caring which one is active.
abstract class LifeWorld extends World {
  /// Size of the walkable area, used to clamp the player and the camera.
  Vector2 get worldSize;

  /// Everything the player collides with (buildings, walls, props).
  List<PositionComponent> solidBounds();

  /// Interactables that are not solids, e.g. interior doorways. NPC markers
  /// are tracked separately because they are spawned dynamically.
  List<Interactable> interactables() => const [];
}
