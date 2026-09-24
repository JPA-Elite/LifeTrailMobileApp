import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// The shape an actor collides with: a small box at the feet, so tall figures
/// can stand in front of walls instead of being shoved away from them.
class FeetBody {
  final double halfWidth;
  final double halfHeight;

  const FeetBody({this.halfWidth = 18, this.halfHeight = 18});

  Rect rectAt(Vector2 position) => Rect.fromLTWH(
    position.x - halfWidth,
    position.y - halfHeight,
    halfWidth * 2,
    halfHeight * 2 + 2,
  );
}

/// Slides [position] out of [solids] by cancelling the movement into them,
/// one axis at a time.
///
/// [previous] is the position at the start of the frame. The old code pushed
/// actors to a fixed 26px offset from the solid's centre, which flipped
/// direction frame to frame and made the player shake whenever they touched a
/// building. Undoing only the blocked axis keeps contact stable: actors stop
/// dead against a wall and slide smoothly along it.
///
/// Returns true when the movement was blocked.
bool resolveFeetCollision({
  required Vector2 position,
  required Vector2 previous,
  required Iterable<PositionComponent> solids,
  FeetBody body = const FeetBody(),
}) {
  final rects = [for (final solid in solids) solid.toRect()];

  bool blocked(Vector2 p) {
    final rect = body.rectAt(p);
    for (final solid in rects) {
      if (rect.overlaps(solid)) return true;
    }
    return false;
  }

  var wasBlocked = false;

  // X first, using the previous Y, so diagonal movement slides along walls.
  if (blocked(Vector2(position.x, previous.y))) {
    position.x = previous.x;
    wasBlocked = true;
  }
  if (blocked(Vector2(position.x, position.y))) {
    position.y = previous.y;
    wasBlocked = true;
  }

  // Still overlapping (for example spawned inside something): nudge out the
  // shortest way instead of oscillating.
  for (var guard = 0; guard < 4 && blocked(position); guard++) {
    final feet = body.rectAt(position);
    Rect? target;
    var smallest = double.infinity;
    for (final solid in rects) {
      if (!feet.overlaps(solid)) continue;
      final push = [
        feet.right - solid.left,
        solid.right - feet.left,
        feet.bottom - solid.top,
        solid.bottom - feet.top,
      ].reduce(math.min);
      if (push < smallest) {
        smallest = push;
        target = solid;
      }
    }
    if (target == null) break;
    final now = body.rectAt(position);
    final options = <double>[
      now.right - target.left,
      target.right - now.left,
      now.bottom - target.top,
      target.bottom - now.top,
    ];
    final best = options.reduce(math.min);
    if (best == options[0]) {
      position.x -= best;
    } else if (best == options[1]) {
      position.x += best;
    } else if (best == options[2]) {
      position.y -= best;
    } else {
      position.y += best;
    }
  }

  return wasBlocked;
}
