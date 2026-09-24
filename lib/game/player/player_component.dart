import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlayerComponent extends PositionComponent {
  Vector2 moveInput = Vector2.zero();
  bool running = false;
  final double walkSpeed = 220;
  final double runSpeed = 360;

  PlayerComponent({required Vector2 spawn})
    : super(position: spawn, size: Vector2(48, 48), anchor: Anchor.center);

  double get speed => running ? runSpeed : walkSpeed;

  @override
  void update(double dt) {
    if (moveInput.length > 0.01) {
      final dir = moveInput.normalized();
      position += dir * speed * dt;
      position.x = position.x.clamp(24, 3200 - 24);
      position.y = position.y.clamp(24, 1800 - 24);
    }
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final body = Paint()..color = const Color(0xFFE06666);
    canvas.drawCircle(const Offset(24, 24), 20, body);
    final face = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(24, 20), 8, face);
  }
}
