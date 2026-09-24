import 'dart:ui';

import '../../models/location_dialogue.dart';
import 'interior_data.dart';
import 'map_data.dart';

/// One rectangle of a minimap.
class MiniMapBlock {
  final Rect rect;
  final Color color;
  final bool isMarker;

  const MiniMapBlock(this.rect, this.color, {this.isMarker = false});

  factory MiniMapBlock.at(double x, double y, double size, Color color) =>
      MiniMapBlock(
        Rect.fromCenter(center: Offset(x, y), width: size, height: size),
        color,
        isMarker: true,
      );
}

/// Everything needed to draw the map the player is currently standing in.
class MiniMapScene {
  final String title;
  final double width;
  final double height;
  final Color background;
  final List<MiniMapBlock> blocks;

  const MiniMapScene({
    required this.title,
    required this.width,
    required this.height,
    required this.background,
    required this.blocks,
  });

  /// The town: highways, sidewalks and every building with its doorway.
  factory MiniMapScene.town() {
    final blocks = <MiniMapBlock>[
      for (final strip in buildTownRoads())
        MiniMapBlock(
          Rect.fromLTWH(strip.x, strip.y, strip.w, strip.h),
          Color(strip.color),
        ),
      for (final d in buildTownDecorations())
        if (d.kind == 'tree')
          MiniMapBlock(
            Rect.fromCenter(
              center: Offset(d.x, d.y - d.size * 0.28),
              width: d.size * 0.8,
              height: d.size * 0.8,
            ),
            const Color(0xFF3F7D3A),
          ),
      for (final LocationModel l in buildTownLocations())
        MiniMapBlock(Rect.fromLTWH(l.x, l.y, l.w, l.h), Color(l.color)),
      for (final LocationModel l in buildTownLocations())
        MiniMapBlock.at(
          l.x + l.w / 2,
          l.doorOnTop ? l.y : l.y + l.h,
          70,
          const Color(0xFFFFF3D6),
        ),
    ];
    return MiniMapScene(
      title: 'Town',
      width: kWorldWidth,
      height: kWorldHeight,
      background: const Color(0xFFCFE0B5),
      blocks: blocks,
    );
  }

  /// The inside of a building: walls, furniture and its activity point.
  factory MiniMapScene.interior(InteriorLayout layout) {
    const wallThickness = 24.0;
    const backWall = 150.0;
    final blocks = <MiniMapBlock>[
      MiniMapBlock(
        Rect.fromLTWH(0, 0, layout.width, backWall),
        Color(layout.wallColor),
      ),
      MiniMapBlock(
        Rect.fromLTWH(0, backWall, wallThickness, layout.height - backWall),
        Color(layout.trimColor),
      ),
      MiniMapBlock(
        Rect.fromLTWH(
          layout.width - wallThickness,
          backWall,
          wallThickness,
          layout.height - backWall,
        ),
        Color(layout.trimColor),
      ),
      MiniMapBlock(
        Rect.fromLTWH(
          0,
          layout.height - wallThickness,
          layout.width / 2 - layout.doorWidth / 2,
          wallThickness,
        ),
        Color(layout.trimColor),
      ),
      MiniMapBlock(
        Rect.fromLTWH(
          layout.width / 2 + layout.doorWidth / 2,
          layout.height - wallThickness,
          layout.width / 2 - layout.doorWidth / 2,
          wallThickness,
        ),
        Color(layout.trimColor),
      ),
      for (final prop in layout.props)
        MiniMapBlock(
          Rect.fromLTWH(prop.x, prop.y, prop.w, prop.h),
          Color(prop.color),
        ),
      MiniMapBlock.at(
        layout.width / 2,
        layout.height - InteriorWorldMetrics.doorHeight / 2,
        90,
        const Color(0xFF3A2C26),
      ),
    ];
    return MiniMapScene(
      title: layout.title,
      width: layout.width,
      height: layout.height,
      background: Color(layout.floorColor),
      blocks: blocks,
    );
  }
}

/// Doorway metrics shared with the interior scene.
class InteriorWorldMetrics {
  static const double doorHeight = 68;
}

/// The minimap scene for [locationId], or the town when it is null.
MiniMapScene buildMiniMapScene(String? locationId) => locationId == null
    ? MiniMapScene.town()
    : MiniMapScene.interior(buildInterior(locationId));
