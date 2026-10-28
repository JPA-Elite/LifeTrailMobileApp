import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/venue.dart';

/// Shared drawing surface for the hand-painted venue backdrops.
///
/// Each venue gets a subclass with its own `paintScene`, but they all share
/// the same primitives (walls, floors, windows, plants, lamps, steam and
/// drifting dust) so the town feels like one illustrated world.
abstract class VenueArtist {
  VenueArtist(this.venue, this.ambient, this.reaction);

  final Venue venue;

  /// 0..1, looping slowly. Drives dust, steam, water and shimmer.
  final double ambient;

  /// 1 right after an action, fading to 0. Throws a glow and sparks.
  final double reaction;

  double w = 1;
  double h = 1;
  double u = 1;

  void paint(Canvas canvas, Size size) {
    w = size.width;
    h = size.height;
    u = math.min(w / 1000, h / 560);
    paintScene(canvas);
    _vignette(canvas);
    _reaction(canvas);
  }

  void paintScene(Canvas canvas);

  // --- palettes ----------------------------------------------------------
  Color get dark => venue.background;
  Color get panel => venue.panel;
  Color get accent => venue.accent;
  Color get glowColor => venue.glow;

  Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
  Color alpha(Color c, int a) => c.withAlpha(a);

  // --- primitives --------------------------------------------------------
  void rect(Canvas c, double x, double y, double wd, double ht, Color color) {
    c.drawRect(Rect.fromLTWH(x, y, wd, ht), Paint()..color = color);
  }

