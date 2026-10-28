import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'venue_art_base.dart';

// ---------------------------------------------------------------------------
// Hospital, restaurant, laundry, computer center and hotel lobby.
// ---------------------------------------------------------------------------

class HospitalArtist extends VenueArtist {
  HospitalArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    room(
      c,
      wallTop: const Color(0xFF243A42),
      wallBottom: const Color(0xFFB9D6D2),
      floorFar: const Color(0xFF7A9A98),
      floorNear: const Color(0xFF2E4444),
      horizon: 0.60,
    );
    tileFloor(c, far: const Color(0xFF7A9A98), near: const Color(0xFF2E4444),
        horizon: 0.60, columns: 8, rows: 4,
        lineColor: const Color(0x22000000));
    // Mint stripe and glossy reflection.
    rect(c, 0, h * 0.46, w, h * 0.035, const Color(0xFF3E8E83));
    rect(c, 0, h * 0.495, w, h * 0.008, const Color(0xFFA8DADC));
    poly(c, [
      Offset(w * 0.30, h * 0.62),
      Offset(w * 0.70, h * 0.62),
      Offset(w * 0.80, h * 0.82),
      Offset(w * 0.20, h * 0.82),
    ], const Color(0x10FFFFFF));

    // Fluorescent ceiling panels.
    for (var i = 0; i < 4; i++) {
      final x = w * (0.08 + i * 0.24);
      rrect(c, x, h * 0.035, w * 0.16, u * 8, u * 2,
          const Color(0xFFE8FFF8));
      radialGlow(c, Offset(x + w * 0.08, h * 0.08), u * 80,
          const Color(0xFFE8FFF8), 0.16);
    }

    // Reception desk.
    final dy = h * 0.56;
    rrect(c, w * 0.32, dy, w * 0.40, h * 0.19, u * 8,
        const Color(0xFF4F7370));
    rrect(c, w * 0.32, dy, w * 0.40, u * 12, u * 4,
        const Color(0xFFE8F4F0));
    rect(c, w * 0.325, dy + u * 12, w * 0.39, h * 0.03,
        const Color(0xFFA8DADC));
    // Monitor, keyboard, paperwork.
    rrect(c, w * 0.38, dy - u * 34, u * 44, u * 28, u * 3,
        const Color(0xFF2A3A40));
    rect(c, w * 0.39, dy - u * 28, u * 32, u * 18,
        const Color(0xFF7FE0C4));
    rrect(c, w * 0.380, dy + u * 4, u * 34, u * 8, u * 2,
        const Color(0xFFD9E8E4));
    rrect(c, w * 0.56, dy - u * 8, u * 30, u * 10, u * 1,
        const Color(0xFFF5F1E6));
    // Chair.
    rrect(c, w * 0.55, dy - u * 60, u * 36, u * 30, u * 8,
        const Color(0xFF2E4A4A));
    // Green cross sign.
    final crossC = Offset(w * 0.50, h * 0.20);
    radialGlow(c, crossC, u * 60, const Color(0xFF7FE0C4), 0.26);
    line(c, crossC - Offset(0, u * 20), crossC + Offset(0, u * 20),
        const Color(0xFF7FE0C4), u * 11);
    line(c, crossC - Offset(u * 20, 0), crossC + Offset(u * 20, 0),
        const Color(0xFF7FE0C4), u * 11);

    // Waiting chairs.
    for (var i = 0; i < 3; i++) {
      final x = w * (0.75 + i * 0.065);
      rrect(c, x, h * 0.66, w * 0.05, h * 0.08, u * 5,
          const Color(0xFF4A8F8A));
      rrect(c, x, h * 0.61, w * 0.05, h * 0.07, u * 5,
          const Color(0xFF6AA8A0));
      line(c, Offset(x + u * 4, h * 0.74), Offset(x + u * 4, h * 0.80),
          const Color(0xFF5B5B5B), u * 2);
      line(c, Offset(x + w * 0.046, h * 0.74), Offset(x + w * 0.046, h * 0.80),
          const Color(0xFF5B5B5B), u * 2);
    }
    // Wheelchair silhouette by the corridor.
    final wx = w * 0.18;
    final wy = h * 0.80;
    strokeCircle(c, Offset(wx, wy), u * 18, const Color(0xFF6B7A7A), u * 4);
    line(c, Offset(wx - u * 18, wy), Offset(wx + u * 18, wy),
        const Color(0xFF6B7A7A), u * 2);
    rrect(c, wx - u * 10, wy - u * 42, u * 20, u * 26, u * 6,
        const Color(0xFF6B7A7A));

