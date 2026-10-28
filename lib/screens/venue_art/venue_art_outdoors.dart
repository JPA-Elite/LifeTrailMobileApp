import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'venue_art_base.dart';

// ---------------------------------------------------------------------------
// Amusement park, beach and fishing pier.
// ---------------------------------------------------------------------------

class AmusementArtist extends VenueArtist {
  AmusementArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    vertical(c, Rect.fromLTWH(0, 0, w, h * 0.66), [
      const Color(0xFF120E2A),
      const Color(0xFF4A2A5E),
      const Color(0xFF8A4A6A),
    ], const [0, 0.55, 1]);
    // Stars.
    final r = math.Random(4);
    for (var i = 0; i < 46; i++) {
      final x = r.nextDouble() * w;
      final y = r.nextDouble() * h * 0.42;
      final twinkle = 0.4 + 0.6 * ((math.sin(ambient * 9 + i) + 1) / 2);
      circle(c, Offset(x, y), (0.7 + r.nextDouble() * 1.4) * u,
          Colors.white.withAlpha((150 * twinkle).round()));
    }
    // Ground.
    vertical(c, Rect.fromLTWH(0, h * 0.66, w, h * 0.34), [
      const Color(0xFF3A2448),
      const Color(0xFF1A1024),
    ]);

