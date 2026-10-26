import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/world/interactable.dart' show RelaxSpot;
import 'relax_scene_screen.dart';

/// The town-bench flavour of [RelaxSceneScreen]: the player sits on a park
/// bench in the afternoon sun while the town drifts past, and happiness
/// ticks up just like it does on the home sofa.
class BenchRelaxScreen extends StatelessWidget {
  const BenchRelaxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RelaxSceneScreen(
      spot: RelaxSpot.bench,
      painterBuilder: (ambient, breath, celebrating) => _ParkPainter(
        ambient: ambient,
        breath: breath,
        celebrating: celebrating,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The scene painter
// ---------------------------------------------------------------------------

class _Petal {
  const _Petal({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.color,
  });

  final double x;
  final double phase;
  final double speed;
  final double size;
  final Color color;
}

class _ParkPainter extends CustomPainter {
  _ParkPainter({
    required this.ambient,
    required this.breath,
    required this.celebrating,
  });

  /// 0..1, looping slowly: drifts clouds, petals and the pigeons.
  final double ambient;

  /// 0..1, looping back and forth: breathing, steam and leaf shimmer.
  final double breath;

  final bool celebrating;

  static const double _designW = 1000;
  static const double _designH = 600;

  static final List<_Petal> _petals = () {
    final r = math.Random(19);
    const colors = [
      Color(0xFFFFC2CE),
      Color(0xFFFFE0B8),
      Color(0xFFD7E8AE),
      Color(0xFFF6D6E6),
      Color(0xFFFFF1D2),
    ];
    return List.generate(34, (_) {
      return _Petal(
        x: r.nextDouble() * 1000,
        phase: r.nextDouble(),
        speed: 0.32 + r.nextDouble() * 0.7,
        size: 3.0 + r.nextDouble() * 4.2,
        color: colors[r.nextInt(colors.length)],
      );
    });
  }();

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackdrop(canvas, size);

    final scale = math.min(size.width / _designW, size.height / _designH);
    final dy = (size.height - _designH * scale) / 2;

    canvas.save();
    canvas.translate(0, dy);
    canvas.scale(scale);

    _paintSky(canvas);
    _paintSun(canvas);
    _paintClouds(canvas);
    _paintHills(canvas);
    _paintTreeLine(canvas);
    _paintGrass(canvas);
    _paintPath(canvas);
    _paintFlowers(canvas);
    _paintLamp(canvas);
    _paintFramingTrees(canvas);
    _paintBench(canvas);
    _paintPigeons(canvas);
    _paintFigure(canvas);
    _paintGlows(canvas);
    _paintPetals(canvas);
    _paintVignette(canvas);

    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas, Size size) {
    final sky = Rect.fromLTWH(0, 0, size.width, size.height * 0.62);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FA9BD), Color(0xFFB9DCCB), Color(0xFFF4DEB6)],
          stops: [0, 0.58, 1],
        ).createShader(sky),
    );
    final grass = Rect.fromLTWH(
      0,
      size.height * 0.62,
      size.width,
      size.height * 0.38,
    );
    canvas.drawRect(
      grass,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FA35D), Color(0xFF294A34)],
        ).createShader(grass),
    );
  }

  void _paintSky(Canvas canvas) {
    final sky = Rect.fromLTWH(0, 0, _designW, 380);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7FB9CF), Color(0xFFBCDFD2), Color(0xFFFBE3BD)],
          stops: [0, 0.56, 1],
        ).createShader(sky),
    );

    // Warm haze along the horizon.
    canvas.drawRect(
      const Rect.fromLTWH(0, 300, _designW, 90),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00FFE3B8), Color(0x55FFE3B8)],
        ).createShader(const Rect.fromLTWH(0, 300, _designW, 90)),
    );
  }

  void _paintSun(Canvas canvas) {
    const sun = Offset(790, 116);
    canvas.drawCircle(
      sun,
      170,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE8B0).withAlpha(120),
            const Color(0xFFFFE8B0).withAlpha(0),
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: 170)),
    );
    canvas.drawCircle(sun, 46, Paint()..color = const Color(0xFFFFF3CC));
    canvas.drawCircle(
      sun,
      58,
      Paint()
        ..color = const Color(0x33FFF3CC)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  void _paintClouds(Canvas canvas) {
    final drift = (ambient * 26) % 60;
    final cloud = Paint()..color = Colors.white.withAlpha(120);
    final shade = Paint()..color = const Color(0x33A9C6C0);

    void puff(double cx, double cy, double w, double h) {
      final r = Rect.fromCenter(
        center: Offset(cx + drift, cy),
        width: w,
        height: h,
      );
      canvas.drawOval(r, shade);
      canvas.drawOval(r.shift(const Offset(0, -3)), cloud);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - w * 0.2 + drift, cy - h * 0.45),
          width: w * 0.6,
          height: h * 0.9,
        ),
        cloud,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + w * 0.2 + drift, cy - h * 0.3),
          width: w * 0.52,
          height: h * 0.8,
        ),
        cloud,
      );
    }

    puff(170, 96, 170, 44);
    puff(235, 122, 110, 30);
    puff(620, 66, 130, 34);
    puff(690, 84, 88, 24);
  }

  void _paintHills(Canvas canvas) {
    // Far ridge.
    final far = Path()
      ..moveTo(-30, 372)
      ..quadraticBezierTo(110, 292, 250, 348)
      ..quadraticBezierTo(400, 290, 545, 350)
      ..quadraticBezierTo(690, 300, 830, 352)
      ..quadraticBezierTo(930, 320, 1030, 364)
      ..lineTo(1030, 420)
      ..lineTo(-30, 420)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFF87AE86));

    final mid = Path()
      ..moveTo(-30, 392)
      ..quadraticBezierTo(150, 344, 300, 382)
      ..quadraticBezierTo(470, 336, 640, 388)
      ..quadraticBezierTo(790, 350, 1030, 396)
      ..lineTo(1030, 440)
      ..lineTo(-30, 440)
      ..close();
    canvas.drawPath(mid, Paint()..color = const Color(0xFF6A9A6E));
  }

  void _paintTreeLine(Canvas canvas) {
    // A soft band of canopies closing off the horizon.
    const greens = [
      Color(0xFF4E8153),
      Color(0xFF3F7047),
      Color(0xFF5B9160),
      Color(0xFF356241),
    ];
    const spots = [
      (x: -10.0, y: 360.0, r: 70.0, shade: 0),
      (x: 60.0, y: 352.0, r: 58.0, shade: 1),
      (x: 130.0, y: 366.0, r: 66.0, shade: 2),
      (x: 210.0, y: 350.0, r: 54.0, shade: 3),
      (x: 285.0, y: 362.0, r: 62.0, shade: 0),
      (x: 355.0, y: 348.0, r: 50.0, shade: 2),
      (x: 430.0, y: 364.0, r: 68.0, shade: 1),
      (x: 520.0, y: 350.0, r: 56.0, shade: 3),
      (x: 600.0, y: 366.0, r: 72.0, shade: 0),
      (x: 695.0, y: 352.0, r: 54.0, shade: 2),
      (x: 775.0, y: 364.0, r: 64.0, shade: 1),
      (x: 860.0, y: 348.0, r: 52.0, shade: 3),
      (x: 930.0, y: 362.0, r: 68.0, shade: 0),
      (x: 1010.0, y: 352.0, r: 58.0, shade: 2),
    ];
    for (final spot in spots) {
      final color = greens[spot.shade];
      final center = Offset(spot.x, spot.y);
      canvas.drawCircle(
        center + Offset(0, spot.r * 0.42),
        spot.r * 0.55,
        Paint()..color = color,
      );
      canvas.drawCircle(
        center + Offset(-spot.r * 0.4, 0),
        spot.r * 0.6,
        Paint()..color = color,
      );
      canvas.drawCircle(
        center + Offset(spot.r * 0.42, 4),
        spot.r * 0.58,
        Paint()..color = color,
      );
    }

    // Haze over the tree line so it sits back in the distance.
    canvas.drawRect(
      const Rect.fromLTWH(0, 300, _designW, 92),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00FFE8C4), Color(0x44FFE8C4)],
        ).createShader(const Rect.fromLTWH(0, 300, _designW, 92)),
    );
  }

  void _paintGrass(Canvas canvas) {
    final grass = Rect.fromLTWH(0, 372, _designW, 228);
    canvas.drawRect(
      grass,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7EAE63), Color(0xFF517F4C), Color(0xFF2E5339)],
          stops: [0, 0.5, 1],
        ).createShader(grass),
    );

    // A soft sunlit band across the middle of the green.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(640, 430), width: 620, height: 130),
      Paint()
        ..shader =
            RadialGradient(
              colors: [const Color(0x55FFE2A8), const Color(0x00FFE2A8)],
            ).createShader(
              Rect.fromCenter(
                center: const Offset(640, 430),
                width: 620,
                height: 130,
              ),
            ),
    );

    // Grass blades: two hundred tiny strokes, deterministic and cheap.
    final blade = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 220; i++) {
      final x = (i * 53.7) % _designW;
      final y = 392 + ((i * 29.3) % 200);
      final sway = math.sin((ambient * 2 + i * 0.37) * math.pi * 2) * 2.4;
      blade.color =
          (i.isEven ? const Color(0xFF3C6B45) : const Color(0xFF8FBE72))
              .withAlpha(i.isEven ? 90 : 70);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + sway, y - 7 - (i % 4) * 2.2),
        blade,
      );
    }
  }

  void _paintPath(Canvas canvas) {
    final path = Path()
      ..moveTo(-30, 600)
      ..lineTo(-30, 516)
      ..cubicTo(170, 500, 330, 474, 480, 470)
      ..cubicTo(660, 464, 830, 502, 1030, 512)
      ..lineTo(1030, 600)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7D3A9), Color(0xFFCDB182), Color(0xFFB7976B)],
        ).createShader(const Rect.fromLTWH(0, 464, _designW, 136)),
    );

    // Sunlit top edge of the paving.
    canvas.drawPath(
      Path()
        ..moveTo(-30, 518)
        ..cubicTo(170, 502, 330, 476, 480, 472)
        ..cubicTo(660, 466, 830, 504, 1030, 514),
      Paint()
        ..color = const Color(0x88FFF0CE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Flagstone seams fanning across the path.
    final seam = Paint()
      ..color = const Color(0x335E4326)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 9; i++) {
      final x = -20 + i * 130.0;
      final y = 520 + math.sin(i * 1.4) * 8;
      canvas.drawLine(Offset(x, y), Offset(x + 46, 600), seam);
    }
    // Pebbles.
    final pebble = Paint()..color = const Color(0x445E4326);
    for (var i = 0; i < 40; i++) {
      final x = (i * 79.3) % _designW;
      final y = 486 + ((i * 41.7) % 100);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 4 + (i % 3) * 2,
          height: 3 + (i % 2) * 2,
        ),
        pebble,
      );
    }
  }

  void _paintFlowers(Canvas canvas) {
    final stem = Paint()
      ..color = const Color(0xFF3E6B41)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    void flower(double x, double y, Color color) {
      final sway = math.sin((ambient + x * 0.01) * math.pi * 2) * 2.5;
      canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + sway, y - 16, x + sway, y - 28),
        stem,
      );
      final center = Offset(x + sway, y - 30);
      for (var i = 0; i < 5; i++) {
        final angle = i * math.pi * 2 / 5 + ambient * 0.5;
        canvas.drawCircle(
          center + Offset(math.cos(angle) * 4.4, math.sin(angle) * 4.4),
          3.8,
          Paint()..color = color,
        );
      }
      canvas.drawCircle(center, 3, Paint()..color = const Color(0xFFFFE08A));
    }

    const bed = [
      (x: 120.0, y: 578.0, color: Color(0xFFFFB3C7)),
      (x: 142.0, y: 588.0, color: Color(0xFFFFE7B0)),
      (x: 166.0, y: 574.0, color: Color(0xFFE7B8E8)),
      (x: 190.0, y: 586.0, color: Color(0xFFFFC9D8)),
      (x: 214.0, y: 576.0, color: Color(0xFFFDF1C4)),
      (x: 238.0, y: 590.0, color: Color(0xFFF3B9DA)),
      (x: 762.0, y: 584.0, color: Color(0xFFFFD1DE)),
      (x: 786.0, y: 592.0, color: Color(0xFFFFF0C0)),
      (x: 810.0, y: 582.0, color: Color(0xFFE4C5F0)),
    ];
    for (final f in bed) {
      flower(f.x, f.y, f.color);
    }

    // A few clumps of longer grass around the flowers.
    final clump = Paint()
      ..color = const Color(0xFF4A7B4C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (final x in const [104.0, 152.0, 204.0, 254.0, 778.0, 828.0]) {
      for (var i = 0; i < 4; i++) {
        canvas.drawPath(
          Path()
            ..moveTo(x + i * 5, 594)
            ..quadraticBezierTo(
              x + i * 5 - 4 + i,
              580,
              x + i * 5 - 8 + i * 2,
              566,
            ),
          clump,
        );
      }
    }
  }

  void _paintLamp(Canvas canvas) {
    const x = 246.0;
    // Base.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(x, 574), width: 42, height: 12),
      Paint()..color = const Color(0xFF2F3A34),
    );
    // Post.
    canvas.drawRect(
      const Rect.fromLTWH(x - 4, 286, 8, 288),
      Paint()..color = const Color(0xFF3D4A42),
    );
    canvas.drawRect(
      const Rect.fromLTWH(x - 4, 286, 3, 288),
      Paint()..color = const Color(0xFF66776A),
    );
    // Curved arm and lantern.
    canvas.drawPath(
      Path()
        ..moveTo(x, 296)
        ..quadraticBezierTo(x + 10, 266, x + 44, 268),
      Paint()
        ..color = const Color(0xFF3D4A42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    final lantern = RRect.fromRectAndRadius(
      const Rect.fromLTWH(x + 28, 264, 34, 44),
      const Radius.circular(6),
    );
    canvas.drawRRect(lantern, Paint()..color = const Color(0xFFFFEFC4));
    canvas.drawRRect(
      lantern,
      Paint()
        ..color = const Color(0xFF3D4A42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRect(
      const Rect.fromLTWH(x + 24, 258, 42, 7),
      Paint()..color = const Color(0xFF3D4A42),
    );
    canvas.drawRect(
      const Rect.fromLTWH(x + 24, 306, 42, 6),
      Paint()..color = const Color(0xFF3D4A42),
    );
  }

  void _paintFramingTrees(Canvas canvas) {
    // Left trunk and canopy.
    canvas.drawPath(
      Path()
        ..moveTo(28, 600)
        ..cubicTo(44, 500, 24, 400, 56, 314)
        ..lineTo(86, 318)
        ..cubicTo(58, 402, 82, 502, 76, 600)
        ..close(),
      Paint()..color = const Color(0xFF5C4227),
    );
    canvas.drawPath(
      Path()
        ..moveTo(42, 580)
        ..cubicTo(54, 500, 38, 420, 66, 352),
      Paint()
        ..color = const Color(0xFF7A5A34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final leaf = Paint()..color = const Color(0xFF3E7446);
    final leafLight = Paint()..color = const Color(0xFF5B9257);
    final leafDark = Paint()..color = const Color(0xFF2F5B3B);
    for (final spec in const [
      (x: -10.0, y: 236.0, r: 108.0, shade: 0),
      (x: 80.0, y: 172.0, r: 118.0, shade: 1),
      (x: 188.0, y: 210.0, r: 84.0, shade: 2),
      (x: 58.0, y: 300.0, r: 80.0, shade: 2),
      (x: 150.0, y: 286.0, r: 62.0, shade: 1),
    ]) {
      final paint = switch (spec.shade) {
        0 => leafLight,
        1 => leaf,
        _ => leafDark,
      };
      canvas.drawCircle(Offset(spec.x, spec.y), spec.r, paint);
    }

    // Right trunk and canopy.
    canvas.drawPath(
      Path()
        ..moveTo(944, 600)
        ..cubicTo(930, 498, 956, 408, 918, 310)
        ..lineTo(888, 316)
        ..cubicTo(918, 404, 894, 500, 900, 600)
        ..close(),
      Paint()..color = const Color(0xFF543B24),
    );
    canvas.drawPath(
      Path()
        ..moveTo(928, 580)
        ..cubicTo(918, 496, 938, 422, 910, 350),
      Paint()
        ..color = const Color(0xFF76532F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    for (final spec in const [
      (x: 1010.0, y: 230.0, r: 112.0, shade: 0),
      (x: 920.0, y: 158.0, r: 120.0, shade: 1),
      (x: 820.0, y: 204.0, r: 86.0, shade: 2),
      (x: 960.0, y: 298.0, r: 78.0, shade: 2),
      (x: 860.0, y: 284.0, r: 58.0, shade: 1),
    ]) {
      final paint = switch (spec.shade) {
        0 => leafLight,
        1 => leaf,
        _ => leafDark,
      };
      canvas.drawCircle(Offset(spec.x, spec.y), spec.r, paint);
    }

    // Hanging branch over the bench, with a few leaves catching the light.
    final branch = Path()
      ..moveTo(878, 252)
      ..quadraticBezierTo(780, 280, 700, 272);
    canvas.drawPath(
      branch,
      Paint()
        ..color = const Color(0xFF4C3722)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    final shimmer = 0.5 + 0.5 * math.sin(breath * math.pi);
    for (final leafSpot in const [
      (x: 742.0, y: 268.0, r: 10.0),
      (x: 722.0, y: 280.0, r: 8.0),
      (x: 770.0, y: 276.0, r: 9.0),
      (x: 700.0, y: 282.0, r: 7.0),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(leafSpot.x, leafSpot.y),
          width: leafSpot.r * 2,
          height: leafSpot.r * 1.3,
        ),
        Paint()
          ..color = const Color(
            0xFF6BA35F,
          ).withAlpha((150 + 60 * shimmer).round()),
      );
    }
  }

  void _paintBench(Canvas canvas) {
    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(500, 568), width: 392, height: 44),
      Paint()..color = const Color(0x55000000),
    );

    const metal = Color(0xFF3E453F);
    const metalLight = Color(0xFF6A7368);
    const wood = Color(0xFFA9713F);
    const woodLight = Color(0xFFC28A50);
    const woodDark = Color(0xFF7B4E28);

    // Back supports.
    for (final x in const [382.0, 606.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 392, 13, 146),
          const Radius.circular(6),
        ),
        Paint()..color = metal,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + 2, 398, 3, 132),
        Paint()..color = metalLight.withAlpha(120),
      );
    }

    // Backrest slats.
    for (final y in const [396.0, 424.0, 452.0]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(342, y, 316, 15),
        const Radius.circular(6),
      );
      canvas.drawRRect(r, Paint()..color = wood);
      canvas.drawRRect(
        r,
        Paint()
          ..color = woodDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawRect(
        Rect.fromLTWH(348, y + 3, 304, 2.4),
        Paint()..color = woodLight.withAlpha(150),
      );
    }

    // Armrests.
    for (final x in const [334.0, 646.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 462, 20, 58),
          const Radius.circular(7),
        ),
        Paint()..color = metal,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 10, 454, 40, 12),
          const Radius.circular(6),
        ),
        Paint()..color = wood,
      );
    }

    // Seat slats.
    for (final y in const [478.0, 498.0, 518.0]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(336, y, 328, 16),
        const Radius.circular(5),
      );
      canvas.drawRRect(r, Paint()..color = wood);
      canvas.drawRRect(
        r,
        Paint()
          ..color = woodDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawRect(
        Rect.fromLTWH(342, y + 3, 316, 2.6),
        Paint()..color = woodLight.withAlpha(140),
      );
    }

    // Front legs and cross brace.
    for (final spec in const [
      (top: Offset(366, 534), foot: Offset(354, 574)),
      (top: Offset(620, 534), foot: Offset(632, 574)),
    ]) {
      canvas.drawLine(
        spec.top,
        spec.foot,
        Paint()
          ..color = metal
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        spec.foot + const Offset(-8, 2),
        spec.foot + const Offset(8, 2),
        Paint()
          ..color = metal
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawLine(
      const Offset(360, 552),
      const Offset(626, 552),
      Paint()
        ..color = metal
        ..strokeWidth = 5,
    );

    // Brass dedication plaque.
    final plaque = RRect.fromRectAndRadius(
      const Rect.fromLTWH(468, 410, 64, 26),
      const Radius.circular(4),
    );
    canvas.drawRRect(plaque, Paint()..color = const Color(0xFFD8B25E));
    canvas.drawRRect(
      plaque,
      Paint()
        ..color = const Color(0xFF8A6A2C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final y in const [418.0, 424.0]) {
      canvas.drawRect(
        Rect.fromLTWH(476, y, 48 - (y - 418) * 1.4, 2),
        Paint()..color = const Color(0x778A6A2C),
      );
    }

    // Takeaway cup resting on the bench.
    final cup = RRect.fromRectAndRadius(
      const Rect.fromLTWH(596, 444, 28, 36),
      const Radius.circular(5),
    );
    canvas.drawRRect(cup, Paint()..color = const Color(0xFFF2E3C8));
    canvas.drawRRect(
      cup,
      Paint()
        ..color = const Color(0xFF6B4A32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRect(
      const Rect.fromLTWH(592, 438, 36, 8),
      Paint()..color = const Color(0xFF6B4A32),
    );
    canvas.drawRect(
      const Rect.fromLTWH(598, 456, 24, 12),
      Paint()..color = const Color(0xFFB45E4A),
    );
    final steamSway = math.sin(breath * math.pi * 2) * 3;
    final steam = Paint()
      ..color = const Color(0x66FFF6E2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(604, 434)
        ..quadraticBezierTo(600 + steamSway, 422, 606, 410),
      steam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(616, 432)
        ..quadraticBezierTo(620 - steamSway, 420, 614, 408),
      steam,
    );
  }

  void _paintPigeons(Canvas canvas) {
    final bob = math.sin(breath * math.pi * 2) * 1.6;
    final drift = math.sin(ambient * math.pi * 2) * 3;

    void pigeon(Offset at, double scale, {required bool pecking}) {
      final x = at.dx + drift;
      final y = at.dy + bob;
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale);
      final body = Paint()..color = const Color(0xFF8D99A8);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 32, height: 19),
        body,
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-4, -3), width: 18, height: 12),
        Paint()..color = const Color(0xFFA9B4C1),
      );
      // Wing.
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-2, 1), width: 16, height: 9),
        Paint()..color = const Color(0xFF6F7C8C),
      );
      final head = pecking ? const Offset(15, 10) : const Offset(14, -9);
      canvas.drawCircle(head, 7, body);
      canvas.drawCircle(
        head + const Offset(1.5, -1),
        1.4,
        Paint()..color = const Color(0xFF2C333D),
      );
      canvas.drawPath(
        Path()
          ..moveTo(head.dx + 6, head.dy)
          ..lineTo(head.dx + 11, head.dy + 1.5)
          ..lineTo(head.dx + 6, head.dy + 3),
        Paint()..color = const Color(0xFFD9A05B),
      );
      final leg = Paint()
        ..color = const Color(0xFFB4664E)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-3, 9), const Offset(-5, 15), leg);
      canvas.drawLine(const Offset(3, 9), const Offset(4, 15), leg);
      canvas.restore();
    }

    pigeon(const Offset(700, 556), 1.05, pecking: false);
    pigeon(const Offset(748, 568), 0.86, pecking: true);
    pigeon(const Offset(664, 572), 0.7, pecking: true);
  }

  void _paintFigure(Canvas canvas) {
    final bob = (breath - 0.5) * 3.4;
    const skin = Color(0xFFF2C9A4);
    const ink = Color(0xFF3A2C26);
    const shirt = Color(0xFFE07856);
    const jeans = Color(0xFF3B5570);

    // Warm halo so the figure reads against the green.
    canvas.drawCircle(
      const Offset(500, 430),
      126,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFFFFE3B0).withAlpha(30),
                const Color(0xFFFFE3B0).withAlpha(0),
              ],
            ).createShader(
              Rect.fromCircle(center: const Offset(500, 430), radius: 126),
            ),
    );

    // Legs hang over the bench front; feet rest on the path.
    final legPaint = Paint()
      ..color = jeans
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final spec in const [
      (hip: Offset(482, 504), knee: Offset(458, 542), foot: Offset(472, 574)),
      (hip: Offset(518, 504), knee: Offset(542, 542), foot: Offset(528, 574)),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(spec.hip.dx, spec.hip.dy)
          ..lineTo(spec.knee.dx, spec.knee.dy)
          ..lineTo(spec.foot.dx, spec.foot.dy),
        legPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              spec.foot.dx + (spec.foot.dx < 500 ? -8 : 8),
              spec.foot.dy + 3,
            ),
            width: 35,
            height: 15,
          ),
          const Radius.circular(7),
        ),
        Paint()..color = const Color(0xFF2B2119),
      );
    }

    canvas.save();
    canvas.translate(0, bob);

    // Torso.
    final torso = Path()
      ..moveTo(468, 424)
      ..quadraticBezierTo(500, 406, 532, 424)
      ..lineTo(540, 494)
      ..quadraticBezierTo(500, 508, 460, 494)
      ..close();
    canvas.drawPath(torso, Paint()..color = shirt);
    canvas.drawPath(
      torso,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Collar.
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(500, 420), width: 30, height: 18),
      0.15,
      math.pi - 0.3,
      false,
      Paint()
        ..color = const Color(0xFFB9573B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // One arm stretched along the backrest, one hand resting on the knee.
    final arm = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(471, 434)
        ..lineTo(438, 450)
        ..lineTo(414, 458),
      arm,
    );
    canvas.drawPath(
      Path()
        ..moveTo(529, 434)
        ..lineTo(550, 470)
        ..lineTo(540, 502),
      arm,
    );
    for (final hand in const [Offset(412, 459), Offset(540, 503)]) {
      canvas.drawCircle(hand, 6.5, Paint()..color = skin);
    }

    // Head.
    const head = Offset(500, 384);
    canvas.drawCircle(head, 25, Paint()..color = skin);
    canvas.drawCircle(
      head,
      25,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    // Hair, with a lazy strand moving in the breeze.
    canvas.drawArc(
      Rect.fromCircle(center: head, radius: 25),
      math.pi * 1.03,
      math.pi * 0.94,
      false,
      Paint()
        ..color = const Color(0xFF4A3B32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
    final strand = math.sin(breath * math.pi * 2) * 2.5;
    canvas.drawPath(
      Path()
        ..moveTo(520, 370)
        ..quadraticBezierTo(534 + strand, 376, 537 + strand, 388),
      Paint()
        ..color = const Color(0xFF4A3B32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // Closed, happy eyes.
    final eye = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(491, 386), radius: 4.5),
      0.15,
      math.pi - 0.3,
      false,
      eye,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(509, 386), radius: 4.5),
      0.15,
      math.pi - 0.3,
      false,
      eye,
    );
    // Smile.
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(500, 392), radius: 8),
      0.25,
      math.pi - 0.5,
      false,
      Paint()
        ..color = const Color(0xFF8C4A4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    // Blush.
    canvas.drawCircle(
      const Offset(482, 395),
      5,
      Paint()..color = const Color(0x66E88A8A),
    );
    canvas.drawCircle(
      const Offset(518, 395),
      5,
      Paint()..color = const Color(0x66E88A8A),
    );

    canvas.restore();
  }

  void _paintGlows(Canvas canvas) {
    _radial(canvas, const Offset(790, 150), 300, const Color(0xFFFFE8B0), 20);
    _radial(
      canvas,
      const Offset(292, 286),
      150,
      const Color(0xFFFFD98A),
      (16 + 6 * math.sin(breath * math.pi)).round(),
    );
    if (celebrating) {
      _radial(canvas, const Offset(500, 430), 340, const Color(0xFFFFD27A), 46);
    }
  }

  void _radial(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    int alpha,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withAlpha(alpha), color.withAlpha(0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _paintPetals(Canvas canvas) {
    for (final petal in _petals) {
      final t = (petal.phase + ambient * petal.speed) % 1.0;
      final y = -30 + t * 660;
      final sway = math.sin((ambient * 2 + petal.phase) * math.pi * 2) * 20;
      final alpha = (math.sin(t * math.pi) * (celebrating ? 200 : 135))
          .clamp(0, 255)
          .round();
      if (alpha <= 2) continue;

      canvas.save();
      canvas.translate(petal.x + sway, y);
      canvas.rotate(sway * 0.02 + t * 2.5);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: petal.size * 2,
          height: petal.size,
        ),
        Paint()..color = petal.color.withAlpha(alpha),
      );
      canvas.restore();
    }
  }

  void _paintVignette(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, _designW, _designH);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.15, -0.05),
          radius: 1.05,
          colors: [Colors.transparent, Color(0xA60A140D)],
          stops: [0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ParkPainter old) =>
      old.ambient != ambient ||
      old.breath != breath ||
      old.celebrating != celebrating;
}
