import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'map_data.dart';

/// Signal phase at one highway × cross-street junction.
enum LightPhase { green, yellow, red }

/// What a vehicle needs from the town: signal phases, crosswalk
/// occupancy (player on the zebra) and the gap to the vehicle ahead.
/// Implemented by TownWorld; kept as an interface so this file has no
/// import cycle back into town_world.dart.
abstract class TrafficHost {
  LightPhase phaseAtJunction(int index);
  bool crossingBlocked(int index);

  /// Distance from the vehicle's front bumper to the nearest pedestrian
  /// or player ahead in its lane (null when the lane ahead is clear).
  /// Wanderers stick to sidewalks, so this only fires for genuine
  /// jaywalking/crossing — never a town-wide freeze.
  double? pedestrianAhead(VehicleComponent self);

  /// Bumper gap to the nearest vehicle ahead in the same lane.
  double? gapAhead(VehicleComponent self);

  /// Speed of that vehicle ahead (for smooth following).
  double? speedAhead(VehicleComponent self);
}

/// Town-wide signal timing. Each junction runs green → yellow → red on
/// a shared period with a staggered offset, so lights don't flip together.
class TrafficSystem {
  static const double period = 12.0;
  static const double greenT = 7.0;
  static const double yellowT = 1.5;

  final List<double> offsets;
  double t = 0;

  TrafficSystem({List<double>? offsets})
    : offsets = offsets ?? const [0.0, 3.0, 6.0, 9.0];

  void update(double dt) {
    t += dt;
  }

  LightPhase phaseAt(int junction) {
    final local = (t + offsets[junction % offsets.length]) % period;
    if (local < greenT) return LightPhase.green;
    if (local < greenT + yellowT) return LightPhase.yellow;
    return LightPhase.red;
  }
}

enum VehicleKind { car, bicycle }

/// A car or bicycle cruising its highway lane. Stops for red/yellow
/// signals, for the player on the crosswalk, and for the vehicle ahead;
/// wraps around the world edges. Never blocks the player physically
/// (roads stay walkable) — the stop behavior is the interaction.
class VehicleComponent extends PositionComponent {
  final TrafficHost host;
  final VehicleKind kind;
  final double highwayTop;
  final int junction;
  final int dir; // +1 eastbound, -1 westbound.
  final double cruiseSpeed;
  final Color color;

  double speed = 0;

  VehicleComponent({
    required this.host,
    required this.kind,
    required this.highwayTop,
    required this.junction,
    required this.dir,
    required Vector2 spawn,
    required this.cruiseSpeed,
    required this.color,
  }) : super(
         position: spawn.clone(),
         size: kind == VehicleKind.car
             ? Vector2(120, 52)
             : Vector2(76, 22),
         anchor: Anchor.center,
         priority: 50,
       ) {
    // Stagger rolling starts so traffic doesn't launch as one convoy.
    speed = cruiseSpeed * (0.4 + 0.6 * _kRandom.nextDouble());
  }

  static final Random _kRandom = Random();

  double get halfLen => size.x / 2;

  double get _accel => kind == VehicleKind.car ? 170 : 95;
  double get _brake => kind == VehicleKind.car ? 400 : 260;

  @override
  void update(double dt) {
    super.update(dt);

    var target = cruiseSpeed;
    double? holdAt; // max forward step: stop lines and people cap motion.

    // 0. Pedestrian / player in this lane ahead: halt before reaching
    // them, then roll again once the lane is clear.
    final pedDist = host.pedestrianAhead(this);
    if (pedDist != null && pedDist < 300) {
      target = 0;
      holdAt = pedDist - 24;
    }

    // 1. Signal + crosswalk: must halt behind the stop line.
    final stopX = stopLineX(dir);
    final frontX = position.x + dir * halfLen;
    final distToLine = (stopX - frontX) * dir;
    final blocked =
        host.phaseAtJunction(junction) != LightPhase.green ||
        host.crossingBlocked(junction);
    if (blocked && distToLine > -12 && distToLine < 300) {
      target = 0;
    }

    // 2. Car following: match the leader's speed, full stop when close.
    final gap = host.gapAhead(this);
    if (gap != null && gap < 220) {
      target = min(target, host.speedAhead(this) ?? 0);
      if (gap < 90) target = 0;
    }

    // 3. Ease toward target, then roll. Never cross a stop line or a
    // person: both cap the forward step.
    if (target < speed) {
      speed = max(0.0, speed - _brake * dt);
    } else {
      speed = min(target, speed + _accel * dt);
    }
    var step = dir * speed * dt;
    double? cap;
    if (target == 0 && blocked && distToLine > -12 && distToLine < 300) {
      cap = distToLine - 6;
    }
    if (holdAt != null && (cap == null || holdAt < cap)) cap = holdAt;
    if (cap != null) {
      if (step * dir > cap) {
        step = dir * max(0.0, cap);
        if (cap <= 0) speed = 0;
      }
    }
    position.x += step;

    // Wrap around the world edges.
    if (dir > 0 && position.x - halfLen > kWorldWidth + 80) {
      position.x = -halfLen - 80;
    } else if (dir < 0 && position.x + halfLen < -80) {
      position.x = kWorldWidth + halfLen + 80;
    }
  }

