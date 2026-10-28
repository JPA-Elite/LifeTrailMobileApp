import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'venue_art_base.dart';

// ---------------------------------------------------------------------------
// Café, mall, garage, bookstore, supermarket and pizzeria.
// ---------------------------------------------------------------------------

class CafeArtist extends VenueArtist {
  CafeArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    room(
      c,
      wallTop: const Color(0xFF2E2118),
      wallBottom: const Color(0xFF8A5E3D),
      floorFar: const Color(0xFF6B4A32),
      floorNear: const Color(0xFF2A1A12),
      horizon: 0.62,
    );
    plankFloor(c, far: const Color(0xFF6B4A32), near: const Color(0xFF2A1A12),
        horizon: 0.62);

    // Window onto the street.
    windowBox(
      c,
      Rect.fromLTWH(w * 0.68, h * 0.13, w * 0.25, h * 0.37),
      skyTop: const Color(0xFF7FB4D8),
      skyBottom: const Color(0xFFFFC98A),
      curtains: true,
      mullions: 2,
    );
    poly(c, [
      Offset(w * 0.68, h * 0.50),
      Offset(w * 0.93, h * 0.50),
      Offset(w * 0.86, h * 0.98),
      Offset(w * 0.60, h * 0.98),
    ], const Color(0x12FFE7B8));

    // Back shelves with jars and cups.
    rrect(c, w * 0.04, h * 0.16, w * 0.24, h * 0.34, u * 4,
        const Color(0xFF4A3222));
    for (var shelf = 0; shelf < 3; shelf++) {
      final y = h * (0.22 + shelf * 0.10);
      rect(c, w * 0.045, y, w * 0.23, u * 4, const Color(0xFF7A5538));
      for (var i = 0; i < 5; i++) {
        final x = w * (0.055 + i * 0.043);
        final jarH = u * (12 + (i % 3) * 5);
        rrect(c, x, y - jarH, u * 13, jarH, u * 2,
            i.isEven ? const Color(0xFFC9A46A) : const Color(0xFF8FAE8E));
      }
    }
    // Chalkboard menu.
    rrect(c, w * 0.38, h * 0.10, w * 0.24, h * 0.24, u * 4,
        const Color(0xFF2A211A));
    rrect(c, w * 0.39, h * 0.11, w * 0.22, h * 0.22, u * 2,
        const Color(0xFF203029));
    for (var i = 0; i < 4; i++) {
      line(c, Offset(w * 0.41, h * (0.15 + i * 0.035)),
          Offset(w * (0.53 + (i % 2) * 0.05), h * (0.15 + i * 0.035)),
          const Color(0xBBF2EDD8), u * 2);
    }
    line(c, Offset(w * 0.395, h * 0.325), Offset(w * 0.555, h * 0.325),
        const Color(0xFF8A6A4B), u * 3);

    // Pendant lamps.
    for (final x in const [0.32, 0.52, 0.84]) {
      pendant(c, Offset(w * x, 0), h * 0.12, 1.3, const Color(0xFFE8A05C));
    }