  void rrect(
    Canvas c,
    double x,
    double y,
    double wd,
    double ht,
    double r,
    Color color,
  ) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, wd, ht), Radius.circular(r)),
      Paint()..color = color,
    );
  }

  void strokeRRect(
    Canvas c,
    Rect r,
    double radius,
    Color color,
    double width,
  ) {
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  void line(
    Canvas c,
    Offset a,
    Offset b,
    Color color,
    double width, {
    StrokeCap cap = StrokeCap.round,
  }) {
    c.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = cap,
    );
  }

  void circle(Canvas c, Offset center, double radius, Color color) {
    c.drawCircle(center, radius, Paint()..color = color);
  }

  void strokeCircle(
    Canvas c,
    Offset center,
    double radius,
    Color color,
    double width,
  ) {
    c.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  void oval(Canvas c, Rect r, Color color) {
    c.drawOval(r, Paint()..color = color);
  }

  void poly(Canvas c, List<Offset> points, Color color) {
    final p = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      p.lineTo(point.dx, point.dy);
    }
    p.close();
    c.drawPath(p, Paint()..color = color);
  }

  void path(Canvas c, Path p, Color color, [double width = 1]) {
    c.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void vertical(Canvas c, Rect r, List<Color> colors, [List<double>? stops]) {
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(r),
    );
  }

  void radialGlow(Canvas c, Offset center, double radius, Color color,
      [double strength = 0.55]) {
    c.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withAlpha((255 * strength).round()), color.withAlpha(0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  // --- room shells -------------------------------------------------------
  void room(
    Canvas c, {
    required Color wallTop,
    required Color wallBottom,
    required Color floorFar,
    required Color floorNear,
    double horizon = 0.58,
    Color? trim,
  }) {
    vertical(c, Rect.fromLTWH(0, 0, w, h * horizon), [
      wallTop,
      wallBottom,
    ]);
    vertical(c, Rect.fromLTWH(0, h * horizon, w, h * (1 - horizon)), [
      floorFar,
      floorNear,
    ]);
    line(
      c,
      Offset(0, h * horizon),
      Offset(w, h * horizon),
      trim ?? Colors.black.withAlpha(70),
      u * 3,
      cap: StrokeCap.butt,
    );
  }

  void plankFloor(
    Canvas c, {
    required Color far,
    required Color near,
    double horizon = 0.58,
    Color seam = const Color(0x33000000),
  }) {
    final rect = Rect.fromLTWH(0, h * horizon, w, h * (1 - horizon));
    vertical(c, rect, [far, near]);
    for (var i = -6; i <= 6; i++) {
      final x = w / 2 + i * w * 0.12;
      c.drawLine(
        Offset(w / 2 + (x - w / 2) * 0.18, h * horizon),
        Offset(x, h),
        Paint()
          ..color = seam
          ..strokeWidth = u * 1.5,
      );
    }
    for (final t in const [0.25, 0.55, 0.85]) {
      final y = h * horizon + h * (1 - horizon) * t;
      c.drawLine(
        Offset(0, y),
        Offset(w, y),
        Paint()
          ..color = seam
          ..strokeWidth = u * 1.2,
      );
    }
  }

  void tileFloor(
    Canvas c, {
    required Color far,
    required Color near,
    double horizon = 0.58,
    Color lineColor = const Color(0x22000000),
    int columns = 9,
    int rows = 4,
  }) {
    final rect = Rect.fromLTWH(0, h * horizon, w, h * (1 - horizon));
    vertical(c, rect, [far, near]);
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = u * 1.4;
    for (var i = 0; i <= columns; i++) {
      final t = i / columns;
      final xTop = w * 0.5 + (t - 0.5) * w * 0.42;
      final xBottom = w * 0.5 + (t - 0.5) * w * 1.18;
      c.drawLine(
        Offset(xTop, h * horizon),
        Offset(xBottom, h),
        paint,
      );
    }
    for (var i = 1; i <= rows; i++) {
      final t = i / (rows + 1);
      final y = h * horizon + h * (1 - horizon) * t * t;
      c.drawLine(Offset(0, y), Offset(w, y), paint);
    }
  }

  void windowBox(
    Canvas c,
    Rect r, {
    Color frame = const Color(0xFF3B2A24),
    Color skyTop = const Color(0xFFBFE3F7),
    Color skyBottom = const Color(0xFFFFE3B0),
    bool curtains = false,
    double mullions = 2,
  }) {
    final casing = RRect.fromRectAndRadius(r, Radius.circular(u * 10));
    c.drawRRect(casing, Paint()..color = frame);
    final glass = r.deflate(u * 7);
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(glass, Radius.circular(u * 5)));
    vertical(c, glass, [skyTop, skyBottom]);
    final sun = Offset(glass.right - glass.width * 0.24, glass.center.dy);
    radialGlow(c, sun, glass.width * 0.45, const Color(0xFFFFE3A3), 0.5);
    circle(c, sun, glass.shortestSide * 0.09, const Color(0xFFFFF0C2));
    oval(
      c,
      Rect.fromCenter(
        center: Offset(glass.left + glass.width * 0.3, glass.top + glass.height * 0.3),
        width: glass.width * 0.34,
        height: glass.height * 0.09,
      ),
      const Color(0x44FFFFFF),
    );
    c.restore();
    final bar = Paint()..color = frame;
    for (var i = 1; i < mullions; i++) {
      final x = glass.left + glass.width * i / mullions;
      c.drawRect(Rect.fromLTWH(x - u * 3, glass.top, u * 6, glass.height), bar);
    }
    c.drawRect(
      Rect.fromLTWH(glass.left, glass.center.dy - u * 3, glass.width, u * 6),
      bar,
    );
    strokeRRect(c, glass, u * 5, Colors.white.withAlpha(40), u * 1.5);
    if (curtains) {
      poly(c, [
        Offset(r.left - u * 14, r.top),
        Offset(r.left + u * 20, r.top),
        Offset(r.left + u * 26, r.bottom + u * 8),
        Offset(r.left - u * 8, r.bottom + u * 8),
      ], const Color(0xCCE8CDB2));
      poly(c, [
        Offset(r.right + u * 14, r.top),
        Offset(r.right - u * 20, r.top),
        Offset(r.right - u * 26, r.bottom + u * 8),
        Offset(r.right + u * 8, r.bottom + u * 8),
      ], const Color(0xCCE8CDB2));
    }
  }

  void pendant(Canvas c, Offset top, double drop, double scale, Color shade) {
    line(
      c,
      top,
      Offset(top.dx, top.dy + drop),
      const Color(0xFF2A2220),
      u * 2,
    );
    final base = top.dy + drop;
    poly(c, [
      Offset(top.dx - 26 * scale * u / 1.4, base + 26 * scale),
      Offset(top.dx + 26 * scale * u / 1.4, base + 26 * scale),
      Offset(top.dx + 14 * scale * u / 1.4, base),
      Offset(top.dx - 14 * scale * u / 1.4, base),
    ], shade);
    radialGlow(
      c,
      Offset(top.dx, base + 34 * scale),
      70 * scale * u,
      const Color(0xFFFFE3A3),
      0.5,
    );
  }

  void plant(Canvas c, Offset base, double scale) {
    final s = u * scale;
    rrect(c, base.dx - 14 * s, base.dy - 22 * s, 28 * s, 24 * s, 4 * s,
        const Color(0xFF8B5A3C));
    for (var i = 0; i < 7; i++) {
      final angle = -math.pi / 2 + (i - 3) * 0.42 + math.sin(ambient * 6 + i) * 0.03;
      final len = (26 + (i % 3) * 9) * s;
      final end = Offset(
        base.dx + math.cos(angle) * len,
        base.dy - 22 * s + math.sin(angle) * len,
      );
      final mid = Offset(
        base.dx + math.cos(angle - 0.28) * len * 0.55,
        base.dy - 22 * s + math.sin(angle - 0.28) * len * 0.55,
      );
      oval(
        c,
        Rect.fromCenter(center: mid, width: len * 0.55, height: len * 0.24),
        Color.lerp(const Color(0xFF4F8A5B), const Color(0xFF7EBB6E), i / 7)!,
      );
      circle(c, end, len * 0.13, const Color(0xFF3E6F47));
    }
  }

  void stool(Canvas c, double x, double y, double scale, Color seat) {
    final s = u * scale;
    oval(c, Rect.fromCenter(center: Offset(x, y), width: 34 * s, height: 12 * s),
        seat);
    line(c, Offset(x - 12 * s, y), Offset(x - 14 * s, y + 34 * s),
        const Color(0xFF3A2C26), 3 * s);
    line(c, Offset(x + 12 * s, y), Offset(x + 14 * s, y + 34 * s),
        const Color(0xFF3A2C26), 3 * s);
  }

  // --- particles ---------------------------------------------------------
  void dust(Canvas c, {
    int seed = 1,
    Color color = const Color(0xFFFFE8B5),
    int count = 26,
  }) {
    final r = math.Random(seed);
    for (var i = 0; i < count; i++) {
      final baseX = r.nextDouble();
      final baseY = r.nextDouble();
      final speed = 0.3 + r.nextDouble() * 0.8;
      final x = ((baseX + ambient * 0.06 * speed) % 1) * w;
      final y = ((baseY + ambient * speed * 0.18) % 1) * h;
      final size = (0.8 + r.nextDouble() * 2.1) * u;
      circle(c, Offset(x, y), size, color.withAlpha(40 + (i % 3) * 18));
    }
  }

  void motes(Canvas c, {
    int seed = 1,
    Color color = const Color(0xFFFFE3A3),
    int count = 18,
  }) {
    final r = math.Random(seed);
    for (var i = 0; i < count; i++) {
      final baseX = r.nextDouble();
      final baseY = r.nextDouble();
      final phase = r.nextDouble() * math.pi * 2;
      final x = (baseX + math.sin(ambient * math.pi * 2 + phase) * 0.02) * w;
      final y = ((baseY - ambient * 0.12) % 1) * h;
      circle(c, Offset(x, y), (1 + r.nextDouble() * 2) * u,
          color.withAlpha(50 + (i % 4) * 20));
    }
  }

  void steam(Canvas c, Offset origin, Color color) {
    final ox = origin.dx * w;
    final oy = origin.dy * h;
    for (var i = 0; i < 4; i++) {
      final t = (ambient + i * 0.22) % 1;
      final x = ox + math.sin(t * math.pi * 3 + i) * 14 * u;
      final y = oy - t * 120 * u;
      circle(
        c,
        Offset(x, y),
        (5 + t * 15) * u,
        color.withAlpha(((1 - t) * 54).round()),
      );
    }
  }

  void leaves(Canvas c) {
    final r = math.Random(9);
    for (var i = 0; i < 14; i++) {
      final baseX = r.nextDouble();
      final speed = 0.2 + r.nextDouble() * 0.5;
      final x = ((baseX + ambient * speed * 0.25) % 1) * w;
      final y = ((r.nextDouble() + ambient * speed * 0.35) % 1) * h * 0.8;
      final sway = math.sin(ambient * math.pi * 4 + i) * 12 * u;
      final leaf = Rect.fromCenter(
        center: Offset(x + sway, y),
        width: 12 * u,
        height: 5 * u,
      );
      c.save();
      c.translate(leaf.center.dx, leaf.center.dy);
      c.rotate(sway * 0.04);
      oval(
        c,
        Rect.fromCenter(center: Offset.zero, width: leaf.width, height: leaf.height),
        Color.lerp(const Color(0xFF7BA05B), const Color(0xFFD6B85A), i / 14)!,
      );
      c.restore();
    }
  }

  void bubbles(Canvas c, {Color color = const Color(0x66CFF6FF)}) {
    for (var i = 0; i < 10; i++) {
      final t = (ambient + i * 0.13) % 1;
      final x = w * (0.1 + (i % 5) * 0.19) + math.sin(t * 8 + i) * 6 * u;
      final y = h * (1 - t);
      c.drawCircle(
        Offset(x, y),
        (3 + (i % 3) * 2) * u,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 1.3,
      );
    }
  }

  // --- finishing ---------------------------------------------------------
  void _vignette(Canvas c) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    c.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [
            Colors.transparent,
            Colors.black.withAlpha(40),
            Colors.black.withAlpha(130),
          ],
          stops: const [0.55, 0.82, 1],
        ).createShader(rect),
    );
  }

  void _reaction(Canvas c) {
    if (reaction <= 0.002) return;
    final center = Offset(w * 0.38, h * 0.52);
    final fade = reaction.clamp(0.0, 1.0);
    radialGlow(
      c,
      center,
      110 * u + 90 * u * (1 - fade),
      glowColor,
      0.34 * fade,
    );
    final spark = Paint()..color = accent.withAlpha((210 * fade).round());
    for (var i = 0; i < 9; i++) {
      final angle = i / 9 * math.pi * 2 + fade * 1.6;
      final distance = (40 + (1 - fade) * 150) * u;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      c.drawCircle(p, (3.2 - (1 - fade) * 1.4).clamp(0.7, 3.2) * u, spark);
    }
  }
}
