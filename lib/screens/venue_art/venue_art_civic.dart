import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'venue_art_base.dart';

// ---------------------------------------------------------------------------
// Classroom, plaza, church, park, bank and police station.
// ---------------------------------------------------------------------------

class ClassroomArtist extends VenueArtist {
  ClassroomArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    room(
      c,
      wallTop: const Color(0xFF2B4A5D),
      wallBottom: const Color(0xFF8DAFBE),
      floorFar: const Color(0xFF7A5538),
      floorNear: const Color(0xFF3A271B),
    );
    plankFloor(c, far: const Color(0xFF6B4A32), near: const Color(0xFF332116));

    windowBox(
      c,
      Rect.fromLTWH(w * 0.035, h * 0.11, w * 0.19, h * 0.41),
      curtains: true,
      skyTop: const Color(0xFF8FD0EE),
      skyBottom: const Color(0xFFFFE0A6),
    );
    // Sunlight falling across the room.
    poly(c, [
      Offset(w * 0.21, h * 0.16),
      Offset(w * 0.52, h * 0.72),
      Offset(w * 0.36, h * 0.78),
      Offset(w * 0.08, h * 0.24),
    ], const Color(0x16FFE7B8));

    // Blackboard.
    final board = Rect.fromLTWH(w * 0.30, h * 0.09, w * 0.42, h * 0.31);
    rrect(c, board.left, board.top, board.width, board.height, u * 7,
        const Color(0xFF3B2A1E));
    rrect(c, board.left + u * 7, board.top + u * 7, board.width - u * 14,
        board.height - u * 14, u * 3, const Color(0xFF1D3A32));
    final chalk = Paint()
      ..color = const Color(0xCCF2F1E4)
      ..strokeWidth = u * 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final y = board.top + board.height * (0.27 + i * 0.13);
      c.drawLine(
        Offset(board.left + board.width * 0.10, y),
        Offset(
          board.left + board.width * (0.52 + (i % 2) * 0.18),
          y - u * (i % 2 == 0 ? 4 : 0),
        ),
        chalk,
      );
    }
    c.drawPath(
      Path()
        ..moveTo(board.left + board.width * 0.72, board.top + board.height * 0.28)
        ..quadraticBezierTo(
          board.left + board.width * 0.80,
          board.top + board.height * 0.45,
          board.left + board.width * 0.70,
          board.top + board.height * 0.62,
        ),
      chalk,
    );
    rrect(c, board.left + board.width * 0.58, board.bottom - u * 8,
        u * 46, u * 8, u * 2, const Color(0xFFD9C7A5));

    // Clock, with a minute hand that creeps around.
    final clockCenter = Offset(w * 0.80, h * 0.15);
    circle(c, clockCenter, h * 0.055, const Color(0xFF23343D));
    circle(c, clockCenter, h * 0.045, const Color(0xFFF5E9CF));
    final minuteAngle = ambient * math.pi * 2;
    line(c, clockCenter, clockCenter + Offset(math.cos(minuteAngle), math.sin(minuteAngle)) * h * 0.034,
        const Color(0xFF2B2B2B), u * 2);
    line(c, clockCenter, clockCenter + const Offset(0, -1) * h * 0.026,
        const Color(0xFF2B2B2B), u * 3);

    // Teacher's desk.
    rrect(c, w * 0.66, h * 0.46, w * 0.20, h * 0.10, u * 5,
        const Color(0xFF8A5A34));
    rect(c, w * 0.68, h * 0.56, u * 10, h * 0.12, const Color(0xFF5A3A22));
    rect(c, w * 0.81, h * 0.56, u * 10, h * 0.12, const Color(0xFF5A3A22));
    rrect(c, w * 0.70, h * 0.43, u * 42, u * 9, u * 2, const Color(0xFFE7DCC3));

    // Student desks, nearer rows lower and larger.
    for (var row = 0; row < 3; row++) {
      final depth = row / 2;
      for (var col = 0; col < 4; col++) {
        final cx = w * (0.16 + col * 0.20) + w * 0.035 * (2 - row);
        final cy = h * (0.64 + depth * 0.14);
        _desk(c, cx, cy, 0.65 + depth * 0.45);
      }
    }
    // Paper garland strung across the ceiling.
    final garland = Path()
      ..moveTo(0, h * 0.06)
      ..quadraticBezierTo(w * 0.5, h * 0.16, w, h * 0.05);
    path(c, garland, const Color(0xFF6D5A4A), u * 1.6);
    for (var i = 0; i < 9; i++) {
      final t = (i + 0.5) / 9;
      final x = w * t;
      final y = h * (0.06 + math.sin(t * math.pi) * 0.10);
      poly(c, [
        Offset(x, y),
        Offset(x + u * 8, y + u * 16),
        Offset(x - u * 8, y + u * 16),
      ], const Color(0xFFE8B45A));
    }
  }

  void _desk(Canvas c, double cx, double cy, double scale) {
    final s = u * scale;
    // Chair back behind the desk.
    rrect(c, cx - 20 * s, cy - 46 * s, 40 * s, 34 * s, 6 * s,
        const Color(0xFF7C5A3C));
    rect(c, cx - 18 * s, cy - 14 * s, 36 * s, 5 * s, const Color(0xFF5A3E29));
    // Desk top in slight perspective.
    poly(c, [
      Offset(cx - 44 * s, cy - 12 * s),
      Offset(cx + 44 * s, cy - 12 * s),
      Offset(cx + 52 * s, cy + 4 * s),
      Offset(cx - 52 * s, cy + 4 * s),
    ], const Color(0xFFC79A63));
    rect(c, cx - 50 * s, cy + 4 * s, 100 * s, 7 * s, const Color(0xFF90663F));
    line(c, Offset(cx - 40 * s, cy + 10 * s), Offset(cx - 42 * s, cy + 54 * s),
        const Color(0xFF5B4128), 4 * s);
    line(c, Offset(cx + 40 * s, cy + 10 * s), Offset(cx + 42 * s, cy + 54 * s),
        const Color(0xFF5B4128), 4 * s);
    // A book and a pencil.
    rrect(c, cx - 26 * s, cy - 20 * s, 34 * s, 8 * s, 2 * s,
        const Color(0xFFD9D2E9));
    line(c, Offset(cx + 12 * s, cy - 18 * s), Offset(cx + 28 * s, cy - 14 * s),
        const Color(0xFFFFD966), 2 * s);
  }
}

