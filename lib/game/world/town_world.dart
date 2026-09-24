import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'interactable.dart';
import 'map_data.dart';
import '../../models/location_dialogue.dart';

class TownWorld extends World {
  final void Function(Interactable?) onNearestChanged;
  late final List<_BuildingBlock> buildings;

  TownWorld({required this.onNearestChanged}) {
    buildings = buildTownLocations()
        .map(
          (loc) => _BuildingBlock(
            location: loc,
            interactId: 'enter_${loc.id}',
            interactLabel: 'Enter ${loc.name}',
          ),
        )
        .toList();
  }

  @override
  Future<void> onLoad() async {
    final ground = RectangleComponent(
      position: Vector2(0, 0),
      size: Vector2(kWorldWidth, kWorldHeight),
      paint: Paint()..color = const Color(0xFFEFE8D5),
    );
    add(ground);

    final roadPaint = Paint()..color = const Color(0xFFB7B7B7);
    add(
      RectangleComponent(
        position: Vector2(0, 800),
        size: Vector2(kWorldWidth, 120),
        paint: roadPaint,
      ),
    );
    add(
      RectangleComponent(
        position: Vector2(1540, 0),
        size: Vector2(120, kWorldHeight),
        paint: roadPaint,
      ),
    );

    for (final b in buildings) {
      add(b);
    }
  }

  List<RectangleComponent> solidBounds() => buildings;

  Interactable? nearestInteractable(Vector2 playerPos, {double radius = 130}) {
    Interactable? best;
    var bestDist = radius;
    for (final b in buildings) {
      final d = b.center.distanceTo(playerPos);
      if (d < bestDist) {
        bestDist = d;
        best = b;
      }
    }
    return best;
  }
}

class _BuildingBlock extends RectangleComponent implements Interactable {
  final LocationModel location;
  @override
  final String interactId;
  @override
  final String interactLabel;

  _BuildingBlock({
    required this.location,
    required this.interactId,
    required this.interactLabel,
  }) : super(
         position: Vector2(location.x, location.y),
         size: Vector2(location.w, location.h),
         paint: Paint()..color = Color(location.color),
       );

  Vector2 get center => position + size / 2;

  @override
  Vector2 get interactPosition => center;

  @override
  Future<void> onInteract(LifeInteractContext ctx) async {
    ctx.enterLocation(location.id);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final textPainter = TextPainter(
      text: TextSpan(
        text: location.name,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }
}

class NpcMarker extends PositionComponent implements Interactable {
  final String npcId;
  final String npcName;
  @override
  String get interactId => 'talk_$npcId';
  @override
  String get interactLabel => 'Talk to $npcName';
  @override
  Vector2 get interactPosition => position;

  NpcMarker({required this.npcId, required this.npcName, required Vector2 at})
    : super(position: at, size: Vector2(56, 56), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF4A86E8);
    canvas.drawCircle(const Offset(28, 28), 26, paint);
    final tp = TextPainter(
      text: TextSpan(
        text: npcName.isEmpty ? '?' : npcName[0],
        style: const TextStyle(color: Colors.white, fontSize: 24),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(28 - tp.width / 2, 28 - tp.height / 2));
  }

  @override
  Future<void> onInteract(LifeInteractContext ctx) async {
    ctx.talkTo(npcId);
  }
}
