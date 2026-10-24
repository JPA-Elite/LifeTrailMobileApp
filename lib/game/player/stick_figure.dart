import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/outfit.dart';

/// Draws an articulated stick figure into the local box
/// `[0,0] - [width,height]`, with the feet on the bottom edge.
///
/// Limb positions are driven by [phase] (the walk cycle) so legs and arms
/// swing in opposite phases, the body bobs on each step and the torso leans
/// into the direction of travel. [stride] fades the pose between standing
/// still (0) and a full stride (1).
void drawStickFigure(
  Canvas canvas, {
  required double width,
  required double height,
  required double phase,
  required double stride,
  required double facing,
  double idle = 0,
  bool running = false,
  Color shirt = const Color(0xFFE06666),
  Color? shirtAccent,
  OutfitPattern shirtPattern = OutfitPattern.solid,
  Color? shorts,
  Color? shortsAccent,
  OutfitPattern shortsPattern = OutfitPattern.solid,
  Color skin = const Color(0xFFF2C9A4),
  Color ink = const Color(0xFF3A2C26),
  Color hair = const Color(0xFF4A3B32),
  bool shadow = true,
}) {
  // Everything below is authored against a 96px tall figure.
  final s = height / 96;
  final cx = width / 2;

  final breath = math.sin(idle) * 0.8 * (1 - stride);
  final bob =
      -math.sin(phase * 2) * 2.5 * stride * (running ? 1.4 : 1.0) + breath;
  final lean = facing * 2.5 * stride;

  final limbPaint = Paint()
    ..color = ink
    ..strokeWidth = 5 * s
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  if (shadow) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, height - 3 * s),
        width: 34 * s,
        height: 10 * s,
      ),
      Paint()..color = const Color(0x33000000),
    );
  }

  final hipX = cx + lean * 0.4;
  final hipY = height - 38 * s + bob;
  final shoulderX = cx + lean;
  final shoulderY = height - 70 * s + bob;
  final headCenter = Offset(cx + lean * 1.2, shoulderY - 11 * s);

  // Legs, swinging in opposite phases.
  for (final offset in const [0.0, math.pi]) {
    final swing = math.sin(phase + offset) * stride;
    final hip = Offset(hipX, hipY);
    final knee = Offset(hipX + swing * 11 * s, hipY + 18 * s);
    final foot = Offset(
      hipX + swing * 23 * s,
      hipY + 36 * s - math.max(0.0, swing) * 7 * s,
    );
    canvas.drawPath(
      Path()
        ..moveTo(hip.dx, hip.dy)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(foot.dx, foot.dy),
      limbPaint,
    );

    // Shorts cover the upper thigh. Drawing them over the ink leg makes the
    // bottoms read at a distance while leaving the lower leg as a stick.
    if (shorts != null) {
      final shortsEnd = Offset.lerp(hip, knee, 0.62)!;
      canvas.drawLine(
        hip,
        shortsEnd,
        Paint()
          ..color = shorts
          ..strokeWidth = 9.5 * s
          ..strokeCap = StrokeCap.round,
      );
      if (shortsAccent != null) {
        _drawShortsDetail(
          canvas,
          hip,
          shortsEnd,
          shortsPattern,
          shortsAccent,
          s,
          side: offset == 0 ? -1 : 1,
        );
      }
    }
  }

  // Torso, drawn as a shirt.
  final shoulder = Offset(shoulderX, shoulderY);
  final hip = Offset(hipX, hipY);
  canvas.drawLine(
    hip,
    shoulder,
    Paint()
      ..color = shirt
      ..strokeWidth = 10 * s
      ..strokeCap = StrokeCap.round,
  );

  // A tiny print so the five tees read differently even at stick-figure
  // scale. Placed along the torso so it follows the walk lean.
  if (shirtAccent != null) {
    final torso = hip - shoulder;
    final length = torso.distance;
    if (length > 0.001) {
      final unit = torso / length;
      final normal = Offset(-unit.dy, unit.dx);
      switch (shirtPattern) {
        case OutfitPattern.solid:
          break;
        case OutfitPattern.stripe:
          final p = shoulder + unit * (length * 0.42);
          canvas.drawLine(
            p - normal * 5.2 * s,
            p + normal * 5.2 * s,
            Paint()
              ..color = shirtAccent
              ..strokeWidth = 2.2 * s
              ..strokeCap = StrokeCap.round,
          );
          break;
        case OutfitPattern.pocket:
          final p =
              shoulder + unit * (length * 0.42) - normal * 2.6 * s;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: p,
                width: 4.4 * s,
                height: 4.4 * s,
              ),
              Radius.circular(0.8 * s),
            ),
            Paint()
              ..color = shirtAccent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2 * s,
          );
          break;
        case OutfitPattern.star:
          _drawStar(
            canvas,
            shoulder + unit * (length * 0.42),
            3.6 * s,
            shirtAccent,
          );
          break;
        case OutfitPattern.heart:
          _drawHeart(
            canvas,
            shoulder + unit * (length * 0.42),
            3.6 * s,
            shirtAccent,
          );
          break;
        case OutfitPattern.trim:
          canvas.drawLine(
            shoulder + normal * 3.8 * s,
            hip + normal * 3.8 * s,
            Paint()
              ..color = shirtAccent
              ..strokeWidth = 1.4 * s
              ..strokeCap = StrokeCap.round,
          );
          break;
      }
    }
  }

  // Arms, opposite to the legs.
  for (final offset in const [math.pi, 0.0]) {
    final swing = math.sin(phase + offset) * stride;
    final elbow = Offset(shoulderX + swing * 9 * s, shoulderY + 14 * s);
    final hand = Offset(shoulderX + swing * 17 * s, shoulderY + 27 * s);
    canvas.drawPath(
      Path()
        ..moveTo(shoulderX, shoulderY)
        ..lineTo(elbow.dx, elbow.dy)
        ..lineTo(hand.dx, hand.dy),
      limbPaint,
    );
  }

  // Head, hair and a nose so the facing direction is readable.
  final headRadius = 11 * s;
  canvas.drawCircle(headCenter, headRadius, Paint()..color = skin);
  canvas.drawCircle(
    headCenter,
    headRadius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s
      ..color = ink,
  );
  canvas.drawArc(
    Rect.fromCircle(center: headCenter, radius: headRadius),
    math.pi * 1.05,
    math.pi * 0.9,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * s
      ..strokeCap = StrokeCap.round
      ..color = hair,
  );
  canvas.drawCircle(
    Offset(headCenter.dx + facing * 10 * s, headCenter.dy + 1 * s),
    2.5 * s,
    Paint()..color = ink,
  );
}