    // Counter.
    final cy = h * 0.60;
    rrect(c, w * 0.05, cy, w * 0.58, h * 0.18, u * 7,
        const Color(0xFF5B3A24));
    rrect(c, w * 0.05, cy, w * 0.58, u * 12, u * 3,
        const Color(0xFFC79A63));
    for (var i = 0; i < 6; i++) {
      rect(c, w * (0.08 + i * 0.09), cy + u * 16, u * 5, h * 0.13,
          const Color(0x33FFFFFF));
    }
    // Espresso machine.
    rrect(c, w * 0.18, cy - h * 0.13, w * 0.18, h * 0.13, u * 5,
        const Color(0xFFB9C2C8));
    rrect(c, w * 0.19, cy - h * 0.115, w * 0.16, h * 0.075, u * 3,
        const Color(0xFFDDE4E8));
    for (var i = 0; i < 3; i++) {
      circle(c, Offset(w * (0.215 + i * 0.045), cy - h * 0.075), u * 4,
          const Color(0xFF3A3A3A));
      line(c, Offset(w * (0.215 + i * 0.045), cy - h * 0.045),
          Offset(w * (0.215 + i * 0.045), cy - h * 0.025),
          const Color(0xFF5B5B5B), u * 3);
    }
    steam(c, const Offset(0.27, 0.45), const Color(0xAAFFE4C4));
    // Pastry dome.
    final domeCenter = Offset(w * 0.47, cy - u * 4);
    c.drawArc(
      Rect.fromCircle(center: domeCenter, radius: u * 30),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0x44FFFFFF),
    );
    for (var i = 0; i < 4; i++) {
      circle(c, domeCenter + Offset((i - 2) * u * 11, -u * 3), u * 5,
          const Color(0xFFD9A45C));
    }
    // Cash register.
    rrect(c, w * 0.56, cy - h * 0.075, w * 0.06, h * 0.075, u * 3,
        const Color(0xFF6B7A80));
    rrect(c, w * 0.565, cy - h * 0.065, w * 0.05, h * 0.045, u * 2,
        const Color(0xFF9FE3D0));

    // Stools.
    stool(c, w * 0.16, h * 0.84, 1.2, const Color(0xFFB45F3A));
    stool(c, w * 0.36, h * 0.86, 1.1, const Color(0xFFB45F3A));
    stool(c, w * 0.55, h * 0.88, 1.0, const Color(0xFFB45F3A));

    // Coffee sacks and a plant.
    for (var i = 0; i < 2; i++) {
      oval(c, Rect.fromCenter(center: Offset(w * (0.70 + i * 0.05), h * 0.83),
          width: u * 48, height: u * 54), const Color(0xFF8A6844));
      line(c, Offset(w * (0.70 + i * 0.05), h * 0.79),
          Offset(w * (0.70 + i * 0.05), h * 0.88), const Color(0x554A3222), u * 2);
    }
    plant(c, Offset(w * 0.97, h * 0.72), 1.3);
  }
}

class MallArtist extends VenueArtist {
  MallArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    // Skylight and atrium.
    vertical(c, Rect.fromLTWH(0, 0, w, h * 0.62), [
      const Color(0xFF2A1C36),
      const Color(0xFF6B4A74),
    ]);
    final sky = Rect.fromLTWH(w * 0.24, 0, w * 0.52, h * 0.16);
    vertical(c, sky, [const Color(0xFF243B5C), const Color(0xFF8FCBE8)]);
    for (var i = 1; i < 6; i++) {
      line(c, Offset(sky.left + sky.width * i / 6, sky.top),
          Offset(sky.left + sky.width * i / 6, sky.bottom),
          const Color(0xFF2A1C36), u * 4);
    }
    line(c, Offset(sky.left, sky.center.dy), Offset(sky.right, sky.center.dy),
        const Color(0xFF2A1C36), u * 4);
    radialGlow(c, Offset(w * 0.5, h * 0.22), w * 0.32,
        const Color(0xFFFFE7C4), 0.25);
    tileFloor(c, far: const Color(0xFF6B5B70), near: const Color(0xFF241A2E),
        horizon: 0.62, columns: 8, rows: 4,
        lineColor: const Color(0x33FFFFFF));

    // Storefronts, left and right.
    for (final side in const [0.0, 1.0]) {
      final x = side == 0 ? w * 0.02 : w * 0.72;
      final tint = side == 0 ? const Color(0xFFE69138) : const Color(0xFF6FA8DC);
      rect(c, x, h * 0.20, w * 0.26, h * 0.42, const Color(0xFF2A2230));
      vertical(c, Rect.fromLTWH(x + u * 6, h * 0.24, w * 0.26 - u * 12, h * 0.34), [
        tint.withAlpha(180),
        tint.withAlpha(40),
      ]);
      // Mannequins / display blobs.
      for (var i = 0; i < 3; i++) {
        final cx = x + w * (0.06 + i * 0.07);
        circle(c, Offset(cx, h * 0.38), u * 7, const Color(0xCCF2E6D8));
        poly(c, [
          Offset(cx - u * 10, h * 0.47),
          Offset(cx, h * 0.39),
          Offset(cx + u * 10, h * 0.47),
        ], const Color(0xCCF2E6D8));
      }
      // Neon sign.
      final nx = x + w * 0.03;
      rrect(c, nx, h * 0.205, w * 0.12, u * 22, u * 4,
          side == 0 ? const Color(0xFFFF9EC4) : const Color(0xFF9DE1FF));
      radialGlow(c, Offset(nx + w * 0.06, h * 0.225), u * 40,
          side == 0 ? const Color(0xFFFF9EC4) : const Color(0xFF9DE1FF), 0.28);
      for (var i = 0; i < 3; i++) {
        line(c, Offset(nx + u * 8, h * 0.212 + i * u * 5),
            Offset(nx + w * 0.10, h * 0.212 + i * u * 5),
            const Color(0xAA2A1C36), u * 2);
      }
    }

