import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    final knee = Offset(hipX + swing * 11 * s, hipY + 18 * s);
    final foot = Offset(
      hipX + swing * 23 * s,
      hipY + 36 * s - math.max(0.0, swing) * 7 * s,
    );
    canvas.drawPath(
      Path()
        ..moveTo(hipX, hipY)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(foot.dx, foot.dy),
      limbPaint,
    );
  }

  // Torso, drawn as a shirt.
  canvas.drawLine(
    Offset(hipX, hipY),
    Offset(shoulderX, shoulderY),
    Paint()
      ..color = shirt
      ..strokeWidth = 10 * s
      ..strokeCap = StrokeCap.round,
  );

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
