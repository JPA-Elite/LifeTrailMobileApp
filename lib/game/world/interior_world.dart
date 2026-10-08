import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'interactable.dart';
import 'interior_data.dart';
import 'life_world.dart';

/// The scene *inside* a building: a room with walls, furniture and a doorway
/// back out to the town. Built from an [InteriorLayout].
class InteriorWorld extends LifeWorld {
  final InteriorLayout layout;
  final void Function(Interactable?) onNearestChanged;

  final List<PositionComponent> _solids = [];
  ExitDoor? _exitDoor;

  InteriorWorld({required this.layout, required this.onNearestChanged});

  static const double wallThickness = 24;
  static const double backWallHeight = 150;
  static const double doorHeight = 68;

  @override
  Vector2 get worldSize => Vector2(layout.width, layout.height);

  /// Center of the doorway in the bottom wall.
  Vector2 get doorPosition =>
      Vector2(layout.width / 2, layout.height - doorHeight / 2);

  /// Where the player appears when they walk in, just inside the doorway.
  Vector2 get entrySpawn => Vector2(layout.width / 2, layout.entryY);

  @override
  List<PositionComponent> solidBounds() => _solids;

  @override
  List<Interactable> interactables() => [?_exitDoor];

  @override
  Future<void> onLoad() async {
    final w = layout.width;
    final h = layout.height;

    add(
      RectangleComponent(
        position: Vector2.zero(),
        size: Vector2(w, h),
        paint: Paint()..color = Color(layout.floorColor),
      ),
    );

    // Back wall along the top, then thinner side walls and a bottom wall
    // split by the doorway so the player can stand in the exit.
    _addSolid(
      RectangleComponent(
        position: Vector2.zero(),
        size: Vector2(w, backWallHeight),
        paint: Paint()..color = Color(layout.wallColor),
      ),
    );
    final trim = Paint()..color = Color(layout.trimColor);
    _addSolid(
      RectangleComponent(
        position: Vector2(0, backWallHeight),
        size: Vector2(wallThickness, h - backWallHeight),
        paint: trim,
      ),
    );
    _addSolid(
      RectangleComponent(
        position: Vector2(w - wallThickness, backWallHeight),
        size: Vector2(wallThickness, h - backWallHeight),
        paint: trim,
      ),
    );
    final doorHalf = layout.doorWidth / 2;
    _addSolid(
      RectangleComponent(
        position: Vector2(0, h - wallThickness),
        size: Vector2(w / 2 - doorHalf, wallThickness),
        paint: trim,
      ),
    );
    _addSolid(
      RectangleComponent(
        position: Vector2(w / 2 + doorHalf, h - wallThickness),
        size: Vector2(w / 2 - doorHalf, wallThickness),
        paint: trim,
      ),
    );

    for (final prop in layout.props) {
      _addSolid(InteriorPropBlock(prop: prop, locationId: layout.id));
    }

    _exitDoor = ExitDoor(layout: layout, at: doorPosition);
    add(_exitDoor!);
  }

  void _addSolid(PositionComponent component) {
    _solids.add(component);
    add(component);
  }
}

/// Doorway leading back to the town.
class ExitDoor extends PositionComponent implements Interactable {
  final InteriorLayout layout;

  ExitDoor({required this.layout, required Vector2 at})
    : super(
        position: at,
        size: Vector2(layout.doorWidth, InteriorWorld.doorHeight),
        anchor: Anchor.center,
      );

  @override
  String get interactId => 'exit_${layout.id}';

  @override
  String get interactLabel => 'Leave ${layout.title}';

  @override
  bool get isSeat => false;

  @override
  Vector2 get interactPosition => position;

  /// Body contact: the doorway's own box, extended onto the room side
  /// so the entry spawn (96px inside the door) still targets it.
  @override
  Rect get touchRect => toRect().expandToInclude(
    Rect.fromCenter(
      center: Offset(position.x, position.y - 100),
      width: size.x,
      height: 200,
    ),
  );

  @override
  Future<void> onInteract(LifeInteractContext ctx) => ctx.exitLocation();