    // Escalator.
    final ex = w * 0.40;
    poly(c, [
      Offset(ex, h * 0.48),
      Offset(ex + w * 0.20, h * 0.80),
      Offset(ex + w * 0.25, h * 0.80),
      Offset(ex + w * 0.05, h * 0.48),
    ], const Color(0xFF3A3342));
    for (var i = 0; i < 12; i++) {
      final t = i / 11;
      line(c, Offset(ex + w * 0.01 + t * w * 0.19, h * 0.50 + t * h * 0.29),
          Offset(ex + w * 0.05 + t * w * 0.19, h * 0.50 + t * h * 0.29),
          const Color(0xFF8F8699), u * 2);
    }
    line(c, Offset(ex + w * 0.01, h * 0.50), Offset(ex + w * 0.05, h * 0.50),
        const Color(0xFFB9B0C4), u * 2);
    line(c, Offset(ex + w * 0.20, h * 0.79), Offset(ex + w * 0.24, h * 0.79),
        const Color(0xFFB9B0C4), u * 2);

    // Fountain.
    final f = Offset(w * 0.50, h * 0.80);
    oval(c, Rect.fromCenter(center: f, width: w * 0.24, height: h * 0.10),
        const Color(0xFF4A3A56));
    oval(c, Rect.fromCenter(center: f - Offset(0, u * 5), width: w * 0.21, height: h * 0.075),
        const Color(0xFF7FD1E8));
    oval(c, Rect.fromCenter(center: f - Offset(0, u * 8), width: w * 0.16, height: h * 0.05),
        const Color(0xFFB6EEF8));
    for (var i = 0; i < 4; i++) {
      final t = (ambient + i * 0.25) % 1;
      circle(c, Offset(f.dx + (i - 1.5) * u * 18, f.dy - u * 10 - t * u * 40),
          u * (2 + t * 3), const Color(0x99E8FAFF));
    }

    // Hanging banners.
    for (var i = 0; i < 4; i++) {
      final x = w * (0.12 + i * 0.22);
      line(c, Offset(x, h * 0.16), Offset(x, h * 0.28), const Color(0xFF3A2A44), u * 1.5);
      poly(c, [
        Offset(x - u * 14, h * 0.28),
        Offset(x + u * 14, h * 0.28),
        Offset(x + u * 10, h * 0.38),
        Offset(x - u * 10, h * 0.38),
      ], i.isEven ? const Color(0xFFFF9EC4) : const Color(0xFF9DE1FF));
    }
    plant(c, Offset(w * 0.10, h * 0.82), 1.4);
    plant(c, Offset(w * 0.90, h * 0.82), 1.3);
  }
}