class PlazaArtist extends VenueArtist {
  PlazaArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    vertical(c, Rect.fromLTWH(0, 0, w, h * 0.62), [
      const Color(0xFF78BFE4),
      const Color(0xFFFFD49A),
    ]);
    final sun = Offset(w * 0.80, h * 0.17);
    radialGlow(c, sun, w * 0.20, const Color(0xFFFFE7B0), 0.55);
    circle(c, sun, h * 0.045, const Color(0xFFFFF3D4));
    // Soft clouds.
    for (final c0 in const [Offset(0.22, 0.16), Offset(0.52, 0.10), Offset(0.66, 0.24)]) {
      oval(c, Rect.fromCenter(center: Offset(w * c0.dx, h * c0.dy), width: w * 0.16, height: h * 0.045),
          const Color(0x55FFFFFF));
      oval(c, Rect.fromCenter(center: Offset(w * (c0.dx + 0.04), h * (c0.dy - 0.02)), width: w * 0.10, height: h * 0.04),
          const Color(0x44FFFFFF));
    }
    // Distant town skyline.
    for (var i = 0; i < 11; i++) {
      final bw = w * (0.055 + (i % 3) * 0.018);
      final bh = h * (0.10 + (i % 4) * 0.035);
      final x = w * (0.03 + i * 0.089);
      rect(c, x, h * 0.62 - bh, bw, bh, const Color(0xFF6E7E8A));
      for (var k = 0; k < 4; k++) {
        rect(c, x + bw * 0.16 + (k % 2) * bw * 0.45, h * 0.62 - bh + h * 0.02 + k * h * 0.025,
            bw * 0.16, h * 0.012, const Color(0x99FFE7A8));
      }
    }
    // Warm stone plaza.
    vertical(c, Rect.fromLTWH(0, h * 0.62, w, h * 0.38), [
      const Color(0xFFC9A87C),
      const Color(0xFF7C5B3F),
    ]);
    tileFloor(c, far: const Color(0xFFC9A87C), near: const Color(0xFF7C5B3F),
        horizon: 0.62, columns: 10, rows: 4);

    // Fountain.
    final fx = w * 0.50;
    final baseY = h * 0.76;
    oval(c, Rect.fromCenter(center: Offset(fx, baseY), width: w * 0.34, height: h * 0.12),
        const Color(0xFF8C8C8C));
    oval(c, Rect.fromCenter(center: Offset(fx, baseY - h * 0.012), width: w * 0.31, height: h * 0.10),
        const Color(0xFF63B7D8));
    oval(c, Rect.fromCenter(center: Offset(fx, baseY - h * 0.018), width: w * 0.27, height: h * 0.075),
        const Color(0xFF8FD8EC));
    rect(c, fx - u * 10, h * 0.60, u * 20, h * 0.15, const Color(0xFFB9B9B9));
    oval(c, Rect.fromCenter(center: Offset(fx, h * 0.60), width: w * 0.15, height: h * 0.045),
        const Color(0xFFD9D9D9));
    oval(c, Rect.fromCenter(center: Offset(fx, h * 0.595), width: w * 0.12, height: h * 0.03),
        const Color(0xFF7FCBE2));
    // Water arcs.
    final water = Paint()
      ..color = const Color(0xBBE8FAFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final side = i.isEven ? 1.0 : -1.0;
      final lift = math.sin(ambient * math.pi * 2 + i) * u * 3;
      c.drawPath(
        Path()
          ..moveTo(fx, h * 0.60)
          ..quadraticBezierTo(
            fx + side * w * (0.05 + i * 0.008),
            h * 0.50 + lift,
            fx + side * w * (0.10 + i * 0.012),
            h * 0.73,
          ),
        water,
      );
    }
    for (var i = 0; i < 6; i++) {
      final t = (ambient + i * 0.17) % 1;
      circle(c, Offset(fx + (i - 3) * w * 0.02, h * 0.61 - t * h * 0.05), u * 2,
          const Color(0x99E8FAFF));
    }