    plant(c, Offset(w * 0.06, h * 0.68), 1.3);
    plant(c, Offset(w * 0.94, h * 0.68), 1.1);
  }
}

class RestaurantArtist extends VenueArtist {
  RestaurantArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    room(
      c,
      wallTop: const Color(0xFF2A1814),
      wallBottom: const Color(0xFF6B3A2E),
      floorFar: const Color(0xFF5B3E2E),
      floorNear: const Color(0xFF24140E),
      horizon: 0.60,
    );
    plankFloor(c, far: const Color(0xFF5B3E2E), near: const Color(0xFF24140E),
        horizon: 0.60);

    // Big window onto the evening street.
    windowBox(
      c,
      Rect.fromLTWH(w * 0.61, h * 0.12, w * 0.30, h * 0.38),
      skyTop: const Color(0xFF262B4A),
      skyBottom: const Color(0xFFB25E5E),
      curtains: true,
      mullions: 2,
    );
    for (var i = 0; i < 9; i++) {
      final x = w * (0.64 + (i % 5) * 0.055);
      final y = h * (0.30 + (i ~/ 5) * 0.07);
      rect(c, x, y, u * 8, u * 8, const Color(0x99FFD27A));
    }

    // Wine rack on the left.
    rrect(c, w * 0.035, h * 0.16, w * 0.18, h * 0.32, u * 4,
        const Color(0xFF4A2E22));
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 4; col++) {
        final x = w * (0.055 + col * 0.04);
        final y = h * (0.21 + row * 0.08);
        circle(c, Offset(x, y), u * 8, const Color(0xFF2E1A14));
        rrect(c, x - u * 3, y + u * 7, u * 6, u * 16, u * 2,
            const Color(0xFF5B7A4A));
      }
    }
    // Pendant lights.
    for (final x in const [0.30, 0.52, 0.75]) {
      pendant(c, Offset(w * x, 0), h * 0.13, 1.2, const Color(0xFFE0A44A));
    }

    // Round tables with white cloth.
    for (final table in const [
      Offset(0.28, 0.78),
      Offset(0.52, 0.84),
      Offset(0.78, 0.76),
    ]) {
      final cx = w * table.dx;
      final cy = h * table.dy;
      oval(c, Rect.fromCenter(center: Offset(cx, cy - u * 36),
          width: u * 130, height: u * 34), const Color(0xFFF2EDE2));
      poly(c, [
        Offset(cx - u * 62, cy - u * 36),
        Offset(cx + u * 62, cy - u * 36),
        Offset(cx + u * 50, cy + u * 20),
        Offset(cx - u * 50, cy + u * 20),
      ], const Color(0xFFE8E0D0));
      line(c, Offset(cx, cy + u * 20), Offset(cx, cy + u * 64),
          const Color(0xFF4A3A2A), u * 5);
      oval(c, Rect.fromCenter(center: Offset(cx, cy + u * 66),
          width: u * 40, height: u * 10), const Color(0xFF4A3A2A));
      // Candle.
      rrect(c, cx - u * 3, cy - u * 52, u * 6, u * 16, u * 2,
          const Color(0xFFF0E6D2));
      oval(c, Rect.fromCenter(center: Offset(cx, cy - u * 56),
          width: u * 5, height: u * 10), const Color(0xFFFFD27A));
      radialGlow(c, Offset(cx, cy - u * 56), u * 26,
          const Color(0xFFFFC857), 0.30);
      // Glasses.
      for (final dx in const [-0.035, 0.035]) {
        rrect(c, cx + w * dx - u * 4, cy - u * 48, u * 8, u * 14, u * 3,
            const Color(0x66E8FAFF));
      }
    }
    // Chairs.
    for (final p in const [Offset(0.18, 0.84), Offset(0.38, 0.88), Offset(0.66, 0.82)]) {
      final x = w * p.dx;
      final y = h * p.dy;
      rrect(c, x - u * 22, y - u * 30, u * 44, u * 26, u * 7,
          const Color(0xFF6B3A2E));
      rrect(c, x - u * 22, y - u * 4, u * 44, u * 8, u * 3,
          const Color(0xFF8A4A3A));
      line(c, Offset(x - u * 18, y + u * 4), Offset(x - u * 19, y + u * 24),
          const Color(0xFF3A241A), u * 3);
      line(c, Offset(x + u * 18, y + u * 4), Offset(x + u * 19, y + u * 24),
          const Color(0xFF3A241A), u * 3);
    }
    plant(c, Offset(w * 0.06, h * 0.88), 1.4);
  }
}