class GarageArtist extends VenueArtist {
  GarageArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    room(
      c,
      wallTop: const Color(0xFF25282B),
      wallBottom: const Color(0xFF4E555A),
      floorFar: const Color(0xFF3A3E42),
      floorNear: const Color(0xFF171A1D),
      horizon: 0.62,
    );
    // Corrugated wall panels.
    for (var i = 0; i < 24; i++) {
      final x = w * i / 24;
      line(c, Offset(x, h * 0.05), Offset(x, h * 0.62),
          const Color(0x14FFFFFF), u * 3);
    }
    // Roll-up shutter.
    rect(c, w * 0.32, h * 0.08, w * 0.36, h * 0.40, const Color(0xFF3E4449));
    for (var i = 0; i < 9; i++) {
      line(c, Offset(w * 0.32, h * 0.10 + i * h * 0.042),
          Offset(w * 0.68, h * 0.10 + i * h * 0.042),
          const Color(0xFF596168), u * 2);
    }
    // Pegboard with tools.
    rrect(c, w * 0.06, h * 0.16, w * 0.20, h * 0.25, u * 3,
        const Color(0xFF6B5A44));
    for (var i = 0; i < 8; i++) {
      final x = w * (0.08 + (i % 4) * 0.045);
      final y = h * (0.20 + (i ~/ 4) * 0.09);
      if (i.isEven) {
        line(c, Offset(x, y), Offset(x, y + u * 34), const Color(0xFFB9BEC2), u * 4);
        strokeCircle(c, Offset(x, y), u * 6, const Color(0xFFB9BEC2), u * 3);
      } else {
        rrect(c, x - u * 4, y, u * 8, u * 30, u * 1,
            const Color(0xFF8A6A4B));
        rrect(c, x - u * 8, y - u * 5, u * 16, u * 8, u * 2,
            const Color(0xFFB9BEC2));
      }
    }
    // Workbench.
    rrect(c, w * 0.71, h * 0.46, w * 0.26, h * 0.06, u * 3,
        const Color(0xFF8A5A34));
    rect(c, w * 0.72, h * 0.52, u * 8, h * 0.16, const Color(0xFF4A3222));
    rect(c, w * 0.93, h * 0.52, u * 8, h * 0.16, const Color(0xFF4A3222));
    // Toolbox and parts.
    rrect(c, w * 0.75, h * 0.42, u * 50, u * 22, u * 3,
        const Color(0xFFB45F3A));
    line(c, Offset(w * 0.75 + u * 20, h * 0.42),
        Offset(w * 0.75 + u * 20, h * 0.40), const Color(0xFF3A3A3A), u * 2);
    for (var i = 0; i < 3; i++) {
      circle(c, Offset(w * (0.90 + i * 0.018), h * 0.43), u * 7,
          const Color(0xFF6B6B6B));
      circle(c, Offset(w * (0.90 + i * 0.018), h * 0.43), u * 3,
          const Color(0xFF3A3A3A));
    }

    // Bike on a repair stand.
    final bx = w * 0.40;
    final by = h * 0.70;
    strokeCircle(c, Offset(bx - u * 54, by), u * 34, const Color(0xFF2A2A2A), u * 6);
    strokeCircle(c, Offset(bx + u * 54, by), u * 34, const Color(0xFF2A2A2A), u * 6);
    for (var i = 0; i < 8; i++) {
      final a = i / 8 * math.pi * 2 + ambient * 0.2;
      line(c, Offset(bx - u * 54, by),
          Offset(bx - u * 54 + math.cos(a) * u * 32, by + math.sin(a) * u * 32),
          const Color(0x66555B60), u * 1);
      line(c, Offset(bx + u * 54, by),
          Offset(bx + u * 54 + math.cos(a) * u * 32, by + math.sin(a) * u * 32),
          const Color(0x66555B60), u * 1);
    }
    final frame = Paint()
      ..color = const Color(0xFFE06666)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 7
      ..strokeCap = StrokeCap.round;
    c.drawPath(
      Path()
        ..moveTo(bx - u * 54, by)
        ..lineTo(bx - u * 8, by - u * 32)
        ..lineTo(bx + u * 30, by - u * 32)
        ..lineTo(bx + u * 54, by)
        ..lineTo(bx + u * 4, by)
        ..lineTo(bx - u * 8, by - u * 32),
      frame,
    );
    line(c, Offset(bx + u * 30, by - u * 32), Offset(bx + u * 24, by - u * 52),
        const Color(0xFF3A3A3A), u * 3);
    line(c, Offset(bx + u * 24, by - u * 52), Offset(bx + u * 46, by - u * 52),
        const Color(0xFF3A3A3A), u * 3);
    // Repair stand.
    line(c, Offset(bx, by + u * 10), Offset(bx, by + u * 74),
        const Color(0xFF555B60), u * 4);
    line(c, Offset(bx - u * 22, by + u * 74), Offset(bx + u * 22, by + u * 74),
        const Color(0xFF555B60), u * 4);