    // Ferris wheel.
    final hub = Offset(w * 0.62, h * 0.36);
    final radius = math.min(w * 0.17, h * 0.27);
    line(c, hub + Offset(-radius * 0.46, radius * 1.15),
        hub + Offset(0, 0), const Color(0xFF6B5A7A), u * 5);
    line(c, hub + Offset(radius * 0.46, radius * 1.15),
        hub + Offset(0, 0), const Color(0xFF6B5A7A), u * 5);
    line(c, hub + Offset(-radius * 0.46, radius * 1.15),
        hub + Offset(radius * 0.46, radius * 1.15), const Color(0xFF7E6B8E), u * 3);
    c.drawCircle(
      hub,
      radius,
      Paint()
        ..color = const Color(0xFFB9A0C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 3,
    );
    c.drawCircle(
      hub,
      radius * 0.82,
      Paint()
        ..color = const Color(0x66B9A0C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 1.5,
    );
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2 + ambient * 0.18;
      final p = hub + Offset(math.cos(a), math.sin(a)) * radius;
      line(c, hub, p, const Color(0xFF8F7AA0), u * 1.6);
      // Cabin.
      rrect(c, p.dx - u * 8, p.dy - u * 3, u * 16, u * 12, u * 3,
          i.isEven ? const Color(0xFFFF9BD1) : const Color(0xFFFFD36E));
      line(c, Offset(p.dx, p.dy - u * 3), Offset(p.dx, p.dy - u * 8),
          const Color(0xFF8F7AA0), u * 1.4);
      radialGlow(c, p, u * 18, const Color(0xFFFFE27A), 0.2);
    }
    circle(c, hub, u * 10, const Color(0xFFFFE27A));
    radialGlow(c, hub, radius * 0.55, const Color(0xFFFFD36E), 0.22);

    // Coaster track on the left.
    final track = Path()
      ..moveTo(0, h * 0.52)
      ..quadraticBezierTo(w * 0.08, h * 0.28, w * 0.18, h * 0.48)
      ..quadraticBezierTo(w * 0.26, h * 0.68, w * 0.36, h * 0.54);
    path(c, track, const Color(0xFFFF9BD1), u * 3);
    path(c, track.shift(Offset(0, u * 7)), const Color(0xFF9DE1FF), u * 3);
    for (var i = 0; i < 8; i++) {
      final t = i / 7;
      final x = w * (0.02 + t * 0.32);
      final y = h * (0.40 + math.sin(t * math.pi * 2) * 0.10);
      line(c, Offset(x, y), Offset(x, h * 0.62), const Color(0xFF5A4A6A), u * 2);
    }
    // Coaster cars.
    final carX = w * (0.06 + (math.sin(ambient * math.pi * 2) + 1) * 0.10);
    final carY = h * 0.44;
    for (var i = 0; i < 3; i++) {
      rrect(c, carX + i * u * 18, carY - u * 4, u * 16, u * 10, u * 3,
          const Color(0xFFFFD36E));
      circle(c, Offset(carX + i * u * 18 + u * 4, carY + u * 8), u * 3,
          const Color(0xFF3A2448));
      circle(c, Offset(carX + i * u * 18 + u * 12, carY + u * 8), u * 3,
          const Color(0xFF3A2448));
    }

    // Midway stalls.
    for (var i = 0; i < 3; i++) {
      final x = w * (0.06 + i * 0.18);
      final y = h * 0.68;
      rect(c, x, y, w * 0.14, h * 0.16, const Color(0xFF4A2E52));
      // Striped awning.
      for (var s = 0; s < 7; s++) {
        poly(c, [
          Offset(x + w * 0.14 * s / 7, y - h * 0.01),
          Offset(x + w * 0.14 * (s + 1) / 7, y - h * 0.01),
          Offset(x + w * 0.14 * (s + 1) / 7 - u * 4, y + h * 0.05),
          Offset(x + w * 0.14 * s / 7 + u * 4, y + h * 0.05),
        ], s.isEven ? const Color(0xFFE06666) : const Color(0xFFF2E6D0));
      }
      // Counter and prizes.
      rect(c, x, y + h * 0.10, w * 0.14, u * 5, const Color(0xFF8A6A4B));
      for (var k = 0; k < 3; k++) {
        circle(c, Offset(x + w * (0.03 + k * 0.04), y + h * 0.085), u * 6,
            [
              const Color(0xFFFFD36E), const Color(0xFFFF9BD1),
              const Color(0xFF9DE1FF),
            ][k]);
      }
      for (var b = 0; b < 4; b++) {
        circle(c, Offset(x + w * 0.14 * (b + 0.5) / 4, y + h * 0.05), u * 2.2,
            const Color(0xFFFFE27A));
        radialGlow(c, Offset(x + w * 0.14 * (b + 0.5) / 4, y + h * 0.05),
            u * 10, const Color(0xFFFFE27A), 0.2);
      }
    }

    // String bulbs across the midway.
    final wire = Path()
      ..moveTo(0, h * 0.60)
      ..quadraticBezierTo(w * 0.5, h * 0.70, w, h * 0.58);
    path(c, wire, const Color(0x663A2A44), u * 1.4);
    for (var i = 0; i < 15; i++) {
      final t = (i + 0.5) / 15;
      final x = w * t;
      final y = h * (0.60 + math.sin(t * math.pi) * 0.10);
      circle(c, Offset(x, y), u * 3, const Color(0xFFFFE27A));
      radialGlow(c, Offset(x, y), u * 12, const Color(0xFFFFE27A), 0.25);
    }

    // Cotton candy cart.
    final cx = w * 0.82;
    final cy = h * 0.82;
    rrect(c, cx - u * 30, cy - u * 26, u * 60, u * 30, u * 4,
        const Color(0xFFE8A0C4));
    circle(c, Offset(cx - u * 16, cy + u * 8), u * 10, const Color(0xFF3A2448));
    circle(c, Offset(cx + u * 16, cy + u * 8), u * 10, const Color(0xFF3A2448));
    line(c, Offset(cx, cy - u * 26), Offset(cx, cy - u * 60),
        const Color(0xFFE8E0D0), u * 2);
    for (var i = 0; i < 3; i++) {
      circle(c, Offset(cx + (i - 1) * u * 11, cy - u * 68), u * 15,
          const Color(0xFFFFB6D9));
    }
    radialGlow(c, Offset(cx, cy - u * 66), u * 46,
        const Color(0xFFFF9BD1), 0.2);
  }
}

class BeachArtist extends VenueArtist {
  BeachArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    vertical(c, Rect.fromLTWH(0, 0, w, h * 0.52), [
      const Color(0xFF5E8FC4),
      const Color(0xFFFFB27A),
      const Color(0xFFFFE0A6),
    ], const [0, 0.62, 1]);
    final sun = Offset(w * 0.70, h * 0.31);
    radialGlow(c, sun, w * 0.20, const Color(0xFFFFE7B0), 0.65);
    circle(c, sun, h * 0.055, const Color(0xFFFFF6DE));
    // Clouds.
    for (final p in const [Offset(0.20, 0.14), Offset(0.45, 0.10), Offset(0.58, 0.20)]) {
      oval(c, Rect.fromCenter(center: Offset(w * p.dx, h * p.dy),
          width: w * 0.15, height: h * 0.035), const Color(0x44FFFFFF));
    }
    // Distant headland.
    poly(c, [
      Offset(0, h * 0.52),
      Offset(0, h * 0.46),
      Offset(w * 0.10, h * 0.42),
      Offset(w * 0.18, h * 0.47),
      Offset(w * 0.26, h * 0.52),
    ], const Color(0xFF5A6B6E));

