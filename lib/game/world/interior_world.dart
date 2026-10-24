import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
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

    // Glazed windows sit on the back wall, above every piece of furniture.
    for (final window in layout.windows) {
      add(InteriorWindowBlock(spec: window, layout: layout));
    }

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

/// A wooden-framed, glazed window set into the back wall of a room.
///
/// Hand-drawn with the room's trim colour for the casing and mullions.
/// The glass is a sky-blue gradient with soft clouds, a hedge line, and
/// slanted reflection bands so it reads as real glazing rather than a
/// flat blue rectangle. Sheer drapes hang at the sides. Purely visual:
/// no collision, no interaction.
class InteriorWindowBlock extends PositionComponent {
  final InteriorWindow spec;
  final InteriorLayout layout;

  InteriorWindowBlock({required this.spec, required this.layout})
    : super(
        position: Vector2(spec.x, spec.y),
        size: Vector2(spec.width, spec.height),
        // Above the wall paint, below furniture (priority 50/101).
        priority: 1,
      );

  static Color _shade(Color c, double amount) => amount >= 0
      ? Color.lerp(c, Colors.black, amount)!
      : Color.lerp(c, Colors.white, -amount)!;

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final wood = Color(layout.trimColor);
    final woodDark = _shade(wood, 0.38);
    final woodLight = _shade(wood, -0.28);