    // Tires and oil stains.
    for (var i = 0; i < 3; i++) {
      oval(c, Rect.fromCenter(center: Offset(w * 0.14, h * (0.66 + i * 0.055)),
          width: u * 62, height: u * 26), const Color(0xFF1F2225));
      oval(c, Rect.fromCenter(center: Offset(w * 0.14, h * (0.66 + i * 0.055)),
          width: u * 30, height: u * 11), const Color(0xFF3A3E42));
    }
    for (final p in const [Offset(0.58, 0.86), Offset(0.66, 0.91)]) {
      oval(c, Rect.fromCenter(center: Offset(w * p.dx, h * p.dy),
          width: u * 60, height: u * 16), const Color(0x552A1A10));
    }

    // Hanging bulb.
    line(c, Offset(w * 0.54, 0), Offset(w * 0.54, h * 0.20),
        const Color(0xFF2A2A2A), u * 2);
    circle(c, Offset(w * 0.54, h * 0.215), u * 9, const Color(0xFFFFE7A8));
    poly(c, [
      Offset(w * 0.51, h * 0.22),
      Offset(w * 0.57, h * 0.22),
      Offset(w * 0.68, h * 0.72),
      Offset(w * 0.40, h * 0.72),
    ], const Color(0x10FFE7A8));
    radialGlow(c, Offset(w * 0.54, h * 0.24), u * 100,
        const Color(0xFFFFE7A8), 0.22);
  }
}

class BookstoreArtist extends VenueArtist {
  BookstoreArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    room(
      c,
      wallTop: const Color(0xFF2A1D14),
      wallBottom: const Color(0xFF6B4A32),
      floorFar: const Color(0xFF5B3E29),
      floorNear: const Color(0xFF24160E),
      horizon: 0.62,
    );
    plankFloor(c, far: const Color(0xFF5B3E29), near: const Color(0xFF24160E),
        horizon: 0.62);

    // Tall shelves with coloured spines.
    void shelf(double x, double y, double wd, double ht, int shelves) {
      rect(c, x, y, wd, ht, const Color(0xFF4A3222));
      for (var s = 0; s < shelves; s++) {
        final sy = y + ht * (s + 1) / shelves - u * 4;
        rect(c, x, sy, wd, u * 5, const Color(0xFF7A5538));
        var bx = x + u * 4;
        var i = 0;
        while (bx < x + wd - u * 8) {
          final bw = u * (6 + (i * 7) % 9);
          final bh = ht / shelves * (0.55 + ((i * 3) % 4) * 0.10);
          final colors = const [
            Color(0xFFB45F5F), Color(0xFF5B7FA6), Color(0xFF6AA84F),
            Color(0xFFE0A44A), Color(0xFF8E7CC3), Color(0xFF4A8F8A),
          ];
          rect(c, bx, sy - bh, bw, bh, colors[i % colors.length]);
          bx += bw + u * 2;
          i++;
        }
      }
    }

    shelf(w * 0.02, h * 0.08, w * 0.27, h * 0.62, 4);
    shelf(w * 0.71, h * 0.08, w * 0.27, h * 0.62, 4);
    shelf(w * 0.32, h * 0.06, w * 0.36, h * 0.26, 2);

    // Rolling ladder.
    line(c, Offset(w * 0.26, h * 0.10), Offset(w * 0.20, h * 0.72),
        const Color(0xFF8A6A4B), u * 4);
    line(c, Offset(w * 0.31, h * 0.10), Offset(w * 0.25, h * 0.72),
        const Color(0xFF8A6A4B), u * 4);
    for (var i = 0; i < 6; i++) {
      final t = i / 6;
      line(c, Offset(w * (0.26 - 0.06 * t), h * (0.16 + 0.55 * t)),
          Offset(w * (0.31 - 0.06 * t), h * (0.16 + 0.55 * t)),
          const Color(0xFF6B4A32), u * 2.5);
    }