void _drawShortsDetail(
  Canvas canvas,
  Offset hip,
  Offset end,
  OutfitPattern pattern,
  Color accent,
  double s, {
  required double side,
}) {
  final d = end - hip;
  final length = d.distance;
  if (length <= 0.001) return;
  final unit = d / length;
  final normal = Offset(-unit.dy, unit.dx) * side;

  switch (pattern) {
    case OutfitPattern.solid:
      break;
    case OutfitPattern.trim:
      canvas.drawLine(
        hip + normal * 3.5 * s,
        end + normal * 3.5 * s,
        Paint()
          ..color = accent
          ..strokeWidth = 1.5 * s
          ..strokeCap = StrokeCap.round,
      );
      break;
    case OutfitPattern.stripe:
      final p = Offset.lerp(hip, end, 0.44)!;
      canvas.drawLine(
        p - normal * 4.4 * s,
        p + normal * 4.4 * s,
        Paint()
          ..color = accent
          ..strokeWidth = 1.9 * s
          ..strokeCap = StrokeCap.round,
      );
      break;
    case OutfitPattern.pocket:
      canvas.drawCircle(
        Offset.lerp(hip, end, 0.42)! + normal * 2.4 * s,
        1.6 * s,
        Paint()..color = accent,
      );
      break;
    case OutfitPattern.star:
      _drawStar(
        canvas,
        Offset.lerp(hip, end, 0.46)!,
        3 * s,
        accent,
      );
      break;
    case OutfitPattern.heart:
      _drawHeart(
        canvas,
        Offset.lerp(hip, end, 0.46)!,
        3 * s,
        accent,
      );
      break;
  }
}

void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final angle = -math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? radius : radius * 0.44;
    final point = Offset(
      center.dx + math.cos(angle) * r,
      center.dy + math.sin(angle) * r,
    );
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  canvas.drawPath(path, Paint()..color = color);
}

void _drawHeart(Canvas canvas, Offset center, double radius, Color color) {
  final path = Path()
    ..moveTo(center.dx, center.dy + radius * 0.75)
    ..cubicTo(
      center.dx - radius * 1.4,
      center.dy - radius * 0.2,
      center.dx - radius * 0.7,
      center.dy - radius * 1.05,
      center.dx,
      center.dy - radius * 0.35,
    )
    ..cubicTo(
      center.dx + radius * 0.7,
      center.dy - radius * 1.05,
      center.dx + radius * 1.4,
      center.dy - radius * 0.2,
      center.dx,
      center.dy + radius * 0.75,
    )
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}