class LaundryArtist extends VenueArtist {
  LaundryArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    // Tiled wall.
    vertical(c, Rect.fromLTWH(0, 0, w, h * 0.62), [
      const Color(0xFF173640),
      const Color(0xFF4A7A82),
    ]);
    final grout = Paint()
      ..color = const Color(0x22304F56)
      ..strokeWidth = u * 1.5;
    for (var x = 0.0; x < w; x += w * 0.055) {
      c.drawLine(Offset(x, 0), Offset(x, h * 0.62), grout);
    }
    for (var y = 0.0; y < h * 0.62; y += h * 0.09) {
      c.drawLine(Offset(0, y), Offset(w, y), grout);
    }
    tileFloor(c, far: const Color(0xFF3E5A60), near: const Color(0xFF16262B),
        horizon: 0.62, columns: 9, rows: 4,
        lineColor: const Color(0x33FFFFFF));

    // Fluorescent strip.
    rrect(c, w * 0.15, h * 0.025, w * 0.70, u * 7, u * 2,
        const Color(0xFFE4F8FF));
    radialGlow(c, Offset(w * 0.5, h * 0.07), w * 0.42,
        const Color(0xFFE4F8FF), 0.16);

    // Washing machines, left to right.
    for (var i = 0; i < 4; i++) {
      final x = w * (0.06 + i * 0.23);
      final machine = Rect.fromLTWH(x, h * 0.34, w * 0.19, h * 0.28);
      rrect(c, machine.left, machine.top, machine.width, machine.height,
          u * 6, const Color(0xFFD9E4E6));
      rrect(c, machine.left + u * 4, machine.top + u * 4,
          machine.width - u * 8, machine.height - u * 8, u * 4,
          const Color(0xFFB9CCD0));
      // Door.
      final door = Offset(machine.center.dx, machine.top + machine.height * 0.58);
      circle(c, door, machine.width * 0.30, const Color(0xFF7A8F94));
      circle(c, door, machine.width * 0.24, const Color(0xFF2E4A52));
      c.save();
      c.clipPath(Path()..addOval(Rect.fromCircle(center: door, radius: machine.width * 0.22)));
      final spin = ambient * math.pi * 6 + i;
      for (var k = 0; k < 5; k++) {
        final a = spin + k * 1.257;
        oval(c, Rect.fromCenter(
          center: door + Offset(math.cos(a), math.sin(a)) * machine.width * 0.10,
          width: u * 16, height: u * 10,
        ), k.isEven ? const Color(0xFF9FCBE8) : const Color(0xFFE8A0A8));
      }
      c.restore();
      c.drawArc(
        Rect.fromCircle(center: door, radius: machine.width * 0.30),
        0, math.pi * 2, false,
        Paint()
          ..color = const Color(0xFFF5FAFA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 3,
      );
      // Control panel.
      rect(c, machine.left + u * 8, machine.top + u * 8,
          machine.width - u * 16, u * 9, const Color(0xFF4A5A5E));
      circle(c, Offset(machine.right - u * 16, machine.top + u * 12),
          u * 3.5, const Color(0xFF7FE0C4));
      // Detergent drawer.
      rrect(c, machine.left + u * 10, machine.top + u * 20,
          machine.width * 0.35, u * 7, u * 2, const Color(0xFF8FA4A8));
    }
    // Dryer on the far right with warm air.
    final dx = w * 0.83;
    rrect(c, dx, h * 0.30, w * 0.13, h * 0.34, u * 6, const Color(0xFFC9B9A6));
    circle(c, Offset(dx + w * 0.065, h * 0.50), w * 0.045, const Color(0xFF7A6A5A));
    radialGlow(c, Offset(dx + w * 0.065, h * 0.50), w * 0.09,
        const Color(0xFFFFD27A), 0.22);
    steam(c, const Offset(0.86, 0.34), const Color(0x66FFE4C4));

    // Folding table and baskets.
    rrect(c, w * 0.16, h * 0.70, w * 0.28, u * 10, u * 3,
        const Color(0xFF8FB4BA));
    line(c, Offset(w * 0.18, h * 0.71), Offset(w * 0.18, h * 0.83),
        const Color(0xFF5B5B5B), u * 3);
    line(c, Offset(w * 0.42, h * 0.71), Offset(w * 0.42, h * 0.83),
        const Color(0xFF5B5B5B), u * 3);
    for (var i = 0; i < 3; i++) {
      rrect(c, w * (0.19 + i * 0.075), h * 0.665, u * 42, u * 20, u * 3,
          i.isEven ? const Color(0xFF8FA4A8) : const Color(0xFFB9CCD0));
      rrect(c, w * (0.19 + i * 0.075), h * 0.66, u * 42, u * 8, u * 2,
          const Color(0xFFE8F4F0));
    }
    // Detergent shelf.
    rrect(c, w * 0.60, h * 0.16, w * 0.18, u * 8, u * 2, const Color(0xFF6B8A8E));
    for (var i = 0; i < 4; i++) {
      rrect(c, w * (0.61 + i * 0.04), h * 0.115, u * 20, u * 26, u * 3,
          const [
            Color(0xFF7FE0C4), Color(0xFF8FD8FF), Color(0xFFE8A0A8),
            Color(0xFFE0B45C),
          ][i]);
    }
  }
}