    // Big window.
    windowBox(
      c,
      Rect.fromLTWH(w * 0.36, h * 0.44, w * 0.20, h * 0.30),
      skyTop: const Color(0xFF7FB4D8),
      skyBottom: const Color(0xFFFFD49A),
      mullions: 2,
    );

    // Reading chair and lamp.
    rrect(c, w * 0.60, h * 0.68, w * 0.18, h * 0.16, u * 8,
        const Color(0xFF7A3E3E));
    rrect(c, w * 0.62, h * 0.60, w * 0.14, h * 0.12, u * 8,
        const Color(0xFF8F4A4A));
    rrect(c, w * 0.64, h * 0.64, w * 0.10, h * 0.08, u * 6,
        const Color(0xFFB96A55));
    line(c, Offset(w * 0.62, h * 0.84), Offset(w * 0.62, h * 0.90),
        const Color(0xFF3A2A1A), u * 4);
    line(c, Offset(w * 0.76, h * 0.84), Offset(w * 0.76, h * 0.90),
        const Color(0xFF3A2A1A), u * 4);
    // Floor lamp.
    line(c, Offset(w * 0.83, h * 0.58), Offset(w * 0.83, h * 0.90),
        const Color(0xFF3A3A3A), u * 3);
    poly(c, [
      Offset(w * 0.80, h * 0.58),
      Offset(w * 0.86, h * 0.58),
      Offset(w * 0.875, h * 0.68),
      Offset(w * 0.785, h * 0.68),
    ], const Color(0xFFF0C987));
    radialGlow(c, Offset(w * 0.83, h * 0.64), u * 100,
        const Color(0xFFFFE7B0), 0.28);

    // Book stacks on the floor.
    for (var i = 0; i < 6; i++) {
      final x = w * (0.08 + (i % 3) * 0.32);
      final y = h * (0.82 + (i ~/ 3) * 0.06);
      final count = 2 + (i % 3);
      for (var b = 0; b < count; b++) {
        rrect(c, x, y - b * u * 8, u * (44 - b * 3), u * 7, u * 1,
            const [
              Color(0xFF6E8FB0),
              Color(0xFFB96A55),
              Color(0xFF7EBB6E),
              Color(0xFFE0B45C),
            ][(i + b) % 4]);
      }
    }
  }
}

class SupermarketArtist extends VenueArtist {
  SupermarketArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    room(
      c,
      wallTop: const Color(0xFF1B2A24),
      wallBottom: const Color(0xFF4F6B5A),
      floorFar: const Color(0xFF5A6B60),
      floorNear: const Color(0xFF222E28),
      horizon: 0.60,
    );
    tileFloor(c, far: const Color(0xFF5A6B60), near: const Color(0xFF222E28),
        horizon: 0.60, columns: 9, rows: 4,
        lineColor: const Color(0x22000000));

    // Fluorescent ceiling bars.
    for (var i = 0; i < 4; i++) {
      final x = w * (0.10 + i * 0.24);
      rrect(c, x, h * 0.04, w * 0.14, u * 7, u * 2,
          const Color(0xFFE8FFF4));
      radialGlow(c, Offset(x + w * 0.07, h * 0.08), u * 90,
          const Color(0xFFE8FFF4), 0.18);
    }

    // Hanging aisle signs.
    for (var i = 0; i < 3; i++) {
      final x = w * (0.25 + i * 0.25);
      line(c, Offset(x, 0), Offset(x, h * 0.18), const Color(0xFF3A4A40), u * 1.5);
      rrect(c, x - u * 40, h * 0.18, u * 80, u * 22, u * 3,
          i.isEven ? const Color(0xFF4A8F8A) : const Color(0xFF6AA84F));
      for (var k = 0; k < 2; k++) {
        line(c, Offset(x - u * 28, h * 0.193 + k * u * 7),
            Offset(x + u * 24, h * 0.193 + k * u * 7),
            const Color(0xCCF2F7F0), u * 2);
      }
    }