    // Benches and lamps.
    _bench(c, w * 0.15, h * 0.70, 1.0);
    _bench(c, w * 0.73, h * 0.70, 0.9);
    for (final x in const [0.09, 0.92]) {
      line(c, Offset(w * x, h * 0.34), Offset(w * x, h * 0.66), const Color(0xFF3F4A4F), u * 3);
      circle(c, Offset(w * x, h * 0.33), u * 9, const Color(0xFFFFE7A8));
      radialGlow(c, Offset(w * x, h * 0.33), u * 32, const Color(0xFFFFE7A8), 0.3);
    }
    // Tree.
    _tree(c, w * 0.04, h * 0.68, 1.1);
    _tree(c, w * 0.86, h * 0.69, 0.9);

    // String lights across the square.
    final wire = Path()
      ..moveTo(0, h * 0.22)
      ..quadraticBezierTo(w * 0.5, h * 0.34, w, h * 0.20);
    path(c, wire, const Color(0x884A3A30), u * 1.4);
    for (var i = 0; i < 13; i++) {
      final t = (i + 0.5) / 13;
      final x = w * t;
      final y = h * (0.22 + math.sin(t * math.pi) * 0.12);
      circle(c, Offset(x, y), u * 3.4,
          const Color(0xFFFFE3A0).withAlpha(180 + (i % 2) * 60));
      radialGlow(c, Offset(x, y), u * 12, const Color(0xFFFFE3A0), 0.25);
    }

    // Pigeons.
    for (final p in const [Offset(0.30, 0.84), Offset(0.36, 0.88), Offset(0.62, 0.86)]) {
      oval(c, Rect.fromCenter(center: Offset(w * p.dx, h * p.dy), width: u * 14, height: u * 8),
          const Color(0xFF6B6B76));
      circle(c, Offset(w * p.dx + u * 7, h * p.dy - u * 3), u * 3.5, const Color(0xFF55555F));
      line(c, Offset(w * p.dx + u * 10, h * p.dy - u * 3),
          Offset(w * p.dx + u * 14, h * p.dy - u * 5), const Color(0xFFD9A441), u * 1.5);
    }
  }

  void _bench(Canvas c, double x, double y, double scale) {
    final s = u * scale;
    rrect(c, x - 55 * s, y - 34 * s, 110 * s, 10 * s, 3 * s, const Color(0xFF8A5A34));
    rrect(c, x - 55 * s, y - 18 * s, 110 * s, 8 * s, 3 * s, const Color(0xFF9C6B40));
    for (final dx in const [-48.0, 48.0]) {
      line(c, Offset(x + dx * s, y - 8 * s), Offset(x + dx * s, y + 22 * s),
          const Color(0xFF3F3A35), 4 * s);
    }
    line(c, Offset(x - 55 * s, y - 34 * s), Offset(x - 55 * s, y - 4 * s),
        const Color(0xFF3F3A35), 4 * s);
    line(c, Offset(x + 55 * s, y - 34 * s), Offset(x + 55 * s, y - 4 * s),
        const Color(0xFF3F3A35), 4 * s);
  }

  void _tree(Canvas c, double x, double baseY, double scale) {
    final s = u * scale;
    rect(c, x - 7 * s, baseY - 120 * s, 14 * s, 120 * s, const Color(0xFF6B4A2E));
    for (var i = 0; i < 5; i++) {
      final cx = x + math.cos(i * 1.7) * 34 * s;
      final cy = baseY - 138 * s + math.sin(i * 1.3) * 22 * s;
      circle(c, Offset(cx, cy), 42 * s,
          Color.lerp(const Color(0xFF2F5A32), const Color(0xFF6C9E55), i / 5)!);
    }
    for (var i = 0; i < 15; i++) {
      final a = i / 15 * math.pi * 2;
      circle(c, Offset(x + math.cos(a) * 52 * s, baseY - 140 * s + math.sin(a) * 38 * s),
          10 * s, const Color(0xAA6C9E55));
    }
  }
}

class ChurchArtist extends VenueArtist {
  ChurchArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    room(
      c,
      wallTop: const Color(0xFF1B1530),
      wallBottom: const Color(0xFF5A3D63),
      floorFar: const Color(0xFF5B5366),
      floorNear: const Color(0xFF211A29),
      horizon: 0.60,
    );
    tileFloor(c, far: const Color(0xFF5B5366), near: const Color(0xFF211A29),
        horizon: 0.60, columns: 6, rows: 5, lineColor: const Color(0x22000000));