    // Soft shadow the casing casts onto the wall (down and to the right).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 8, w + 10, h + 12),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0x22000000),
    );

    // Outer casing, then the lighter face, giving the frame depth.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(10),
      ),
      Paint()..color = woodDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 3, w - 6, h - 6),
        const Radius.circular(8),
      ),
      Paint()..color = wood,
    );

    final glassRect = Rect.fromLTWH(12, 12, w - 24, h - 24);
    final glass = RRect.fromRectAndRadius(
      glassRect,
      const Radius.circular(4),
    );

    // Sky gradient behind the glass.
    canvas.drawRRect(
      glass,
      Paint()
        ..shader = ui.Gradient.linear(
          glassRect.topCenter,
          glassRect.bottomCenter,
          const [Color(0xFFD6EEFB), Color(0xFF9CCFEA), Color(0xFF6FA6C6)],
          const [0.0, 0.55, 1.0],
        ),
    );

    canvas.save();
    canvas.clipRRect(glass);
    _drawOutside(canvas, glassRect);
    _drawReflections(canvas, glassRect);
    canvas.restore();

    // Glass edge: thin bright inner highlight along the top and left.
    canvas.drawRRect(
      glass.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withAlpha(120),
    );

    // Mullions: one vertical, one horizontal bar split the glazing.
    final bar = Paint()..color = wood;
    final barHi = Paint()..color = woodLight;
    final barShadow = Paint()
      ..color = Colors.black.withAlpha(45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final vBar = Rect.fromLTWH(w / 2 - 3.5, glassRect.top, 7, glassRect.height);
    final hBar = Rect.fromLTWH(
      glassRect.left,
      glassRect.top + glassRect.height * 0.56,
      glassRect.width,
      6,
    );
    canvas.drawRect(vBar.shift(const Offset(1.5, 1.5)), Paint()..color = const Color(0x33000000));
    canvas.drawRect(vBar, bar);
    canvas.drawRect(hBar.shift(const Offset(1.5, 1.5)), Paint()..color = const Color(0x33000000));
    canvas.drawRect(hBar, bar);
    canvas.drawLine(
      vBar.topLeft + const Offset(2, 0),
      vBar.bottomLeft + const Offset(2, 0),
      barHi..strokeWidth = 1.2,
    );
    canvas.drawLine(
      hBar.topLeft + const Offset(0, 2),
      hBar.topRight + const Offset(0, 2),
      barHi,
    );
    // Drawn stroke on the inside of the casing to seat the glass.
    canvas.drawRRect(
      glass.inflate(0.5),
      barShadow,
    );

    // Brass latch where the glazing bars cross.
    canvas.drawCircle(
      Offset(w / 2, glassRect.top + glassRect.height * 0.56 + 4),
      3,
      Paint()..color = const Color(0xFFD9B75C),
    );

    // Sill under the window, with its own small shadow.
    final sillRect = Rect.fromLTWH(-8, h - 5, w + 16, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        sillRect.shift(const Offset(0, 5)),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0x33000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sillRect, const Radius.circular(4)),
      Paint()..color = woodLight,
    );
    canvas.drawLine(
      sillRect.topLeft + const Offset(4, 1.5),
      sillRect.topRight + const Offset(-4, 1.5),
      Paint()
        ..color = Colors.white.withAlpha(110)
        ..strokeWidth = 1.6,
    );

    if (spec.curtains) _drawCurtains(canvas, w, h, woodDark);
  }

  /// What you see through the glass: clouds and a hedge in the garden.
  void _drawOutside(Canvas canvas, Rect r) {
    // Warmer afternoon light pooling near the bottom of the pane.
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(
          r.topCenter,
          r.bottomCenter,
          [const Color(0x00FFF6D8), const Color(0x22FFF1C9)],
          const [0.55, 1.0],
        ),
    );

    final cloud = Paint()..color = Colors.white.withAlpha(200);
    void cloudAt(double cx, double cy, double s) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: 52 * s,
          height: 16 * s,
        ),
        cloud,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - 13 * s, cy - 7 * s),
          width: 30 * s,
          height: 18 * s,
        ),
        cloud,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + 12 * s, cy - 8 * s),
          width: 34 * s,
          height: 20 * s,
        ),
        cloud,
      );
    }

    cloudAt(r.left + r.width * 0.24, r.top + r.height * 0.30, 1.0);
    cloudAt(r.left + r.width * 0.74, r.top + r.height * 0.18, 0.72);

    // Distant hedge line along the bottom of the pane.
    final hedge = Paint()..color = const Color(0xFF8FBE76);
    final hedgeDark = Paint()..color = const Color(0xFF6E9A58);
    canvas.drawRect(
      Rect.fromLTWH(r.left, r.bottom - 16, r.width, 16),
      hedgeDark,
    );
    for (double cx = r.left - 8; cx < r.right + 14; cx += 24) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, r.bottom - 16),
          width: 34,
          height: 30,
        ),
        hedge,
      );
    }
    // A hint of a tree trunk and canopy behind the hedge.
    canvas.drawRect(
      Rect.fromLTWH(r.left + r.width * 0.82, r.bottom - 36, 4, 22),
      Paint()..color = const Color(0xFF8A6A4B),
    );
    canvas.drawCircle(
      Offset(r.left + r.width * 0.82 + 2, r.bottom - 40),
      17,
      Paint()..color = const Color(0xFF74A75F),
    );
  }

  /// Slanted white bands that read as sky reflections on the glass.
  void _drawReflections(Canvas canvas, Rect r) {
    void band(double start, double width) {
      final x = r.left + r.width * start;
      final slope = r.height * 0.6;
      final path = Path()
        ..moveTo(x, r.top)
        ..lineTo(x + r.width * width, r.top)
        ..lineTo(x + r.width * width - slope, r.bottom)
        ..lineTo(x - slope, r.bottom)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0x2EFFFFFF));
    }

    band(-0.05, 0.22);
    band(0.42, 0.12);
  }

  /// Sheer drapes hanging from a rod above the casing.
  void _drawCurtains(Canvas canvas, double w, double h, Color rodColor) {
    const rodY = -12.0;
    final rodPaint = Paint()
      ..color = rodColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(-20, rodY),
      Offset(w + 20, rodY),
      rodPaint,
    );
    final finial = Paint()..color = rodColor;
    canvas.drawCircle(const Offset(-20, rodY), 5, finial);
    canvas.drawCircle(Offset(w + 20, rodY), 5, finial);

    final fabric = Paint()..color = const Color(0xE0F4E4D2);
    final fold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0x2E8A6844);

    final left = Path()
      ..moveTo(-16, rodY + 2)
      ..lineTo(22, rodY + 2)
      ..quadraticBezierTo(16, h * 0.5, 24, h + 6)
      ..lineTo(-22, h + 6)
      ..quadraticBezierTo(-14, h * 0.45, -16, rodY + 2)
      ..close();
    canvas.drawPath(left, fabric);
    for (final f in const [0.0, 0.45, 0.9]) {
      final x = -16 + f * 34;
      canvas.drawPath(
        Path()
          ..moveTo(x, rodY + 6)
          ..quadraticBezierTo(x + 5, h * 0.5, x + 2, h + 4),
        fold,
      );
    }

    final right = Path()
      ..moveTo(w + 16, rodY + 2)
      ..lineTo(w - 22, rodY + 2)
      ..quadraticBezierTo(w - 16, h * 0.5, w - 24, h + 6)
      ..lineTo(w + 22, h + 6)
      ..quadraticBezierTo(w + 14, h * 0.45, w + 16, rodY + 2)
      ..close();
    canvas.drawPath(right, fabric);
    for (final f in const [0.0, 0.45, 0.9]) {
      final x = w + 16 - f * 34;
      canvas.drawPath(
        Path()
          ..moveTo(x, rodY + 6)
          ..quadraticBezierTo(x - 5, h * 0.5, x - 2, h + 4),
        fold,
      );
    }
  }
}

/// A furniture item the player can examine, or that opens the location menu.
/// Chairs, benches, pews and sofas are sittable: they call `sitDown` so the
/// player rests and recovers energy.
class InteriorPropBlock extends RectangleComponent
    implements Interactable, RelaxationSeat {
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
  bool get opensRelaxScene => prop.relaxScene;

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