class ComputerArtist extends VenueArtist {
  ComputerArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    room(
      c,
      wallTop: const Color(0xFF0B1020),
      wallBottom: const Color(0xFF243452),
      floorFar: const Color(0xFF1A2338),
      floorNear: const Color(0xFF080B14),
      horizon: 0.62,
    );
    tileFloor(c, far: const Color(0xFF1A2338), near: const Color(0xFF080B14),
        horizon: 0.62, columns: 8, rows: 4,
        lineColor: const Color(0x339FB6FF));

    // Ceiling light strips.
    for (var i = 0; i < 3; i++) {
      final x = w * (0.14 + i * 0.28);
      rrect(c, x, h * 0.035, w * 0.18, u * 6, u * 2,
          const Color(0xFF9FB6FF));
      radialGlow(c, Offset(x + w * 0.09, h * 0.07), u * 80,
          const Color(0xFF9FB6FF), 0.16);
    }

    // Long desk rows with monitors.
    for (var row = 0; row < 2; row++) {
      final y = h * (0.42 + row * 0.23);
      final scale = 0.75 + row * 0.35;
      rrect(c, w * 0.05, y, w * 0.62, u * 12 * scale, u * 3,
          const Color(0xFF2E3A50));
      for (var i = 0; i < 4; i++) {
        final x = w * (0.09 + i * 0.15);
        final s = u * scale;
        // Monitor.
        rrect(c, x, y - 58 * s, 70 * s, 42 * s, 4 * s,
            const Color(0xFF141A28));
        rect(c, x + 4 * s, y - 54 * s, 62 * s, 34 * s,
            const Color(0xFF7FD1FF));
        vertical(c, Rect.fromLTWH(x + 4 * s, y - 54 * s, 62 * s, 34 * s), [
          const Color(0xFF2E7DC4).withAlpha(200),
          const Color(0xFF9DE9FF).withAlpha(160),
        ]);
        for (var k = 0; k < 4; k++) {
          line(c, Offset(x + 9 * s, y - 49 * s + k * 7 * s),
              Offset(x + (28 + (k % 3) * 12) * s, y - 49 * s + k * 7 * s),
              const Color(0xAA1A2A40), 1.5 * s);
        }
        line(c, Offset(x + 30 * s, y - 16 * s), Offset(x + 40 * s, y - 16 * s),
            const Color(0xFF141A28), 3 * s);
        line(c, Offset(x + 35 * s, y - 16 * s), Offset(x + 35 * s, y - 6 * s),
            const Color(0xFF141A28), 2 * s);
        // Keyboard.
        rrect(c, x + 10 * s, y + 2 * s, 50 * s, 5 * s, 1.5 * s,
            const Color(0xFF39465E));
        // Chair.
        rrect(c, x + 18 * s, y + 26 * s, 34 * s, 16 * s, 5 * s,
            const Color(0xFF202A3E));
        rrect(c, x + 18 * s, y + 12 * s, 34 * s, 20 * s, 5 * s,
            const Color(0xFF2A3650));
        line(c, Offset(x + 35 * s, y + 42 * s), Offset(x + 35 * s, y + 54 * s),
            const Color(0xFF1A2232), 2 * s);
      }
      // Cable spaghetti under the desk.
      final cable = Paint()
        ..color = const Color(0x663E5A86)
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 1.5;
      for (var i = 0; i < 4; i++) {
        c.drawPath(
          Path()
            ..moveTo(w * (0.12 + i * 0.15), y + u * 10)
            ..quadraticBezierTo(w * (0.14 + i * 0.15), y + u * 44,
                w * (0.18 + i * 0.15), y + u * 52),
          cable,
        );
      }
    }