    // Three tall stained-glass windows.
    _archWindow(c, w * 0.12, h * 0.08, w * 0.15, h * 0.44, const [
      Color(0xFF5B7FDB), Color(0xFFB45FAD), Color(0xFFFFC857),
    ]);
    _archWindow(c, w * 0.425, h * 0.05, w * 0.15, h * 0.47, const [
      Color(0xFFFF8A8A), Color(0xFF6FA8DC), Color(0xFFFFD966),
    ]);
    _archWindow(c, w * 0.73, h * 0.08, w * 0.15, h * 0.44, const [
      Color(0xFF93C47D), Color(0xFF8E7CC3), Color(0xFFF6B26B),
    ]);
    // Light beams pooling on the floor.
    for (final x in const [0.19, 0.50, 0.80]) {
      poly(c, [
        Offset(w * x, h * 0.26),
        Offset(w * (x + 0.15), h * 0.96),
        Offset(w * (x + 0.04), h * 0.98),
        Offset(w * (x - 0.06), h * 0.30),
      ], const Color(0x14FFE8B5));
    }

    // Altar.
    final ax = w * 0.50;
    rrect(c, ax - w * 0.12, h * 0.55, w * 0.24, h * 0.045, u * 4,
        const Color(0xFF8F7448));
    rrect(c, ax - w * 0.13, h * 0.59, w * 0.26, h * 0.16, u * 3,
        const Color(0xFFE9DCC3));
    rect(c, ax - w * 0.12, h * 0.59, w * 0.24, h * 0.012,
        const Color(0xFFC9B58F));
    // Cross.
    line(c, Offset(ax, h * 0.17), Offset(ax, h * 0.33), const Color(0xFFD8B96A), u * 5);
    line(c, Offset(ax - u * 20, h * 0.22), Offset(ax + u * 20, h * 0.22),
        const Color(0xFFD8B96A), u * 5);
    radialGlow(c, Offset(ax, h * 0.24), u * 70, const Color(0xFFFFE3A3), 0.22);
    // Candles on the altar.
    for (final dx in const [-0.07, -0.035, 0.0, 0.035, 0.07]) {
      final cx = ax + w * dx;
      rrect(c, cx - u * 3, h * 0.50, u * 6, h * 0.05, u * 2,
          const Color(0xFFF0E6D2));
      final flicker = 1 + math.sin(ambient * math.pi * 12 + dx * 100) * 0.25;
      oval(c, Rect.fromCenter(center: Offset(cx, h * 0.495 - u * 4 * flicker),
          width: u * 5, height: u * 12 * flicker), const Color(0xFFFFD27A));
      radialGlow(c, Offset(cx, h * 0.49), u * 22, const Color(0xFFFFC857), 0.30);
    }

    // Pews, split by a centre aisle.
    for (var row = 0; row < 3; row++) {
      final y = h * (0.68 + row * 0.09);
      final scale = 0.7 + row * 0.18;
      _pew(c, w * 0.24, y, w * 0.22, scale);
      _pew(c, w * 0.54, y, w * 0.22, scale);
    }