    // Sea.
    vertical(c, Rect.fromLTWH(0, h * 0.52, w, h * 0.20), [
      const Color(0xFF2E7E9E),
      const Color(0xFF5FB4C4),
    ]);
    // Sun glitter path.
    for (var i = 0; i < 14; i++) {
      final t = i / 14;
      final y = h * (0.53 + t * 0.19);
      final wobble = math.sin(ambient * math.pi * 4 + i) * u * 4;
      line(c, Offset(w * 0.70 - u * (20 + t * 50) + wobble, y),
          Offset(w * 0.70 + u * (20 + t * 50) + wobble, y),
          const Color(0x88FFE7B0), u * 2);
    }
    // Waves.
    for (var i = 0; i < 4; i++) {
      final y = h * (0.56 + i * 0.045);
      final offset = math.sin(ambient * math.pi * 2 + i) * u * 12;
      path(c, Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(w * 0.25 + offset, y - u * 6, w * 0.5, y)
        ..quadraticBezierTo(w * 0.75 - offset, y + u * 6, w, y),
          const Color(0x88E8FAFF), u * 2);
    }
    // Foam line.
    path(c, Path()
      ..moveTo(0, h * 0.70)
      ..quadraticBezierTo(w * 0.25, h * 0.66, w * 0.5, h * 0.70)
      ..quadraticBezierTo(w * 0.75, h * 0.74, w, h * 0.69),
        const Color(0xCCF2F7F0), u * 3);
    // Sand.
    vertical(c, Rect.fromLTWH(0, h * 0.70, w, h * 0.30), [
      const Color(0xFFE8C89A),
      const Color(0xFFB98A5E),
    ]);
    // Footprints.
    for (var i = 0; i < 8; i++) {
      final x = w * (0.12 + i * 0.035);
      final y = h * (0.78 + (i % 2) * 0.03 + i * 0.012);
      oval(c, Rect.fromCenter(center: Offset(x, y), width: u * 7, height: u * 12),
          const Color(0x33A9713F));
    }

    // Umbrella.
    final base = Offset(w * 0.30, h * 0.86);
    line(c, base, base - Offset(0, h * 0.36), const Color(0xFF8A6A4B), u * 4);
    for (var i = 0; i < 7; i++) {
      final a0 = math.pi + i / 7 * math.pi;
      final a1 = math.pi + (i + 1) / 7 * math.pi;
      final p0 = base - Offset(0, h * 0.36) + Offset(math.cos(a0), math.sin(a0)) * u * 95;
      final p1 = base - Offset(0, h * 0.36) + Offset(math.cos(a1), math.sin(a1)) * u * 95;
      poly(c, [
        base - Offset(0, h * 0.36),
        p0,
        p1,
      ], i.isEven ? const Color(0xFFE06666) : const Color(0xFFF2E6D0));
    }
    // Towel.
    poly(c, [
      Offset(w * 0.42, h * 0.84),
      Offset(w * 0.55, h * 0.82),
      Offset(w * 0.58, h * 0.92),
      Offset(w * 0.44, h * 0.95),
    ], const Color(0xFF6FA8DC));
    for (var i = 0; i < 5; i++) {
      line(c, Offset(w * (0.43 + i * 0.03), h * 0.85),
          Offset(w * (0.45 + i * 0.03), h * 0.94), const Color(0x55FFFFFF), u * 2);
    }
    // Beach ball.
    circle(c, Offset(w * 0.62, h * 0.88), u * 14, const Color(0xFFF2E6D0));
    for (var i = 0; i < 3; i++) {
      final a = i / 3 * math.pi * 2 + ambient;
      poly(c, [
        Offset(w * 0.62, h * 0.88),
        Offset(w * 0.62, h * 0.88) + Offset(math.cos(a), math.sin(a)) * u * 14,
        Offset(w * 0.62, h * 0.88) + Offset(math.cos(a + 0.6), math.sin(a + 0.6)) * u * 14,
      ], [
        const Color(0xFFE06666), const Color(0xFF6FA8DC), const Color(0xFFFFD966),
      ][i]);
    }