    // Server rack with blinking LEDs.
    rrect(c, w * 0.75, h * 0.16, w * 0.16, h * 0.48, u * 5,
        const Color(0xFF141A28));
    for (var i = 0; i < 6; i++) {
      final y = h * (0.19 + i * 0.07);
      rrect(c, w * 0.76, y, w * 0.14, u * 12, u * 2,
          const Color(0xFF232D42));
      for (var k = 0; k < 4; k++) {
        final blink = 0.4 + 0.6 * ((math.sin(ambient * 20 + i * 2.1 + k) + 1) / 2);
        circle(c, Offset(w * (0.785 + k * 0.024), y + u * 6), u * 2.2,
            (k.isEven ? const Color(0xFF7FE0C4) : const Color(0xFF9FB6FF))
                .withAlpha((255 * blink).round()));
      }
    }
    radialGlow(c, Offset(w * 0.83, h * 0.40), u * 80,
        const Color(0xFF9FB6FF), 0.18);
    plant(c, Offset(w * 0.955, h * 0.68), 1.1);
  }
}

class HotelArtist extends VenueArtist {
  HotelArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    room(
      c,
      wallTop: const Color(0xFF1D1429),
      wallBottom: const Color(0xFF5B4A6E),
      floorFar: const Color(0xFF4A3E58),
      floorNear: const Color(0xFF1A1222),
      horizon: 0.62,
    );
    tileFloor(c, far: const Color(0xFF4A3E58), near: const Color(0xFF1A1222),
        horizon: 0.62, columns: 7, rows: 4,
        lineColor: const Color(0x33FFE2A8));