    // Aisles: shelves on the left, freezer on the right.
    void aisle(double x, double y, double wd, double ht, int shelves) {
      rect(c, x, y, wd, ht, const Color(0xFF3E4F45));
      for (var s = 0; s < shelves; s++) {
        final sy = y + ht * (s + 1) / shelves - u * 5;
        rect(c, x, sy, wd, u * 6, const Color(0xFF6B7A70));
        var bx = x + u * 5;
        var i = 0;
        while (bx < x + wd - u * 10) {
          final bw = u * (9 + (i * 5) % 8);
          final bh = ht / shelves * (0.32 + ((i * 3) % 4) * 0.08);
          final colors = const [
            Color(0xFFD9534F), Color(0xFFE0B45C), Color(0xFF5B7FA6),
            Color(0xFF7EBB6E), Color(0xFFB96A9A), Color(0xFFD9D2C3),
          ];
          rrect(c, bx, sy - bh, bw, bh, u * 1.5, colors[i % colors.length]);
          bx += bw + u * 2;
          i++;
        }
      }
    }

    aisle(w * 0.05, h * 0.30, w * 0.24, h * 0.40, 3);
    aisle(w * 0.35, h * 0.28, w * 0.20, h * 0.42, 3);

    // Freezer case with cold glow.
    final fr = Rect.fromLTWH(w * 0.72, h * 0.30, w * 0.24, h * 0.36);
    vertical(c, fr, [const Color(0xFF2E5B66), const Color(0xFF16343E)]);
    for (var i = 0; i < 3; i++) {
      final y = fr.top + fr.height * (0.20 + i * 0.26);
      rect(c, fr.left, y, fr.width, u * 4, const Color(0xFF7FD1E8));
      for (var k = 0; k < 4; k++) {
        rrect(c, fr.left + u * (8 + k * 24), y - u * 16, u * 18, u * 15,
            u * 2, const Color(0xFFD9F4FF));
      }
    }
    strokeRRect(c, fr, u * 5, const Color(0xFF9DE1FF), u * 3);
    radialGlow(c, fr.center, fr.width * 0.9, const Color(0xFF9DE1FF), 0.2);

    // Checkout conveyor.
    rrect(c, w * 0.05, h * 0.73, w * 0.34, h * 0.08, u * 4,
        const Color(0xFF3A3A3A));
    rect(c, w * 0.08, h * 0.715, w * 0.22, u * 8, const Color(0xFF1F1F1F));
    rrect(c, w * 0.40, h * 0.66, w * 0.07, h * 0.12, u * 3,
        const Color(0xFF6B7A70));
    rect(c, w * 0.412, h * 0.67, u * 26, u * 16, const Color(0xFF9BE38E));
    // Shopping basket.
    rrect(c, w * 0.27, h * 0.68, u * 40, u * 20, u * 3,
        const Color(0xFFD9A441));
    for (var i = 0; i < 3; i++) {
      circle(c, Offset(w * 0.27 + u * (10 + i * 10), h * 0.675), u * 6,
          const Color(0xFFE06666));
    }
    plant(c, Offset(w * 0.95, h * 0.72), 1.1);
  }
}

