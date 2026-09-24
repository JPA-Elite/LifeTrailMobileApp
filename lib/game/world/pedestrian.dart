import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../player/stick_figure.dart';

/// A townsperson who wanders the sidewalks on their own.
///
/// Movement, like the player's, is resolved against the world's solids by
/// [TownWorld], which repaths anyone who walks into an obstacle.
class Pedestrian extends PositionComponent {
  static const int renderPriority = 40;
  static const double kHeight = 84;

  final Random random;
  final Color shirt;
  final Color skin;
  final Color hair;
  final double walkSpeed;

  /// Position at the start of the current frame, for stable collision.
  final Vector2 previousPosition = Vector2.zero();

  Vector2 target;

  double _phase = 0;
  double _stride = 0;
  double _idle = 0;
  double _facing = 1;

  Pedestrian({
    required Vector2 spawn,
    required Vector2 target,
    required this.random,
    required this.shirt,
    this.skin = const Color(0xFFF2C9A4),
    this.hair = const Color(0xFF3E2C22),
    this.walkSpeed = 70,
  }) : target = target.clone(),
       super(
         position: spawn,
         size: Vector2(kHeight * 44 / 96, kHeight),
         anchor: Anchor.bottomCenter,
         priority: renderPriority,
       ) {
    previousPosition.setFrom(spawn);
  }

  bool get hasArrived => position.distanceTo(target) < 14;

  /// Sends this townsperson somewhere new inside one of [bands].
  void pickTarget(List<Rect> bands) {
    if (bands.isEmpty) return;
    final band = bands[random.nextInt(bands.length)];
    target = Vector2(
      band.left + random.nextDouble() * band.width,
      band.top + random.nextDouble() * band.height,
    );
  }

  /// Stops walking and settles into a standing pose (used when there is
  /// nowhere to go, e.g. while blocked).
  void waitABeat() {
    target = position.clone();
  }

  @override
  void update(double dt) {
    previousPosition.setFrom(position);

    final toTarget = target - position;
    final moving = toTarget.length > 10;
    if (moving) {
      final direction = toTarget.normalized();
      // Ease the last few pixels so they do not overshoot their target.
      final step = walkSpeed * dt;
      position += direction * (step > toTarget.length ? toTarget.length : step);
      if (direction.x.abs() > 0.15) {
        _facing = direction.x >= 0 ? 1 : -1;
      }
      _phase += dt * 8.4;
    }

    final wanted = moving ? 1.0 : 0.0;
    _stride += (wanted - _stride) * (dt * 8).clamp(0.0, 1.0);
    _idle += dt * 2.2 + (moving ? 0 : dt);

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
      shirt: shirt,
      skin: skin,
      hair: hair,
    );
  }
}