  @override
  void render(Canvas canvas) {
    // Mirror westbound so the front always points at travel direction.
    canvas.save();
    if (dir < 0) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    if (kind == VehicleKind.car) {
      _renderCar(canvas);
    } else {
      _renderBicycle(canvas);
    }
    canvas.restore();
  }

  void _renderCar(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    // Wheels.
    final wheel = Paint()..color = const Color(0xFF1F1A17);
    for (final wx in [w * 0.22, w * 0.78]) {
      for (final wy in [-4.0, h - 6.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(wx - 13, wy, 26, 10),
            const Radius.circular(4),
          ),
          wheel,
        );
      }
    }
    // Body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(13),
      ),
      Paint()..color = color,
    );
    // Roof + windshield.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.3, 7, w * 0.34, h - 14),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFF2B3B4E).withValues(alpha: 0.85),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.62, 9, 10, h - 18),
      Paint()..color = const Color(0xFFA8DADC).withValues(alpha: 0.9),
    );
    // Headlights + taillights.
    final lamp = Paint()..color = const Color(0xFFFFF3D6);
    canvas.drawCircle(Offset(w - 4, 10), 4, lamp);
    canvas.drawCircle(Offset(w - 4, h - 10), 4, lamp);
    final tail = Paint()..color = const Color(0xFFC0392B);
    canvas.drawCircle(const Offset(4, 10), 3.5, tail);
    canvas.drawCircle(Offset(4, h - 10), 3.5, tail);
  }

  void _renderBicycle(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final cy = h / 2;
    final wheel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF1F1A17);
    canvas.drawCircle(Offset(13, cy), 9, wheel);
    canvas.drawCircle(Offset(w - 13, cy), 9, wheel);
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawLine(Offset(13, cy), Offset(w / 2, cy - 4), frame);
    canvas.drawLine(Offset(w / 2, cy - 4), Offset(w - 13, cy), frame);
    canvas.drawLine(Offset(w / 2, cy - 4), Offset(w / 2 - 4, cy - 12), frame);
    // Rider.
    canvas.drawCircle(
      Offset(w / 2 - 2, cy - 18),
      6,
      Paint()..color = const Color(0xFFF2C9A4),
    );
    canvas.drawLine(
      Offset(w / 2 - 2, cy - 12),
      Offset(w / 2 + 2, cy - 3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF4A86E8),
    );
  }
}

/// A signal pole at one junction corner. Purely visual (non-solid);
/// the phase comes from the host's traffic system.
class TrafficLightProp extends PositionComponent {
  final TrafficHost host;
  final int junction;

  TrafficLightProp({
    required this.host,
    required this.junction,
    required Vector2 at,
  }) : super(
         position: at.clone(),
         size: Vector2(20, 76),
         anchor: Anchor.bottomCenter,
         priority: 55,
       );

  @override
  void render(Canvas canvas) {
    final phase = host.phaseAtJunction(junction);
    // Pole.
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 3, 18, 6, size.y - 18),
      Paint()..color = const Color(0xFF4A4A4A),
    );
    // Head box.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, 34),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF1F1A17),
    );
    // Lamps: red on top, yellow middle, green bottom.
    final lamps = [LightPhase.red, LightPhase.yellow, LightPhase.green];
    for (var i = 0; i < 3; i++) {
      final on = phase == lamps[i];
      final c = switch (lamps[i]) {
        LightPhase.red => const Color(0xFFE06666),
        LightPhase.yellow => const Color(0xFFFFD966),
        LightPhase.green => const Color(0xFF6AA84F),
      };
      canvas.drawCircle(
        Offset(size.x / 2, 6 + i * 11),
        4.5,
        Paint()..color = on ? c : c.withValues(alpha: 0.25),
      );
    }
    if (phase == LightPhase.green) {
      canvas.drawCircle(
        Offset(size.x / 2, 28),
        7,
        Paint()..color = const Color(0xFF6AA84F).withValues(alpha: 0.3),
      );
    }
  }
}