    // Palm tree.
    final px = w * 0.08;
    final py = h * 0.80;
    path(c, Path()
      ..moveTo(px, py)
      ..quadraticBezierTo(px + u * 20, py - h * 0.20, px + u * 4, py - h * 0.36),
        const Color(0xFF6B4A2E), u * 6);
    for (var i = 0; i < 7; i++) {
      final a = -math.pi / 2 + (i - 3) * 0.34;
      final end = Offset(px + u * 4, py - h * 0.36) +
          Offset(math.cos(a) * u * 80, math.sin(a) * u * 40);
      path(c, Path()
        ..moveTo(px + u * 4, py - h * 0.36)
        ..quadraticBezierTo(
          px + u * 4 + math.cos(a) * u * 44,
          py - h * 0.36 + math.sin(a) * u * 18 - u * 16,
          end.dx,
          end.dy,
        ), const Color(0xFF3F7A40), u * 7);
    }
    circle(c, Offset(px + u * 4, py - h * 0.34), u * 7, const Color(0xFF8A5A34));

    // Gulls.
    final gull = Paint()
      ..color = const Color(0xBB2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 2;
    for (final p in const [Offset(0.40, 0.16), Offset(0.47, 0.13), Offset(0.54, 0.18)]) {
      final x = w * p.dx + math.sin(ambient * 5 + p.dx * 10) * u * 5;
      final y = h * p.dy;
      c.drawPath(Path()
        ..moveTo(x - u * 8, y)
        ..quadraticBezierTo(x - u * 3, y - u * 6, x, y)
        ..quadraticBezierTo(x + u * 3, y - u * 6, x + u * 8, y), gull);
    }
  }
}

class FishingArtist extends VenueArtist {
  FishingArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    vertical(c, Rect.fromLTWH(0, 0, w, h * 0.54), [
      const Color(0xFF2A2A4E),
      const Color(0xFFC46A6A),
      const Color(0xFFFFC98A),
    ], const [0, 0.58, 1]);
    final sun = Offset(w * 0.78, h * 0.38);
    radialGlow(c, sun, w * 0.16, const Color(0xFFFFD27A), 0.55);
    circle(c, sun, h * 0.035, const Color(0xFFFFE7B0));
    // Mountains.
    poly(c, [
      Offset(0, h * 0.54),
      Offset(0, h * 0.44),
      Offset(w * 0.12, h * 0.34),
      Offset(w * 0.24, h * 0.45),
      Offset(w * 0.36, h * 0.38),
      Offset(w * 0.50, h * 0.48),
      Offset(w * 0.66, h * 0.40),
      Offset(w * 0.82, h * 0.47),
      Offset(w, h * 0.41),
      Offset(w, h * 0.54),
    ], const Color(0xFF3A3A5A));
    poly(c, [
      Offset(0, h * 0.54),
      Offset(0, h * 0.49),
      Offset(w * 0.16, h * 0.43),
      Offset(w * 0.32, h * 0.50),
      Offset(w * 0.48, h * 0.44),
      Offset(w * 0.64, h * 0.51),
      Offset(w * 0.84, h * 0.45),
      Offset(w, h * 0.50),
      Offset(w, h * 0.54),
    ], const Color(0xFF2A2A44));