    // Candle rack.
    for (var i = 0; i < 3; i++) {
      final x = w * 0.055 + i * u * 20;
      line(c, Offset(x, h * 0.62), Offset(x, h * 0.72), const Color(0xFF3B3B3B), u * 2);
      oval(c, Rect.fromCenter(center: Offset(x, h * 0.615), width: u * 4, height: u * 8),
          const Color(0xFFFFD27A));
    }
    for (var i = 0; i < 4; i++) {
      final t = (i + 0.5) / 4;
      final x = w * t;
      line(c, Offset(x, 0), Offset(x, h * 0.06), const Color(0xFF2A2220), u * 1.5);
      circle(c, Offset(x, h * 0.075), u * 4, const Color(0xFFFFE3A0).withAlpha(120));
    }
  }

  void _archWindow(Canvas c, double x, double y, double wd, double ht, List<Color> palette) {
    final rect = Rect.fromLTWH(x, y, wd, ht);
    final arch = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top + rect.height * 0.22)
      ..quadraticBezierTo(rect.center.dx, rect.top - rect.height * 0.08,
          rect.right, rect.top + rect.height * 0.22)
      ..lineTo(rect.right, rect.bottom)
      ..close();
    c.save();
    c.clipPath(arch);
    vertical(c, rect, [palette[0], palette[1], palette[2]]);
    // Leaded panes.
    final lead = Paint()
      ..color = const Color(0xAA241A2E)
      ..strokeWidth = u * 1.5;
    for (var i = 1; i < 5; i++) {
      final yy = rect.top + rect.height * i / 5;
      c.drawLine(Offset(rect.left, yy), Offset(rect.right, yy), lead);
    }
    for (var i = 1; i < 3; i++) {
      final xx = rect.left + rect.width * i / 3;
      c.drawLine(Offset(xx, rect.top), Offset(xx, rect.bottom), lead);
    }
    // A simple figure in the glass.
    circle(c, Offset(rect.center.dx, rect.top + rect.height * 0.40), rect.width * 0.12,
        const Color(0xAAFFE8B5));
    poly(c, [
      Offset(rect.center.dx - rect.width * 0.16, rect.bottom - rect.height * 0.12),
      Offset(rect.center.dx, rect.top + rect.height * 0.44),
      Offset(rect.center.dx + rect.width * 0.16, rect.bottom - rect.height * 0.12),
    ], const Color(0x99FFE8B5));
    c.restore();
    c.drawPath(
      arch,
      Paint()
        ..color = const Color(0xFF3A2A3E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 6,
    );
    radialGlow(c, rect.center, rect.width * 0.9, palette[1], 0.18);
  }

  void _pew(Canvas c, double x, double y, double wd, double scale) {
    final s = u * scale;
    rrect(c, x, y - 22 * s, wd, 12 * s, 3 * s, const Color(0xFF6B4527));
    rrect(c, x, y - 4 * s, wd, 10 * s, 3 * s, const Color(0xFF8A5A34));
    rrect(c, x, y - 52 * s, wd, 30 * s, 4 * s, const Color(0xFF5A3A22));
    for (final dx in [0.03, 0.94]) {
      line(c, Offset(x + wd * dx, y + 6 * s), Offset(x + wd * dx, y + 30 * s),
          const Color(0xFF3F2A1A), 4 * s);
    }
  }
}

