import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
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

  /// Player feet position fed in by LifeGame each frame (like the town's
  /// traffic feed). Drives furniture depth-sorting below.
  Vector2? playerPosition;

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
      final block = InteriorPropBlock(prop: prop, locationId: layout.id);
      _propBlocks.add(block);
      _addSolid(block);
      // Animated trigger point floating over the furniture, so the
      // interaction spot is visible without hunting for it.
      add(
        TriggerMarker(
          at: Vector2(prop.x + prop.w / 2, prop.y - 30),
        ),
      );
    }

    _exitDoor = ExitDoor(layout: layout, at: doorPosition);
    add(_exitDoor!);

    // Furniture art loads in the background (same pattern as TownWorld
    // lot sprites): gameplay / collision never waits for image decodes,
    // and the flat color rect renders until the art arrives.
    _loadPropArt();
  }

  /// Custom sprite art per furniture prop, assigned in the background.
  final List<InteriorPropBlock> _propBlocks = [];

  void _loadPropArt() {
    for (final block in _propBlocks) {
      final art = block.prop.art;
      if (art == null) continue;
      Sprite.load(art).then(block.setSprite).catchError((_) {});
    }
  }

  /// Depth-sort furniture against the player (Y-sort): collision only
  /// guards the feet box while the figure is 82px tall and always drawn
  /// on top, so without this the body visibly sinks INTO tall art when
  /// standing behind it. Furniture whose base is below the player's feet
  /// draws under them (101, over the player); anything else stays under
  /// the player (50, above floor and walls).
  @override
  void update(double dt) {
    super.update(dt);
    final py = playerPosition?.y;
    if (py == null) return;
    for (final block in _propBlocks) {
      final base = block.position.y + block.size.y;
      block.priority = py < base - 10 ? 101 : 50;
    }
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

  /// Custom art for [prop.art], assigned in the background by
  /// [InteriorWorld]. Falls back to the flat color rect until it arrives.
  Sprite? _sprite;

  void setSprite(Sprite sprite) {
    _sprite = sprite;
  }

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

  /// Body contact: a generous halo around all four sides of the furniture,
  /// so brushing ANY outside surface (top, bottom, left, right) triggers
  /// it. Collision stops the feet just outside the solid, which is what
  /// the margin covers. Overlapping zones resolve to the nearest target
  /// by distance.
  @override
  Rect get touchRect => toRect().inflate(64);

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
    // Sprite art replaces the flat rect + text label (the art speaks for
    // itself). Contain-fit: never crops, transparent margins blend into
    // the room floor. No menu highlight on art: the stroke reads as a
    // frame around detailed sprites, and the touch button already names
    // the action (it stays for procedurally drawn props).
    final sprite = _sprite;
    if (sprite != null) {
      // Rotated art (e.g. the dining table turned 90° CCW): spin the
      // canvas around the rect center, then fit into the swapped box.
      // Positive [artTurns] = counter-clockwise.
      if (prop.artTurns != 0) {
        final src = sprite.srcSize;
        final eff = Vector2(size.y, size.x);
        final fit = (eff.x / src.x < eff.y / src.y)
            ? eff.x / src.x
            : eff.y / src.y;
        final drawSize = Vector2(src.x * fit, src.y * fit);
        canvas.save();
        canvas.translate(size.x / 2, size.y / 2);
        canvas.rotate(-math.pi / 2 * prop.artTurns);
        sprite.render(canvas, position: -drawSize / 2, size: drawSize);
        canvas.restore();
        return;
      }
      final src = sprite.srcSize;
      final fit = (size.x / src.x < size.y / src.y)
          ? size.x / src.x
          : size.y / src.y;
      final drawSize = Vector2(src.x * fit, src.y * fit);
      final offset = (size - drawSize) / 2;
      sprite.render(canvas, position: offset, size: drawSize);
      return;
    }
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

/// Floating trigger point over a furniture prop: a gently pulsing gold
/// ring that marks exactly where an interaction lives. Purely visual —
/// never solid, never an interactable itself.
class TriggerMarker extends PositionComponent {
  double _phase = 0.0;

  TriggerMarker({required Vector2 at})
    : super(
        position: at,
        size: Vector2(48, 48),
        anchor: Anchor.center,
        // Above furniture and the player: the trigger point must stay
        // visible even when its prop is drawn over the player.
        priority: 102,
      );

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 2.5;
  }

  @override
  void render(Canvas canvas) {
    final pulse = (math.sin(_phase) + 1) / 2; // 0..1
    canvas.save();
    canvas.translate(0, math.sin(_phase) * 4);
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(
      center,
      10 + 7 * pulse,
      Paint()
        ..color = Colors.white.withAlpha((40 + 120 * (1 - pulse)).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      center,
      4,
      Paint()..color = Colors.white.withAlpha(220),
    );
    canvas.restore();
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
