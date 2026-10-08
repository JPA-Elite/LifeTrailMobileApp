import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../game/world/mini_map_scene.dart';

/// Small map of wherever the player currently is: the town with every
/// building, or the room of the building they walked into.
///
/// Listens to the game's position notifier, so the "you are here" dot stays
/// in sync with the character without rebuilding the rest of the HUD.
class MiniMap extends StatelessWidget {
  final ValueListenable<Vector2> position;
  final ValueListenable<MiniMapScene> scene;
  final double width;

  /// Cap for the painted map height (HUD default 104; fullscreen more).
  final double mapHeightMax;

  const MiniMap({
    super.key,
    required this.position,
    required this.scene,
    this.width = 168,
    this.mapHeightMax = 104,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MiniMapScene>(
      valueListenable: scene,
      builder: (context, sceneValue, _) {
        final mapHeight = (width * sceneValue.height / sceneValue.width).clamp(
          64.0,
          mapHeightMax,
        );
        return ValueListenableBuilder<Vector2>(
          valueListenable: position,
          builder: (context, positionValue, _) => Container(
            width: width,
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(150),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.my_location,
                      size: 12,
                      color: Color(0xFFFFD966),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        sceneValue.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.zoom_out_map,
                      size: 12,
                      color: Colors.white54,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: mapHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomPaint(
                      painter: MiniMapPainter(
                        scene: sceneValue,
                        position: positionValue,
                      ),
                      size: Size(width - 14, mapHeight),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MiniMapPainter extends CustomPainter {
  final MiniMapScene scene;
  final Vector2 position;

  MiniMapPainter({required this.scene, required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / scene.width,
      size.height / scene.height,
    );
    final dx = (size.width - scene.width * scale) / 2;
    final dy = (size.height - scene.height * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, scene.width, scene.height),
      Paint()..color = scene.background,
    );

    for (final block in scene.blocks) {
      canvas.drawRect(
        block.isMarker
            ? Rect.fromCenter(
                center: block.rect.center,
                width: block.rect.width / 2,
                height: block.rect.height / 2,
              )
            : block.rect,
        Paint()..color = block.color,
      );
    }

    // Small building labels, each shrunk to fit inside its own
    // building rect (never spilling onto neighbours). Layouts cached:
    // the painter reruns on every player step.
    for (final block in scene.blocks) {
      final label = block.label;
      if (label == null || label.isEmpty) continue;
      final cap = 8.5 / scale;
      final probe = _labelPainter(label, cap);
      final fit = [
        1.0,
        (block.rect.width * 0.92) / probe.width,
        (block.rect.height * 0.9) / probe.height,
      ].reduce((a, b) => a < b ? a : b);
      final painter = fit < 1.0 ? _labelPainter(label, cap * fit) : probe;
      painter.paint(
        canvas,
        Offset(
          block.rect.center.dx - painter.width / 2,
          block.rect.center.dy - painter.height / 2,
        ),
      );
    }

    // The player: a ring plus a dot, drawn at a constant on-screen size.
    // Kept small so it doesn't cover nearby buildings/doors.
    canvas.drawCircle(
      Offset(position.x, position.y),
      12 / scale,
      Paint()..color = const Color(0x66FFFFFF),
    );
    canvas.drawCircle(
      Offset(position.x, position.y),
      6 / scale,
      Paint()..color = const Color(0xFFFF3B30),
    );
    canvas.drawCircle(
      Offset(position.x, position.y),
      6 / scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 / scale
        ..color = Colors.white,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(MiniMapPainter oldDelegate) =>
      oldDelegate.position != position || oldDelegate.scene != scene;
}

/// Cached label painters (see interior drawCenteredLabel rationale).
final Map<String, TextPainter> _miniLabelCache = {};

TextPainter _labelPainter(String text, double fontSize) {
  final key = '$text|$fontSize';
  return _miniLabelCache.putIfAbsent(key, () {
    return TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 3)],
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )
        ..layout();
  });
}