class ParkArtist extends VenueArtist {
  ParkArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    vertical(c, Rect.fromLTWH(0, 0, w, h * 0.55), [
      const Color(0xFF6FB9DC),
      const Color(0xFFFFE0A6),
    ]);
    final sun = Offset(w * 0.76, h * 0.16);
    radialGlow(c, sun, w * 0.22, const Color(0xFFFFE7B0), 0.6);
    circle(c, sun, h * 0.05, const Color(0xFFFFF4D8));
    for (final p in const [Offset(0.18, 0.14), Offset(0.46, 0.09)]) {
      oval(c, Rect.fromCenter(center: Offset(w * p.dx, h * p.dy), width: w * 0.14, height: h * 0.04),
          const Color(0x55FFFFFF));
    }
    // Distant tree line.
    for (var i = 0; i < 14; i++) {
      final x = w * (i / 13);
      final r = h * (0.06 + (i % 3) * 0.018);
      circle(c, Offset(x, h * 0.54 - r * 0.4), r, const Color(0xFF4E7A46));
    }
    // Grass.
    vertical(c, Rect.fromLTWH(0, h * 0.55, w, h * 0.45), [
      const Color(0xFF5A8F4A),
      const Color(0xFF2F5A32),
    ]);
    // Curving path.
    final pathShape = Path()
      ..moveTo(w * 0.18, h)
      ..quadraticBezierTo(w * 0.30, h * 0.76, w * 0.46, h * 0.56)
      ..lineTo(w * 0.53, h * 0.56)
      ..quadraticBezierTo(w * 0.40, h * 0.78, w * 0.34, h)
      ..close();
    c.drawPath(pathShape, Paint()..color = const Color(0xFFC7A981));
    c.drawPath(
      pathShape,
      Paint()
        ..color = const Color(0x22FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 2,
    );

    // Pond.
    final pond = Rect.fromCenter(center: Offset(w * 0.79, h * 0.78), width: w * 0.34, height: h * 0.22);
    oval(c, pond, const Color(0xFF4A8FA8));
    oval(c, pond.deflate(u * 4), const Color(0xFF6FB9C9));
    for (var i = 0; i < 5; i++) {
      final t = (ambient + i * 0.21) % 1;
      oval(
        c,
        Rect.fromCenter(
          center: Offset(pond.left + pond.width * (0.2 + i * 0.15), pond.top + pond.height * 0.4 + t * pond.height * 0.35),
          width: u * (18 + i * 5),
          height: u * 4,
        ),
        const Color(0x66E8FAFF),
      );
    }
    // Ducks.
    for (final p in const [Offset(0.73, 0.75), Offset(0.83, 0.80)]) {
      oval(c, Rect.fromCenter(center: Offset(w * p.dx, h * p.dy), width: u * 18, height: u * 10),
          const Color(0xFFF2E8D6));
      circle(c, Offset(w * p.dx + u * 7, h * p.dy - u * 6), u * 5, const Color(0xFFF2E8D6));
      line(c, Offset(w * p.dx + u * 11, h * p.dy - u * 6),
          Offset(w * p.dx + u * 16, h * p.dy - u * 5), const Color(0xFFE69138), u * 2);
    }

    // Trees.
    _tree(c, w * 0.10, h * 0.72, 1.5, const Color(0xFF2F5A32));
    _tree(c, w * 0.93, h * 0.70, 1.1, const Color(0xFF37693A));
    _tree(c, w * 0.60, h * 0.60, 0.7, const Color(0xFF3F7A40));

    // Outdoor gym frame.
    final gx = w * 0.03;
    line(c, Offset(gx, h * 0.56), Offset(gx, h * 0.82), const Color(0xFF56606A), u * 4);
    line(c, Offset(gx + u * 100, h * 0.56), Offset(gx + u * 100, h * 0.82),
        const Color(0xFF56606A), u * 4);
    line(c, Offset(gx, h * 0.56), Offset(gx + u * 100, h * 0.56),
        const Color(0xFF6C7680), u * 4);
    for (var i = 0; i < 3; i++) {
      line(c, Offset(gx + u * (20 + i * 28), h * 0.56),
          Offset(gx + u * (20 + i * 28), h * 0.50), const Color(0xFF6C7680), u * 3);
    }
    // Bench in the foreground.
    final bx = w * 0.62;
    final by = h * 0.90;
    rrect(c, bx - u * 80, by - u * 18, u * 160, u * 12, u * 4, const Color(0xFF8A5A34));
    rrect(c, bx - u * 80, by, u * 160, u * 9, u * 4, const Color(0xFFA9713F));
    line(c, Offset(bx - u * 60, by + u * 8), Offset(bx - u * 62, by + u * 40),
        const Color(0xFF3F3A35), u * 4);
    line(c, Offset(bx + u * 60, by + u * 8), Offset(bx + u * 62, by + u * 40),
        const Color(0xFF3F3A35), u * 4);
    // Flowers.
    for (var i = 0; i < 16; i++) {
      final x = w * (0.06 + (i * 0.059) % 0.88);
      final y = h * (0.72 + (i % 5) * 0.045);
      circle(c, Offset(x, y), u * 2.5,
          i.isEven ? const Color(0xFFFFD966) : const Color(0xFFE06666));
      circle(c, Offset(x, y), u * 1.1, const Color(0xFF6B4A2E));
    }
    // Birds.
    final bird = Paint()
      ..color = const Color(0x992A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 1.6;
    for (final p in const [Offset(0.30, 0.12), Offset(0.36, 0.16), Offset(0.25, 0.20)]) {
      final x = w * p.dx + math.sin(ambient * 6 + p.dx * 10) * u * 4;
      final y = h * p.dy;
      c.drawPath(
        Path()
          ..moveTo(x - u * 6, y)
          ..quadraticBezierTo(x - u * 2, y - u * 5, x, y)
          ..quadraticBezierTo(x + u * 2, y - u * 5, x + u * 6, y),
        bird,
      );
    }
  }

  void _tree(Canvas c, double x, double baseY, double scale, Color tint) {
    final s = u * scale;
    rect(c, x - 9 * s, baseY - 130 * s, 18 * s, 130 * s, const Color(0xFF5A3E29));
    for (var i = 0; i < 6; i++) {
      final angle = i / 6 * math.pi * 2;
      circle(
        c,
        Offset(x + math.cos(angle) * 46 * s, baseY - 150 * s + math.sin(angle) * 34 * s),
        44 * s,
        Color.lerp(tint, const Color(0xFF7EBB6E), (i % 3) / 5)!,
      );
    }
    circle(c, Offset(x, baseY - 152 * s), 58 * s, tint);
  }
}

class BankArtist extends VenueArtist {
  BankArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    room(
      c,
      wallTop: const Color(0xFF1E2D38),
      wallBottom: const Color(0xFF708899),
      floorFar: const Color(0xFF2C3C46),
      floorNear: const Color(0xFF0D151A),
      horizon: 0.60,
    );
    tileFloor(c, far: const Color(0xFF2C3C46), near: const Color(0xFF0D151A),
        horizon: 0.60, columns: 7, rows: 4, lineColor: const Color(0x33D9F4FF));

    // Tall windows between marble columns.
    for (final x in const [0.14, 0.76]) {
      windowBox(
        c,
        Rect.fromLTWH(w * x, h * 0.13, w * 0.12, h * 0.40),
        skyTop: const Color(0xFF9FD7F0),
        skyBottom: const Color(0xFFE8F6FF),
        mullions: 2,
      );
    }
    for (final x in const [0.035, 0.28, 0.68, 0.925]) {
      rect(c, w * x - u * 10, h * 0.05, u * 24, h * 0.56,
          const Color(0xFF8FA2B0));
      rect(c, w * x - u * 14, h * 0.05, u * 32, u * 10,
          const Color(0xFFB9C8D4));
      rect(c, w * x - u * 14, h * 0.58, u * 32, u * 10,
          const Color(0xFFB9C8D4));
      for (var i = 0; i < 7; i++) {
        line(c, Offset(w * x - u * 8 + i * u * 5, h * 0.07),
            Offset(w * x - u * 8 + i * u * 5, h * 0.58),
            const Color(0x22FFFFFF), u * 1.2);
      }
    }