class PizzeriaArtist extends VenueArtist {
  PizzeriaArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    // Brick wall.
    vertical(c, Rect.fromLTWH(0, 0, w, h * 0.62), [
      const Color(0xFF3E1F1C),
      const Color(0xFF7A3A2E),
    ]);
    final mortar = Paint()
      ..color = const Color(0x224A241E)
      ..strokeWidth = u * 2;
    for (var row = 0; row < 8; row++) {
      final y = h * (0.06 + row * 0.07);
      c.drawLine(Offset(0, y), Offset(w, y), mortar);
      for (var col = 0; col < 12; col++) {
        final x = w * (col / 12) + (row.isEven ? w * 0.04 : 0);
        c.drawLine(Offset(x, y), Offset(x, y + h * 0.07), mortar);
      }
    }
    // Chequered floor.
    final floorRect = Rect.fromLTWH(0, h * 0.62, w, h * 0.38);
    vertical(c, floorRect, [const Color(0xFFB9A99A), const Color(0xFF5A4A42)]);
    const tileW = 0.075;
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 14; col++) {
        if ((row + col).isEven) {
          rect(c, w * col * tileW, h * (0.62 + row * 0.076),
              w * tileW, h * 0.076, const Color(0x22FFFFFF));
        }
      }
    }

    // Brick oven with fire.
    final oven = Offset(w * 0.20, h * 0.62);
    c.drawArc(
      Rect.fromCenter(center: oven, width: w * 0.26, height: h * 0.48),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFF6B3A2A),
    );
    c.drawArc(
      Rect.fromCenter(center: oven, width: w * 0.20, height: h * 0.40),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFF2A1410),
    );
    final fire = 0.7 + math.sin(ambient * math.pi * 8) * 0.3;
    radialGlow(c, Offset(oven.dx, h * 0.50), u * 80,
        const Color(0xFFFF8C42), 0.55 * fire);
    poly(c, [
      Offset(oven.dx - u * 26, h * 0.56),
      Offset(oven.dx - u * 8, h * 0.44 - u * 8 * fire),
      Offset(oven.dx, h * 0.50),
      Offset(oven.dx + u * 10, h * 0.43 - u * 6 * fire),
      Offset(oven.dx + u * 28, h * 0.56),
    ], const Color(0xFFFF9E4A));
    poly(c, [
      Offset(oven.dx - u * 15, h * 0.56),
      Offset(oven.dx, h * 0.47 - u * 4 * fire),
      Offset(oven.dx + u * 16, h * 0.56),
    ], const Color(0xFFFFD27A));
    // Chimney.
    rect(c, w * 0.16, h * 0.10, w * 0.08, h * 0.24, const Color(0xFF5B2E24));

    // Counter.
    final cy = h * 0.62;
    rrect(c, w * 0.35, cy, w * 0.34, h * 0.16, u * 5,
        const Color(0xFF5B3A24));
    rrect(c, w * 0.35, cy, w * 0.34, u * 11, u * 3,
        const Color(0xFFC79A63));
    // Pizza boxes.
    for (var i = 0; i < 4; i++) {
      rrect(c, w * (0.38 + i * 0.06), cy - u * 12 - i * u * 3, u * 46, u * 11,
          u * 2, i.isEven ? const Color(0xFFD9B07A) : const Color(0xFFE8C79A));
    }
    // Pizza peel.
    line(c, Offset(w * 0.53, cy - u * 6), Offset(w * 0.62, cy - u * 52),
        const Color(0xFF8A6A4B), u * 4);
    oval(c, Rect.fromCenter(center: Offset(w * 0.625, cy - u * 58),
        width: u * 42, height: u * 54), const Color(0xFFB9BEC2));
    // Menu board.
    rrect(c, w * 0.74, h * 0.14, w * 0.22, h * 0.26, u * 4,
        const Color(0xFF2A211A));
    for (var i = 0; i < 5; i++) {
      line(c, Offset(w * 0.76, h * (0.19 + i * 0.035)),
          Offset(w * (0.84 + (i % 2) * 0.07), h * (0.19 + i * 0.035)),
          const Color(0xBBF2EDD8), u * 2);
    }

    // Red booth.
    rrect(c, w * 0.74, h * 0.66, w * 0.23, h * 0.10, u * 4,
        const Color(0xFF9E2B2B));
    rrect(c, w * 0.75, h * 0.55, w * 0.20, h * 0.15, u * 8,
        const Color(0xFFB43A3A));
    rrect(c, w * 0.77, h * 0.59, w * 0.16, h * 0.09, u * 6,
        const Color(0xFFD9534F));
    rrect(c, w * 0.79, h * 0.76, w * 0.15, u * 8, u * 2,
        const Color(0xFF5B3A24));
    rrect(c, w * 0.81, h * 0.73, u * 30, u * 6, u * 2,
        const Color(0xFFD9B07A));

    // Pendant lamps.
    pendant(c, Offset(w * 0.46, 0), h * 0.15, 1.2, const Color(0xFFE06666));
    pendant(c, Offset(w * 0.86, 0), h * 0.10, 1.0, const Color(0xFFE06666));
    steam(c, const Offset(0.60, 0.58), const Color(0x66FFE4C4));
  }
}
