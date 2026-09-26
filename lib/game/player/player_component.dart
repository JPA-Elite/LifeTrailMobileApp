import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../world/feet_collision.dart';
import 'stick_figure.dart';

/// The player: an articulated stick figure with a walk / run cycle.
class PlayerComponent extends PositionComponent {
  Vector2 moveInput = Vector2.zero();
  bool running = false;
  final double walkSpeed = 220;
  final double runSpeed = 360;

  static const double kWidth = 37;
  static const double kHeight = 82;

  /// Render above the scene. Without this the player is drawn *before* a
  /// freshly loaded room's floor and walls (they are added later), which made
  /// the stickman vanish whenever a building was entered.
  static const int renderPriority = 100;

  /// Position at the start of the current frame, used to resolve collisions
  /// without snapping or shaking.
  final Vector2 previousPosition = Vector2.zero();

  /// +1 faces right, -1 faces left.
  double _facing = 1;

  /// Walk cycle phase, in radians.
  double _phase = 0;

  /// Idle breathing phase.
  double _idle = 0;

  /// How much of the walk pose to apply: 0 = standing, 1 = full stride.
  double _stride = 0;

  PlayerComponent({required Vector2 spawn})
    : super(
        position: spawn,
        size: Vector2(kWidth, kHeight),
        anchor: Anchor.bottomCenter,
        priority: renderPriority,
      ) {
    previousPosition.setFrom(spawn);
  }

  double get speed => running ? runSpeed : walkSpeed;

  bool get isMoving => moveInput.length > 0.01;

  /// Small box around the feet: what collides with the world and interacts.
  ///
  /// Shares [FeetBody] with `resolveFeetCollision`, so the box used to detect
  /// touch (benches, doors, furniture) is exactly the box the world blocks
  /// with. They used to differ by 18px vertically, which left a gap no
  /// interact zone could ever reach — the bench "Sit" button never appeared.
  static const FeetBody feetBody = FeetBody();

  Rect get feetRect => feetBody.rectAt(position);

  @override
  void update(double dt) {
    previousPosition.setFrom(position);

    if (isMoving) {
      final direction = moveInput.normalized();
      position += direction * speed * dt;
      if (direction.x.abs() > 0.15) {
        _facing = direction.x >= 0 ? 1 : -1;
      }
      // Faster cadence while running.
      _phase += dt * (running ? 13.5 : 9.0);
    }

    final target = isMoving ? 1.0 : 0.0;
    _stride += (target - _stride) * math.min(1.0, dt * 12);
    _idle += dt * 2.2;

    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    drawStickFigure(
      canvas,
      width: size.x,
      height: size.y,
      phase: _phase,
      stride: _stride,
      facing: _facing,
      idle: _idle,
      running: running,
    );
  }
}