    // Chandelier.
    line(c, Offset(w * 0.5, 0), Offset(w * 0.5, h * 0.10), const Color(0xFF3A3A3A), u * 2);
    for (var i = 0; i < 5; i++) {
      final x = w * 0.5 + (i - 2) * u * 13;
      line(c, Offset(w * 0.5, h * 0.10), Offset(x, h * 0.15), const Color(0xFFB9A05A), u * 2);
      circle(c, Offset(x, h * 0.16), u * 3.5, const Color(0xFFFFE3A0));
    }
    radialGlow(c, Offset(w * 0.5, h * 0.16), u * 90, const Color(0xFFFFE3A0), 0.25);

    // Teller counter.
    final cy = h * 0.58;
    rrect(c, w * 0.24, cy, w * 0.52, h * 0.16, u * 6, const Color(0xFF5B4330));
    rrect(c, w * 0.24, cy, w * 0.52, u * 12, u * 3, const Color(0xFFD9D2C3));
    for (var i = 0; i < 4; i++) {
      final x = w * (0.30 + i * 0.12);
      rect(c, x, cy - h * 0.10, w * 0.10, h * 0.10, const Color(0x22303A44));
      for (var b = 0; b < 4; b++) {
        line(c, Offset(x + u * (5 + b * 8), cy - h * 0.09),
            Offset(x + u * (5 + b * 8), cy - u * 3), const Color(0xFFB9A05A), u * 2);
      }
      line(c, Offset(x + w * 0.05, cy - h * 0.10), Offset(x + w * 0.05, 0),
          const Color(0x22D9F4FF), u * 1);
    }
    // Brass lamp and papers on the counter.
    rrect(c, w * 0.46, cy - u * 22, u * 8, u * 20, u * 2, const Color(0xFFB9A05A));
    poly(c, [
      Offset(w * 0.455, cy - u * 22),
      Offset(w * 0.48, cy - u * 22),
      Offset(w * 0.475, cy - u * 32),
      Offset(w * 0.46, cy - u * 32),
    ], const Color(0xFFE8D8A8));
    radialGlow(c, Offset(w * 0.468, cy - u * 24), u * 34, const Color(0xFFFFE7B0), 0.3);
    rrect(c, w * 0.57, cy - u * 8, u * 34, u * 10, u * 1,
        const Color(0xFFF5F1E6));

    // Vault door.
    final vault = Offset(w * 0.88, h * 0.52);
    circle(c, vault, u * 52, const Color(0xFF4A5660));
    circle(c, vault, u * 44, const Color(0xFF6E7C88));
    circle(c, vault, u * 34, const Color(0xFF56636E));
    for (var i = 0; i < 8; i++) {
      final a = i / 8 * math.pi * 2 + ambient * 0.1;
      line(c, vault, vault + Offset(math.cos(a), math.sin(a)) * u * 32,
          const Color(0xFF8F9EAA), u * 3);
    }
    circle(c, vault, u * 8, const Color(0xFFD8C27A));

    // Queue posts and rope.
    for (final x in const [0.08, 0.20, 0.32]) {
      circle(c, Offset(w * x, h * 0.85), u * 5, const Color(0xFFB9A05A));
      line(c, Offset(w * x, h * 0.86), Offset(w * x, h * 0.93), const Color(0xFFB9A05A), u * 3);
    }
    path(c, Path()
      ..moveTo(w * 0.08, h * 0.855)
      ..quadraticBezierTo(w * 0.14, h * 0.90, w * 0.20, h * 0.855)
      ..quadraticBezierTo(w * 0.26, h * 0.90, w * 0.32, h * 0.855),
        const Color(0xFF8F3E42), u * 3);

    plant(c, Offset(w * 0.06, h * 0.63), 1.2);
  }
}

class PoliceArtist extends VenueArtist {
  PoliceArtist(super.venue, super.ambient, super.reaction);