  @override
  void render(Canvas canvas) {
    final opening = Paint()..color = const Color(0xFF3A2C26);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), opening);
    // Daylight spilling through the doorway.
    canvas.drawRect(
      Rect.fromLTWH(0, size.y - 16, size.x, 16),
      Paint()..color = const Color(0xFFFFF3D6),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, 8),
      Paint()..color = const Color(0xFF241A15),
    );
    drawCenteredLabel(canvas, size, 'EXIT', color: Colors.white, fontSize: 20);
  }
}

/// A furniture item the player can examine, or that opens the location menu.
/// Chairs, benches, pews and sofas are sittable: they call `sitDown` so the
/// player rests and recovers energy.
class InteriorPropBlock extends RectangleComponent implements Interactable {
  final InteriorProp prop;
  final String locationId;

  InteriorPropBlock({required this.prop, required this.locationId})
    : super(
        position: Vector2(prop.x, prop.y),
        size: Vector2(prop.w, prop.h),
        paint: Paint()..color = Color(prop.color),
      );

  /// Labels that count as seats (case-insensitive substring match).
  static const _seatHints = ['bench', 'pew', 'chair', 'sofa', 'stool', 'couch'];

  bool get _sittable =>
      (prop.sit ?? false) ||
      _seatHints.any(
        (h) =>
            (prop.label ?? '').toLowerCase().contains(h) ||
            (prop.interactLabel ?? '').toLowerCase().contains(h),
      );

  @override
  bool get isSeat => _sittable;

  @override
  String get interactId =>
      'prop_${locationId}_${prop.x.toInt()}_${prop.y.toInt()}';

  @override
  String get interactLabel {
    if (_sittable) {
      final what = (prop.label ?? '').isNotEmpty
          ? prop.label!.toLowerCase()
          : 'seat';
      return 'Sit on the $what';
    }
    return prop.interactLabel ?? (prop.opensMenu ? 'Open menu' : 'Look around');
  }

  @override
  Vector2 get interactPosition => center;

  /// Body contact: the furniture's box plus a small margin, so standing right
  /// against a bench / pew / sofa counts as touching it. Collision stops the
  /// feet just outside the solid, which is what the margin covers.
  @override
  Rect get touchRect => toRect().inflate(24);

  @override
  Future<void> onInteract(LifeInteractContext ctx) async {
    if (prop.sleep) {
      ctx.sleepInBed();
      return;
    }
    if (_sittable) {
      ctx.sitDown();
      return;
    }
    if (prop.opensMenu) {
      ctx.openLocationMenu(locationId);
      return;
    }
    ctx.showMessage(prop.message ?? 'Nothing interesting here.');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final label = prop.label;
    if (label == null || label.isEmpty) return;
    // Highlight items that open the action menu.
    if (prop.opensMenu) {
      canvas.drawRect(
        Rect.fromLTWH(3, 3, size.x - 6, size.y - 6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0xFFFFF3D6),
      );
    }
    drawCenteredLabel(
      canvas,
      size,
      label,
      color: Colors.white,
      fontSize: 20,
      shadow: true,
    );
  }
}

/// Draws a bold centred label inside [size], used by interior components.
///
/// Text layout is cached per unique style: these labels are static, and
/// laying out a TextPainter every frame for every building (~20 × 60fps)
/// was a major frame-time cost on phones (visible as camera stutter
/// while walking zoomed).
final Map<String, TextPainter> _labelCache = {};

void drawCenteredLabel(
  Canvas canvas,
  Vector2 size,
  String text, {
  required Color color,
  required double fontSize,
  bool shadow = false,
}) {
  final key = '$text|$fontSize|${color.toARGB32()}|$shadow';
  var painter = _labelCache[key];
  if (painter == null) {
    painter =
        TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              shadows: shadow
                  ? const [Shadow(color: Colors.black54, blurRadius: 3)]
                  : null,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
    _labelCache[key] = painter;
  }
  painter.paint(
    canvas,
    Offset((size.x - painter.width) / 2, (size.y - painter.height) / 2),
  );
}