    // Lake.
    vertical(c, Rect.fromLTWH(0, h * 0.54, w, h * 0.46), [
      const Color(0xFF2E5B6E),
      const Color(0xFF142E3A),
    ]);
    // Sun reflection.
    for (var i = 0; i < 16; i++) {
      final t = i / 16;
      final y = h * (0.55 + t * 0.25);
      final wobble = math.sin(ambient * math.pi * 4 + i) * u * 5;
      line(c, Offset(w * 0.78 - u * (16 + t * 44) + wobble, y),
          Offset(w * 0.78 + u * (16 + t * 44) + wobble, y),
          const Color(0x66FFD27A), u * 1.8);
    }
    // Ripples.
    for (var i = 0; i < 5; i++) {
      final y = h * (0.60 + i * 0.06);
      final off = math.sin(ambient * math.pi * 2 + i * 1.7) * u * 18;
      path(c, Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(w * 0.25 + off, y - u * 4, w * 0.5, y)
        ..quadraticBezierTo(w * 0.75 - off, y + u * 4, w, y),
          const Color(0x44CFF6FF), u * 1.6);
    }
    // Float and line.
    final floatPos = Offset(w * 0.46, h * (0.62 + math.sin(ambient * math.pi * 2) * 0.006));
    circle(c, floatPos, u * 6, const Color(0xFFE06666));
    circle(c, floatPos, u * 2.5, const Color(0xFFF2E6D0));
    path(c, Path()
      ..moveTo(w * 0.28, h * 0.42)
      ..quadraticBezierTo(w * 0.38, h * 0.52, floatPos.dx, floatPos.dy),
        const Color(0x66F2F7F0), u * 1);
    // Ripple around float.
    for (var i = 0; i < 3; i++) {
      final t = (ambient + i * 0.33) % 1;
      c.drawOval(
        Rect.fromCenter(center: floatPos + Offset(0, u * 7),
            width: u * (16 + t * 48), height: u * (5 + t * 14)),
        Paint()
          ..color = const Color(0x55E8FAFF).withAlpha(((1 - t) * 90).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 1.5,
      );
    }

    // Wooden pier in the foreground.
    poly(c, [
      Offset(w * 0.02, h),
      Offset(w * 0.14, h * 0.70),
      Offset(w * 0.62, h * 0.70),
      Offset(w * 0.82, h),
    ], const Color(0xFF6B4A32));
    for (var i = 0; i < 8; i++) {
      final t = i / 8;
      line(c, Offset(w * (0.14 + 0.48 * t / 1), h * (0.70 + 0.30 * t)),
          Offset(w * (0.82 - 0.20 * t), h * (0.70 + 0.30 * t)),
          const Color(0x554A3222), u * 2);
    }
    for (var i = 0; i < 6; i++) {
      final t = i / 5;
      line(c, Offset(w * (0.10 + t * 0.63), h * 0.70),
          Offset(w * (0.02 + t * 0.80), h),
          const Color(0x554A3222), u * 2);
    }
    // Posts in the water.
    for (final x in const [0.18, 0.40, 0.62]) {
      rect(c, w * x, h * 0.58, u * 8, h * 0.16, const Color(0xFF4A3222));
    }

    // Rod, tackle box, bucket.
    final rodBase = Offset(w * 0.64, h * 0.88);
    path(c, Path()
      ..moveTo(rodBase.dx, rodBase.dy)
      ..quadraticBezierTo(w * 0.56, h * 0.62, w * 0.30, h * 0.42),
        const Color(0xFF3A2A1A), u * 4);
    strokeCircle(c, Offset(w * 0.55, h * 0.72), u * 8, const Color(0xFFB9BEC2), u * 2);
    rrect(c, w * 0.70, h * 0.84, u * 52, u * 34, u * 4,
        const Color(0xFF5B6B4A));
    line(c, Offset(w * 0.70 + u * 10, h * 0.84), Offset(w * 0.70 + u * 42, h * 0.84),
        const Color(0xFF3A4A32), u * 3);
    // Bucket.
    poly(c, [
      Offset(w * 0.86, h * 0.84),
      Offset(w * 0.90, h * 0.84),
      Offset(w * 0.895, h * 0.94),
      Offset(w * 0.865, h * 0.94),
    ], const Color(0xFF8FA4A8));
    c.drawArc(
      Rect.fromCenter(center: Offset(w * 0.88, h * 0.84), width: u * 44, height: u * 20),
      math.pi, math.pi, false,
      Paint()
        ..color = const Color(0xFF6B7A7E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 2,
    );

    // Fireflies over the water.
    for (var i = 0; i < 12; i++) {
      final x = w * (0.08 + (i * 0.077) % 0.84);
      final y = h * (0.58 + math.sin(ambient * math.pi * 2 + i * 1.3) * 0.05 + (i % 3) * 0.035);
      circle(c, Offset(x, y), u * 1.6, const Color(0xCCFFE27A));
      radialGlow(c, Offset(x, y), u * 9, const Color(0xFFFFE27A), 0.3);
    }
  }
}