    // Tall arched windows.
    for (final x in const [0.10, 0.74]) {
      final r = Rect.fromLTWH(w * x, h * 0.14, w * 0.16, h * 0.36);
      final arch = Path()
        ..moveTo(r.left, r.bottom)
        ..lineTo(r.left, r.top + r.height * 0.18)
        ..quadraticBezierTo(r.center.dx, r.top - r.height * 0.06,
            r.right, r.top + r.height * 0.18)
        ..lineTo(r.right, r.bottom)
        ..close();
      c.drawPath(arch, Paint()..color = const Color(0xFF2A1E38));
      c.save();
      c.clipPath(arch);
      vertical(c, r, [const Color(0xFF1E2A4A), const Color(0xFF8A5E6A)]);
      for (var i = 0; i < 8; i++) {
        circle(c, Offset(r.left + (i * 0.37 % 1) * r.width,
            r.top + (i * 0.23 % 1) * r.height), u * 1.8,
            const Color(0xCCFFE2A8));
      }
      c.restore();
      c.drawPath(arch, Paint()
        ..color = const Color(0xFFB9A05A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 3);
    }

    // Chandelier.
    line(c, Offset(w * 0.5, 0), Offset(w * 0.5, h * 0.08), const Color(0xFFB9A05A), u * 2);
    for (var ring = 0; ring < 2; ring++) {
      final rx = u * (34 + ring * 20);
      final ry = u * (9 + ring * 5);
      c.drawOval(
        Rect.fromCenter(center: Offset(w * 0.5, h * (0.11 + ring * 0.035)),
            width: rx * 2, height: ry * 2),
        Paint()
          ..color = const Color(0xFFD9C27A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 2,
      );
      for (var i = 0; i < 8; i++) {
        final a = i / 8 * math.pi * 2;
        final p = Offset(w * 0.5 + math.cos(a) * rx, h * (0.11 + ring * 0.035) + math.sin(a) * ry);
        circle(c, p, u * 2.6, const Color(0xFFFFE2A8));
      }
    }
    radialGlow(c, Offset(w * 0.5, h * 0.14), u * 130,
        const Color(0xFFFFE2A8), 0.26);

    // Grand staircase on the left.
    for (var i = 0; i < 6; i++) {
      final y = h * (0.74 - i * 0.055);
      final wd = w * (0.20 + i * 0.018);
      rect(c, w * 0.02, y, wd, h * 0.05, i.isEven ? const Color(0xFF6B5A7A) : const Color(0xFF7E6B8E));
      rect(c, w * 0.02, y, wd, u * 3, const Color(0xFFB9A05A));
    }
    line(c, Offset(w * 0.03, h * 0.42), Offset(w * 0.20, h * 0.74),
        const Color(0xFFB9A05A), u * 3);
    for (var i = 0; i < 5; i++) {
      final t = i / 5;
      line(c, Offset(w * (0.03 + t * 0.17), h * (0.42 + t * 0.32)),
          Offset(w * (0.03 + t * 0.17), h * (0.48 + t * 0.32)),
          const Color(0xFFB9A05A), u * 2);
    }

    // Reception desk on the right.
    rrect(c, w * 0.64, h * 0.56, w * 0.30, h * 0.17, u * 7,
        const Color(0xFF5B4330));
    rrect(c, w * 0.64, h * 0.56, w * 0.30, u * 12, u * 4,
        const Color(0xFFD9C9A8));
    rect(c, w * 0.65, h * 0.60, w * 0.28, h * 0.025, const Color(0xFFB9A05A));
    // Backlit room-key board.
    rrect(c, w * 0.68, h * 0.28, w * 0.22, h * 0.22, u * 4,
        const Color(0xFF3A2A44));
    for (var i = 0; i < 9; i++) {
      final x = w * (0.695 + (i % 3) * 0.065);
      final y = h * (0.31 + (i ~/ 3) * 0.06);
      rrect(c, x, y, u * 16, u * 12, u * 2, const Color(0xFFFFE2A8));
    }

    // Lounge sofas in the middle.
    rrect(c, w * 0.31, h * 0.72, w * 0.24, h * 0.12, u * 8,
        const Color(0xFF6B3E5A));
    rrect(c, w * 0.32, h * 0.62, w * 0.22, h * 0.12, u * 8,
        const Color(0xFF8A4F6E));
    rrect(c, w * 0.34, h * 0.66, w * 0.18, h * 0.08, u * 6,
        const Color(0xFFA8607E));
    rrect(c, w * 0.36, h * 0.80, w * 0.14, u * 10, u * 3,
        const Color(0xFF3A2A1A));
    // Low table with a lamp.
    rrect(c, w * 0.55, h * 0.80, w * 0.09, u * 6, u * 2,
        const Color(0xFF3A2A1A));
    line(c, Offset(w * 0.595, h * 0.80), Offset(w * 0.595, h * 0.74),
        const Color(0xFFB9A05A), u * 2);
    poly(c, [
      Offset(w * 0.585, h * 0.74),
      Offset(w * 0.605, h * 0.74),
      Offset(w * 0.61, h * 0.70),
      Offset(w * 0.58, h * 0.70),
    ], const Color(0xFFFFE2A8));
    radialGlow(c, Offset(w * 0.595, h * 0.73), u * 60,
        const Color(0xFFFFE2A8), 0.24);

    // Red carpet runner.
    poly(c, [
      Offset(w * 0.40, h),
      Offset(w * 0.46, h * 0.62),
      Offset(w * 0.56, h * 0.62),
      Offset(w * 0.62, h),
    ], const Color(0x553E1F2E));
    plant(c, Offset(w * 0.05, h * 0.86), 1.5);
    plant(c, Offset(w * 0.97, h * 0.70), 1.2);
  }
}