  @override
  void paintScene(Canvas c) {
    room(
      c,
      wallTop: const Color(0xFF1E2A35),
      wallBottom: const Color(0xFF4A5D6B),
      floorFar: const Color(0xFF303C47),
      floorNear: const Color(0xFF141C23),
      horizon: 0.60,
    );
    tileFloor(c, far: const Color(0xFF303C47), near: const Color(0xFF141C23),
        horizon: 0.60, columns: 8, rows: 4);
    // Blue stripe.
    rect(c, 0, h * 0.46, w, h * 0.035, const Color(0xFF2D5B8A));
    rect(c, 0, h * 0.495, w, h * 0.008, const Color(0xFF7DB8FF));

    // Barred window with dusk outside.
    final wr = Rect.fromLTWH(w * 0.03, h * 0.10, w * 0.18, h * 0.30);
    windowBox(c, wr, skyTop: const Color(0xFF2E4468), skyBottom: const Color(0xFF6A5A78),
        mullions: 1);
    for (var i = 1; i < 5; i++) {
      line(c, Offset(wr.left + wr.width * i / 5, wr.top),
          Offset(wr.left + wr.width * i / 5, wr.bottom),
          const Color(0xFF2A3138), u * 4);
    }

    // Notice board.
    rrect(c, w * 0.24, h * 0.12, w * 0.20, h * 0.28, u * 4,
        const Color(0xFF5B4330));
    rrect(c, w * 0.245, h * 0.13, w * 0.19, h * 0.26, u * 2,
        const Color(0xFF8A7458));
    for (var i = 0; i < 7; i++) {
      final x = w * (0.255 + (i % 3) * 0.06);
      final y = h * (0.15 + (i ~/ 3) * 0.075);
      rrect(c, x, y, w * 0.05, h * 0.06, u * 1,
          const Color(0xFFF2E9D8));
      line(c, Offset(x + u * 4, y + u * 5), Offset(x + w * 0.045, y + u * 5),
          const Color(0xFF5B5B5B), u * 1);
      line(c, Offset(x + u * 4, y + u * 9), Offset(x + w * 0.038, y + u * 9),
          const Color(0xFF8A8A8A), u * 1);
      circle(c, Offset(x + w * 0.025, y + u * 2.5), u * 1.5,
          const Color(0xFFD9534F));
    }

    // Front desk.
    final dy = h * 0.60;
    rrect(c, w * 0.32, dy, w * 0.34, h * 0.15, u * 6, const Color(0xFF4A3C32));
    rrect(c, w * 0.32, dy, w * 0.34, u * 11, u * 3, const Color(0xFFD9D2C3));
    rect(c, w * 0.34, dy + u * 11, w * 0.30, h * 0.03, const Color(0xFF2D5B8A));
    // Monitor and shield.
    rrect(c, w * 0.37, dy - u * 34, u * 40, u * 26, u * 3,
        const Color(0xFF20262B));
    rect(c, w * 0.385, dy - u * 28, u * 28, u * 16, const Color(0xFF7DB8FF));
    poly(c, [
      Offset(w * 0.55, dy - u * 36),
      Offset(w * 0.57, dy - u * 28),
      Offset(w * 0.55, dy - u * 14),
      Offset(w * 0.53, dy - u * 28),
    ], const Color(0xFFD9B75C));
    // Chair behind the desk.
    rrect(c, w * 0.47, dy - u * 58, u * 34, u * 30, u * 8,
        const Color(0xFF2E3A44));

    // Filing cabinets.
    for (var i = 0; i < 2; i++) {
      final x = w * (0.80 + i * 0.09);
      rect(c, x, h * 0.44, w * 0.075, h * 0.18, const Color(0xFF59646E));
      for (var d = 0; d < 3; d++) {
        rect(c, x + u * 4, h * (0.455 + d * 0.052), w * 0.064, h * 0.044,
            const Color(0xFF47525B));
        line(c, Offset(x + w * 0.03, h * (0.475 + d * 0.052)),
            Offset(x + w * 0.045, h * (0.475 + d * 0.052)),
            const Color(0xFFB9C8D4), u * 2);
      }
    }

    // Bench.
    rrect(c, w * 0.72, h * 0.69, w * 0.22, u * 10, u * 3, const Color(0xFF6B4A2E));
    rrect(c, w * 0.72, h * 0.60, w * 0.22, u * 28, u * 3, const Color(0xFF4A3C32));
    line(c, Offset(w * 0.74, h * 0.69), Offset(w * 0.74, h * 0.79),
        const Color(0xFF2A2A2A), u * 3);
    line(c, Offset(w * 0.92, h * 0.69), Offset(w * 0.92, h * 0.79),
        const Color(0xFF2A2A2A), u * 3);

    // Flag and ceiling fan.
    line(c, Offset(w * 0.965, h * 0.10), Offset(w * 0.965, h * 0.52),
        const Color(0xFF9AA4AC), u * 2);
    poly(c, [
      Offset(w * 0.965, h * 0.10),
      Offset(w * 0.90, h * 0.13),
      Offset(w * 0.965, h * 0.16),
    ], const Color(0xFF2D5B8A));
    final fan = Offset(w * 0.60, h * 0.08);
    line(c, fan, Offset(w * 0.60, h * 0.04), const Color(0xFF3A3A3A), u * 2);
    for (var i = 0; i < 3; i++) {
      final a = ambient * math.pi * 2 + i * math.pi * 2 / 3;
      line(c, fan, fan + Offset(math.cos(a), math.sin(a)) * u * 34,
          const Color(0xFF8A8A8A), u * 4);
    }
    circle(c, fan, u * 5, const Color(0xFF3A3A3A));

    plant(c, Offset(w * 0.28, h * 0.60), 1.0);
  }
}
