import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'feet_collision.dart';
import 'interactable.dart';
import 'life_world.dart';
import 'map_data.dart';
import 'pedestrian.dart';
import 'vehicle.dart';
import 'interior_world.dart' show drawCenteredLabel;
import '../../models/location_dialogue.dart';

class TownWorld extends LifeWorld implements TrafficHost {
  final void Function(Interactable?) onNearestChanged;
  final Random random;

  late final List<BuildingBlock> buildings;
  late final List<StreetProp> streetProps;
  final List<Pedestrian> pedestrians = [];
  final List<PositionComponent> _solids = [];
  late final List<Rect> _walkBands = buildPedestrianBands();

  /// Live traffic: staggered signals, cars and bicycles per highway.
  late final TrafficSystem traffic = TrafficSystem();
  final List<VehicleComponent> vehicles = [];
  final List<TrafficLightProp> signals = [];

  /// Player position fed in by LifeGame each frame (null inside rooms).
  /// Cars treat a player standing on a zebra crossing as a red light.
  Vector2? playerPosition;

  TownWorld({required this.onNearestChanged, Random? random})
    : random = random ?? Random() {
    buildings = buildTownLocations()
        .map(
          (loc) => BuildingBlock(
            location: loc,
            interactId: 'enter_${loc.id}',
            interactLabel: 'Enter ${loc.name}',
          ),
        )
        .toList();
    streetProps = buildTownDecorations()
        .where((d) => d.solid)
        // Safety: lamps never spawn centered on asphalt or junctions —
        // grass/sidewalk edge only, so they never block the way.
        .where(
          (d) => (d.kind != 'lamp') || !isOnAnyAsphalt(d.x, d.y),
        )
        .map((d) => StreetProp(decoration: d))
        .toList();
  }

  @override
  Vector2 get worldSize => Vector2(kWorldWidth, kWorldHeight);

  @override
  List<PositionComponent> solidBounds() => _solids;

  @override
  Future<void> onLoad() async {
    add(TownBackdrop());

    for (final prop in streetProps) {
      _solids.add(prop);
      add(prop);
    }
    for (final b in buildings) {
      _solids.add(b);
      add(b);
    }

    // Standalone cash machine in band 4, on the grass between the bank
    // (ends x1240) and the police station (starts x2120).
    final atm = AtmProp(at: Vector2(1650, 1960));
    _solids.add(atm);
    add(atm);

    _spawnPedestrians();
    _spawnTraffic();

    // Load custom lot sprites in the background: assigning the field later
    // is safe (no mount lifecycle involved), and gameplay / collision must
    // not wait for image decodes. Art is cover-fit and clipped to the
    // lot in render, so visuals can never spill past collision (no
    // standing on building sides).
    _loadLotSprite('home.png', 'home', labelColor: Colors.white);
    _loadLotSprite('plaza.jpg', 'plaza', labelColor: Colors.white);
    _loadLotSprite('school.png', 'school', labelColor: Colors.white);
    _loadLotSprite('church.png', 'church', labelColor: Colors.white);
    _loadLotSprite('park.png', 'park', labelColor: Colors.white);
    _loadLotSprite('cafe.png', 'workplace', labelColor: Colors.white);
    _loadTreeSprite();
  }

  void _loadLotSprite(
    String file,
    String locationId, {
    Color labelColor = Colors.black87,
  }) {
    Sprite.load(file).then((sprite) {
      for (final b in buildings) {
        if (b.location.id == locationId) {
          b.setSprite(sprite, labelColor: labelColor);
        }
      }
    }).catchError((_) {});
  }

  /// Loads tree.png in the background and hands it to every tree prop.
  /// Gameplay / collision never waits for the decode; trees render the
  /// procedural canopy until the art arrives.
  void _loadTreeSprite() {
    Sprite.load('tree.png').then((sprite) {
      for (final prop in streetProps) {
        if (prop.decoration.kind == 'tree') prop.setTreeSprite(sprite);
      }
    }).catchError((_) {});
  }

  /// A handful of townspeople wandering the sidewalks on their own routes.
  void _spawnPedestrians() {
    const shirts = [
      Color(0xFF6D9EEB),
      Color(0xFFE69138),
      Color(0xFF8E7CC3),
      Color(0xFF93C47D),
      Color(0xFFD5A6BD),
      Color(0xFF76A5AF),
      Color(0xFFCC4125),
      Color(0xFFB4A7D6),
    ];
    const hairs = [
      Color(0xFF3E2C22),
      Color(0xFF1F1A17),
      Color(0xFF6B4423),
      Color(0xFF2B2B2B),
    ];
    final bands = buildPedestrianBands();

    for (var i = 0; i < 10; i++) {
      final band = bands[i % bands.length];
      // Find a spot that is not inside a bench, lamp or building.
      var spawn = _randomPointIn(band);
      for (var attempt = 0; attempt < 20 && _overlapsSolid(spawn); attempt++) {
        spawn = _randomPointIn(band);
      }
      final walker = Pedestrian(
        spawn: spawn,
        target: spawn.clone(),
        random: random,
        shirt: shirts[i % shirts.length],
        hair: hairs[i % hairs.length],
        walkSpeed: 58 + random.nextDouble() * 32,
      );
      walker.pickTarget(bands);
      // Spread everyone out so they do not drift as one crowd, and keep the
      // frame-0 reference position in step with the final spot.
      walker.position.x = (walker.position.x + random.nextDouble() * 120 - 60)
          .clamp(60.0, kWorldWidth - 60);
      walker.previousPosition.setFrom(walker.position);
      pedestrians.add(walker);
      add(walker);
    }
  }

  Vector2 _randomPointIn(Rect band) => Vector2(
    band.left + random.nextDouble() * band.width,
    band.top + random.nextDouble() * band.height,
  );

  bool _overlapsSolid(Vector2 point) {
    final rect = const FeetBody(halfWidth: 15, halfHeight: 15).rectAt(point);
    return _solids.any((solid) => rect.overlaps(solid.toRect()));
  }

  /// Flame updates a component *before* its children, so collision cleanup
  /// has to happen in [updateTree] - after the wanderers have moved this
  /// frame - otherwise somebody is always left standing inside a wall.
  @override
  void updateTree(double dt) {
    super.updateTree(dt);
    if (!isMounted) return;

    // Advance the signal cycle; vehicles read phases in their own update.
    traffic.update(dt);

    // Enforce bumper separation after every vehicle has moved.
    _separateTraffic();

    final bands = _walkBands;
    for (final walker in pedestrians) {
      final blocked = resolveFeetCollision(
        position: walker.position,
        previous: walker.previousPosition,
        solids: _solids,
        body: const FeetBody(halfWidth: 15, halfHeight: 15),
      );
      // Blocked or arrived: pick a new route instead of grinding against a
      // wall.
      if (blocked || walker.hasArrived) {
        walker.pickTarget(bands);
        walker.position.x = walker.position.x.clamp(60.0, kWorldWidth - 60);
        walker.position.y = walker.position.y.clamp(100.0, kWorldHeight - 40);
        walker.previousPosition.setFrom(walker.position);
      }
    }
  }

  /// Where the player should stand after leaving [locationId], just in front
  /// of that building's door.
  Vector2 doorSpawn(String locationId) {
    for (final b in buildings) {
      if (b.location.id == locationId) {
        return b.doorPosition + Vector2(0, b.location.doorOnTop ? -56 : 56);
      }
    }
    return Vector2(kWorldWidth / 2, kWorldHeight / 2);
  }

  Interactable? nearestInteractable(Vector2 playerPos, {double radius = 130}) {
    Interactable? best;
    var bestDist = radius;
    for (final b in buildings) {
      final d = b.interactPosition.distanceTo(playerPos);
      if (d < bestDist) {
        bestDist = d;
        best = b;
      }
    }
    return best;
  }

  // --- TrafficHost ----------------------------------------------------------

  @override
  LightPhase phaseAtJunction(int index) => traffic.phaseAt(index);

  /// True while the player stands on junction [index]'s zebra crossing:
  /// approaching vehicles treat it as a red light and halt.
  @override
  bool crossingBlocked(int index) {
    final p = playerPosition;
    if (p == null || index < 0 || index >= kHighwayTops.length) return false;
    final top = kHighwayTops[index];
    return p.x > kCrossStreetLeft - 12 &&
        p.x < kCrossStreetRight + 12 &&
        p.y > top - 6 &&
        p.y < top + kHighwayHeight + 6;
  }

  /// Bumper-to-bumper gap to the nearest vehicle ahead in the same lane,
  /// or null when the road ahead is clear.
  @override
  double? gapAhead(VehicleComponent self) {
    final lead = _leaderAhead(self);
    if (lead == null) return null;
    return (lead.position.x - self.position.x) * self.dir -
        lead.halfLen -
        self.halfLen;
  }

  @override
  double? speedAhead(VehicleComponent self) => _leaderAhead(self)?.speed;

  VehicleComponent? _leaderAhead(VehicleComponent self) {
    VehicleComponent? best;
    var bestDist = double.infinity;
    for (final v in vehicles) {
      if (identical(v, self)) continue;
      if (v.highwayTop != self.highwayTop || v.dir != self.dir) continue;
      final d = (v.position.x - self.position.x) * self.dir;
      if (d > -10 && d < bestDist) {
        bestDist = d;
        best = v;
      }
    }
    return best;
  }

  /// Distance from [self]'s front bumper to the nearest player or
  /// pedestrian ahead in its lane (null when clear). Wanderers stick to
  /// sidewalks, so this only fires for genuine crossings/jaywalking —
  /// one lane yields, the rest of the town keeps rolling.
  @override
  double? pedestrianAhead(VehicleComponent self) {
    double? best;
    void consider(Vector2 p) {
      // Lane bodies are 80px tall with 52px cars inside: 30px keeps
      // sidewalk walkers (44px+ from center) flowing while anything
      // actually on the asphalt yields.
      if ((p.y - self.position.y).abs() > 30) return;
      final d =
          (p.x - self.position.x) * self.dir - self.halfLen;
      if (d > -6 && d < 300 && (best == null || d < best!)) best = d;
    }

    final pp = playerPosition;
    if (pp != null) consider(pp);
    for (final w in pedestrians) {
      consider(w.position);
    }
    return best;
  }

  /// Hard separation guarantee: after vehicles move, walk each lane
  /// front-to-back and push any overlapping rear bumper back. Visual
  /// overlap becomes impossible even across spawns and wrap-arounds.
  void _separateTraffic() {
    const minGap = 26.0;
    for (final top in kHighwayTops) {
      for (final dir in const [1, -1]) {
        // Front of the lane first: largest x eastbound, smallest west.
        final lane = [
          for (final v in vehicles)
            if (v.highwayTop == top && v.dir == dir) v,
        ]..sort((a, b) => dir > 0
            ? b.position.x.compareTo(a.position.x)
            : a.position.x.compareTo(b.position.x));
        for (var i = 1; i < lane.length; i++) {
          final front = lane[i - 1];
          final rear = lane[i];
          final gap = (front.position.x - rear.position.x) * dir -
              front.halfLen -
              rear.halfLen;
          if (gap < minGap) {
            rear.position.x =
                front.position.x - dir * (front.halfLen + rear.halfLen + minGap);
            if (rear.speed > front.speed) rear.speed = front.speed;
          }
        }
      }
    }
  }

  /// Two signals (diagonal corners) per junction plus cars and a bicycle
  /// on every highway, spread out so nothing starts piled at a light.
  void _spawnTraffic() {
    const carColors = [
      Color(0xFFCC4125),
      Color(0xFF4A86E8),
      Color(0xFFBDC3C7),
      Color(0xFF1F1A17),
      Color(0xFFFFD966),
      Color(0xFF8E7CC3),
    ];
    for (var j = 0; j < kHighwayTops.length; j++) {
      final top = kHighwayTops[j];
      final bottom = top + kHighwayHeight;
      signals.add(
        TrafficLightProp(
          host: this,
          junction: j,
          at: Vector2(kCrossStreetRight + 26, top - 30),
        ),
      );
      signals.add(
        TrafficLightProp(
          host: this,
          junction: j,
          at: Vector2(kCrossStreetLeft - 26, bottom + 34),
        ),
      );
      for (final dir in const [1, -1]) {
        // Deterministic slots spread down the lane: nobody spawns
        // piled up or overlapping, whatever the seed.
        for (var k = 0; k < 2; k++) {
          final x = kWorldWidth * (0.18 + 0.42 * k) +
              (random.nextDouble() - 0.5) * 240;
          vehicles.add(
            VehicleComponent(
              host: this,
              kind: VehicleKind.car,
              highwayTop: top,
              junction: j,
              dir: dir,
              spawn: Vector2(
                x.clamp(120.0, kWorldWidth - 120),
                laneCenterY(top, dir),
              ),
              cruiseSpeed: 240 + random.nextDouble() * 90,
              color: carColors[(j * 2 + (dir > 0 ? k : k + 1)) %
                  carColors.length],
            ),
          );
        }
        if (j.isEven == (dir > 0)) {
          vehicles.add(
            VehicleComponent(
              host: this,
              kind: VehicleKind.bicycle,
              highwayTop: top,
              junction: j,
              dir: dir,
              spawn: Vector2(
                (kWorldWidth * 0.82 + (random.nextDouble() - 0.5) * 200)
                    .clamp(120.0, kWorldWidth - 120),
                laneCenterY(top, dir) + (dir > 0 ? 22 : -22),
              ),
              cruiseSpeed: 100 + random.nextDouble() * 40,
              color: const Color(0xFFE69138),
            ),
          );
        }
      }
    }
    for (final s in signals) {
      add(s);
    }
    for (final v in vehicles) {
      add(v);
    }
  }
}

/// Ground, highway, sidewalks, lane markings and the soft planting. Purely
/// visual: everything the player collides with is a separate component.
class TownBackdrop extends PositionComponent {
  TownBackdrop()
    : super(
        position: Vector2.zero(),
        size: Vector2(kWorldWidth, kWorldHeight),
        priority: -10,
      );

  static final List<TownStrip> _roads = buildTownRoads();
  static final List<TownDecoration> _planting = [
    for (final d in buildTownDecorations())
      if (!d.solid &&
          !decorationOnRoad(d.y, margin: 24) &&
          !isOnAnyAsphalt(d.x, d.y))
        d,
  ];

  /// Soft large-scale tonal variation to break up tile repetition.
  /// Deterministic so it looks identical every run.
  static final List<_GrassPatch> _patches = (() {
    final r = Random(11);
    return List.generate(46, (_) {
      return _GrassPatch(
        x: r.nextDouble() * kWorldWidth,
        y: r.nextDouble() * kWorldHeight,
        radius: 140 + r.nextDouble() * 320,
        color: r.nextBool()
            ? const Color(0xFF5E7F43)
            : const Color(0xFF8FAE6B),
        opacity: 0.06 + r.nextDouble() * 0.07,
      );
    });
  })();

  ui.Image? _grassTile;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final sprite = await Sprite.load('grass_tile.png');
      _grassTile = sprite.image;
    } catch (_) {
      _grassTile = null;
    }
  }

  @override
  void render(Canvas canvas) {
    // Ground: realistic tiled grass, single draw via ImageShader.
    // Falls back to a natural flat green if the tile is not ready.
    final tile = _grassTile;
    if (tile != null) {
      // Base underneath (seams / load gaps never flash light green).
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF6F9155),
      );
      final shaderPaint = Paint()
        ..shader = ui.ImageShader(
          tile,
          ui.TileMode.repeated,
          ui.TileMode.repeated,
          Float64List.fromList(const [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
          ]),
        );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        shaderPaint,
      );
      // Large soft patches kill the visible tiling grid.
      for (final p in _patches) {
        canvas.drawCircle(
          Offset(p.x, p.y),
          p.radius,
          Paint()..color = p.color.withValues(alpha: p.opacity),
        );
      }
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF6F9155),
      );
    }

    // Roads and sidewalks.
    for (final strip in _roads) {
      canvas.drawRect(
        Rect.fromLTWH(strip.x, strip.y, strip.w, strip.h),
        Paint()..color = Color(strip.color),
      );
    }

    _paintLaneMarkings(canvas);
    _paintSoftPlanting(canvas);
  }

  /// Dashed centre lines, solid edge lines and crosswalks, repeated for
  /// every highway that splits the town bands.
  void _paintLaneMarkings(Canvas canvas) {
    final dashes = Paint()..color = const Color(0xFFF2F2F2);
    const dashLength = 90.0;
    const gap = 70.0;

    for (final top in kHighwayTops) {
      final bottom = top + kHighwayHeight;
      final centreY = top + kHighwayHeight / 2;

      for (var x = 40.0; x < kWorldWidth - dashLength; x += dashLength + gap) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, centreY - 4, dashLength, 8),
            const Radius.circular(4),
          ),
          dashes,
        );
      }

      // Solid shoulders.
      for (final y in [top + 12, bottom - 20]) {
        canvas.drawRect(
          Rect.fromLTWH(0, y, kWorldWidth, 6),
          Paint()..color = const Color(0xFFEDEDED),
        );
      }

      // Zebra crossing where the streets meet.
      final crossing = Paint()..color = const Color(0xFFF2F2F2);
      for (var x = kCrossStreetLeft + 14; x < kCrossStreetRight - 14; x += 34) {
        canvas.drawRect(
          Rect.fromLTWH(x, top + 6, 20, kHighwayHeight - 12),
          crossing,
        );
      }

      // Stop lines: where each lane halts for red lights / pedestrians.
      final stopPaint = Paint()
        ..color = const Color(0xFFF2F2F2).withValues(alpha: 0.85);
      canvas.drawRect(
        Rect.fromLTWH(stopLineX(1) - 5, top + 10, 10, 60),
        stopPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(stopLineX(-1) - 5, top + 90, 10, 60),
        stopPaint,
      );
    }

    // Dashed centre line down the cross street, pausing at each highway.
    for (var y = 40.0; y < kWorldHeight - dashLength; y += dashLength + gap) {
      if (kHighwayTops.any((t) => y > t - 40 && y < t + kHighwayHeight + 40)) {
        continue;
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            kCrossStreetLeft + kCrossStreetWidth / 2 - 4,
            y,
            8,
            dashLength,
          ),
          const Radius.circular(4),
        ),
        dashes,
      );
    }
  }

  /// Hedges and flower beds (the non-solid planting).
  /// Grass only: anything on the highway corridor or crossing junction
  /// is skipped so the 5-red-dot flower beds never sit centered on roads.
  void _paintSoftPlanting(Canvas canvas) {
    for (final d in _planting) {
      if (decorationOnRoad(d.y, margin: 24)) continue;
      if (isOnAnyAsphalt(d.x, d.y)) continue;
      switch (d.kind) {
        case 'bush':
          canvas.drawCircle(
            Offset(d.x, d.y - d.size * 0.2),
            d.size * 0.45,
            Paint()..color = const Color(0xFF4E7A3A),
          );
          canvas.drawCircle(
            Offset(d.x - d.size * 0.2, d.y - d.size * 0.35),
            d.size * 0.3,
            Paint()..color = const Color(0xFF5F9445),
          );
          break;
        case 'flowers':
          final petals = Paint()..color = const Color(0xFFE06666);
          final leaves = Paint()..color = const Color(0xFF6AA84F);
          canvas.drawCircle(Offset(d.x, d.y), d.size * 0.5, leaves);
          for (var i = 0; i < 5; i++) {
            final angle = i * 1.256;
            canvas.drawCircle(
              Offset(
                d.x + cos(angle) * d.size * 0.28,
                d.y - d.size * 0.1 + sin(angle) * d.size * 0.22,
              ),
              d.size * 0.13,
              petals,
            );
          }
          break;
      }
    }
  }
}

/// Large soft tonal blob to hide tiling repetition on the grass.
class _GrassPatch {
  final double x;
  final double y;
  final double radius;
  final Color color;
  final double opacity;

  const _GrassPatch({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.opacity,
  });
}

/// A physical piece of street dressing: trees, benches, lamps and hydrants.
/// Only the small footprint at its base blocks movement, so the player can
/// walk under a tree canopy or past a bench top.
///
/// Only benches surface an action button ("Sit on the bench"); trees, lamps
/// and hydrants are scenery and are filtered out of the interact scan.
class StreetProp extends PositionComponent implements Interactable {
  final TownDecoration decoration;

  /// Custom tree art (tree.png), assigned in the background by TownWorld.
  /// Falls back to the procedural canopy until it arrives.
  Sprite? _treeSprite;

  void setTreeSprite(Sprite sprite) {
    _treeSprite = sprite;
  }

  StreetProp({required this.decoration})
    : super(
        // Trees rise above benches/lamps/hydrants so canopies never
        // get covered by nearby seating.
        priority: decoration.kind == 'tree' ? 45 : 40,
        anchor: Anchor.topLeft,
      ) {
    final s = decoration.size;
    size = switch (decoration.kind) {
      'tree' => Vector2(s * 0.34, s * 0.26),
      'bench' => Vector2(s, s * 0.3),
      'lamp' => Vector2(s * 0.22, s * 0.18),
      'hydrant' => Vector2(s * 0.66, s * 0.6),
      _ => Vector2(s, s * 0.5),
    };
    // decoration.x/y is the ground contact point at the centre of the base.
    position = Vector2(decoration.x - size.x / 2, decoration.y - size.y / 2);
  }

  @override
  void render(Canvas canvas) {
    // Lamps line the road — only skip them if centered on asphalt or
    // on the crossing junction where they would block the way.
    if (decoration.kind == 'lamp' &&
        isOnAnyAsphalt(decoration.x, decoration.y)) {
      return;
    }
    final s = decoration.size;
    switch (decoration.kind) {
      case 'tree':
        final tree = _treeSprite;
        if (tree != null) {
          // Bottom-center anchored on the ground contact point, rising
          // above the small collision footprint. Same visual bulk as
          // the old procedural canopy so spacing still reads.
          final src = tree.srcSize;
          final drawW = s * 1.05;
          final drawH = drawW * src.y / src.x;
          tree.render(
            canvas,
            position: Vector2((size.x - drawW) / 2, size.y - drawH),
            size: Vector2(drawW, drawH),
          );
          break;
        }
        final baseY = size.y;
        canvas.drawRect(
          Rect.fromLTWH(size.x / 2 - 7, 0, 14, baseY),
          Paint()..color = const Color(0xFF6B4423),
        );
        canvas.drawCircle(
          Offset(size.x / 2, -s * 0.28),
          s * 0.44,
          Paint()..color = const Color(0xFF3F7D3A),
        );
        canvas.drawCircle(
          Offset(size.x / 2 - s * 0.22, -s * 0.42),
          s * 0.3,
          Paint()..color = const Color(0xFF4E9946),
        );
        canvas.drawCircle(
          Offset(size.x / 2 + s * 0.2, -s * 0.36),
          s * 0.26,
          Paint()..color = const Color(0xFF357033),
        );
        break;
      case 'bench':
        final wood = Paint()..color = const Color(0xFF8C6239);
        final metal = Paint()..color = const Color(0xFF5A5A5A);
        canvas.drawRect(
          Rect.fromLTWH(0, size.y * 0.1, size.x, size.y * 0.45),
          wood,
        );
        canvas.drawRect(
          Rect.fromLTWH(4, size.y * 0.6, 10, size.y * 0.4),
          metal,
        );
        canvas.drawRect(
          Rect.fromLTWH(size.x - 14, size.y * 0.6, 10, size.y * 0.4),
          metal,
        );
        // Backrest.
        canvas.drawRect(
          Rect.fromLTWH(0, -size.y * 0.5, size.x, size.y * 0.35),
          Paint()..color = const Color(0xFF7A5230),
        );
        break;
      case 'lamp':
        canvas.drawRect(
          Rect.fromLTWH(size.x / 2 - 3, -size.y * 4, 6, size.y * 5),
          Paint()..color = const Color(0xFF4A4A4A),
        );
        canvas.drawCircle(
          Offset(size.x / 2, -size.y * 4.2),
          11,
          Paint()..color = const Color(0xFFFFF3D6),
        );
        break;
      case 'hydrant':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.x * 0.2, 0, size.x * 0.6, size.y),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xFFC0392B),
        );
        canvas.drawRect(
          Rect.fromLTWH(0, size.y * 0.35, size.x, 6),
          Paint()..color = const Color(0xFF922B21),
        );
        break;
    }
  }

  bool get _sittable => decoration.kind == 'bench';

  /// Only benches count as interactable: trees / lamps / hydrants return an
  /// empty anchor/label so the interact scan skips them entirely.
  bool get isInteractable => _sittable;

  @override
  String get interactId =>
      'prop_${decoration.kind}_${decoration.x.toInt()}_${decoration.y.toInt()}';

  @override
  String get interactLabel => 'Sit on the bench';

  @override
  bool get isSeat => _sittable;

  @override
  Vector2 get interactPosition => Vector2(
    decoration.x,
    decoration.y,
  );

  /// Body contact: the bench's footprint plus a small margin (the player's
  /// feet box is stopped just outside the solid by collision, so the margin
  /// is what makes "standing right at the bench" count as touching it).
  @override
  Rect get touchRect => toRect().inflate(24);

  @override
  Future<void> onInteract(LifeInteractContext ctx) async {
    if (_sittable) {
      ctx.sitDown();
      return;
    }
    ctx.showMessage('Nothing interesting here.');
  }
}

/// A standalone cash machine on the grass south of the sidewalk.
/// Small solid footprint at its base; the kiosk body is drawn rising above
/// it so it reads upright from the top-down camera.
class AtmProp extends PositionComponent implements Interactable {
  /// Ground contact point (centre of the base).
  AtmProp({required Vector2 at})
    : super(priority: 40, anchor: Anchor.topLeft) {
    size = Vector2(56, 48);
    position = Vector2(at.x - size.x / 2, at.y - size.y / 2);
  }

  @override
  String get interactId => 'use_atm';

  @override
  String get interactLabel => 'Use ATM';

  @override
  bool get isSeat => false;

  @override
  Vector2 get interactPosition =>
      Vector2(position.x + size.x / 2, position.y + size.y / 2);

  @override
  Rect get touchRect => toRect().inflate(28);

  @override
  Future<void> onInteract(LifeInteractContext ctx) async {
    ctx.useAtm();
  }

  @override
  void render(Canvas canvas) {
    const bodyW = 64.0;
    const bodyH = 104.0;
    final left = (size.x - bodyW) / 2;
    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y - 4),
        width: bodyW + 16,
        height: 18,
      ),
      Paint()..color = const Color(0x33000000),
    );
    // Kiosk body rising above its footprint.
    final bodyTop = size.y - 6 - bodyH;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, bodyTop, bodyW, bodyH),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF3E5C76),
    );
    // Header sign.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 6, bodyTop + 6, bodyW - 12, 20),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF1D3557),
    );
    // Screen.
    canvas.drawRect(
      Rect.fromLTWH(left + 10, bodyTop + 34, bodyW - 20, 30),
      Paint()..color = const Color(0xFFA8DADC),
    );
    // Keypad + cash slot.
    canvas.drawRect(
      Rect.fromLTWH(left + 10, bodyTop + 70, 20, 16),
      Paint()..color = const Color(0xFFF1FAEE),
    );
    canvas.drawRect(
      Rect.fromLTWH(left + bodyW - 30, bodyTop + 70, 20, 8),
      Paint()..color = const Color(0xFF1D3557),
    );
    // Label pinned under the kiosk.
    canvas.save();
    canvas.translate(0, size.y + 6);
    drawCenteredLabel(
      canvas,
      Vector2(size.x, 28),
      'ATM',
      color: Colors.white,
      fontSize: 20,
      shadow: true,
    );
    canvas.restore();
  }
}

class BuildingBlock extends RectangleComponent implements Interactable {  final LocationModel location;
  @override
  final String interactId;
  @override
  final String interactLabel;

  @override
  bool get isSeat => false;

  static const double doorWidth = 96;
  static const double doorHeight = 26;

  Sprite? _lotSprite;
  Color _spriteLabelColor = Colors.black87;

  BuildingBlock({
    required this.location,
    required this.interactId,
    required this.interactLabel,
  }) : super(
         position: Vector2(location.x, location.y),
         size: Vector2(location.w, location.h),
         priority: 10,
         paint: Paint()..color = Color(location.color),
       );

  /// Called once [TownWorld] finishes loading the lot art in the
  /// background. Synchronous so mounting a building never races with
  /// swapping the world in/out.
  void setSprite(Sprite sprite, {Color labelColor = Colors.black87}) {
    _lotSprite = sprite;
    _spriteLabelColor = labelColor;
  }

  /// Doorway on the wall facing the street, so the player can see where to
  /// go in.
  Vector2 get doorPosition => Vector2(
    position.x + size.x / 2,
    location.doorOnTop ? position.y : position.y + size.y,
  );

  @override
  Vector2 get interactPosition => doorPosition;

  /// Body contact: the doorway zone on the street side of the door.
  /// Tall enough (140px) to include the doorSpawn point 56px in front of
  /// the door, so standing in front of the door targets it.
  @override
  Rect get touchRect => Rect.fromCenter(
    center: Offset(doorPosition.x, doorPosition.y),
    width: 140,
    height: 140,
  );

  @override
  Future<void> onInteract(LifeInteractContext ctx) async {
    await ctx.enterLocation(location.id);
  }

  @override
  void render(Canvas canvas) {
    // Buildings with custom art render it as a top-down lot tile filling
    // the lot exactly (cover-fit + clip): visuals can never spill past
    // the collision rect, so the player can't stand on building sides.
    // Collision / door logic is unchanged.
    final lotSprite = _lotSprite;
    if (lotSprite != null) {
      // Soft grounding shadow along the south edge.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.x / 2, size.y - 6),
          width: size.x * 0.88,
          height: 40,
        ),
        Paint()..color = const Color(0x2E000000),
      );
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.x, size.y));
      final src = lotSprite.srcSize;
      final cover = max(size.x / src.x, size.y / src.y);
      final drawSize = Vector2(src.x * cover, src.y * cover);
      final offset = (size - drawSize) / 2;
      lotSprite.render(canvas, position: offset, size: drawSize);
      canvas.restore();
      drawCenteredLabel(
        canvas,
        Vector2(size.x, size.y + 36),
        location.name,
        color: _spriteLabelColor,
        fontSize: 28,
      );
      return;
    }
    super.render(canvas);

    // Roof trim, windows and the doorway.
    final trim = Paint()..color = const Color(0x33FFFFFF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 14), trim);
    final window = Paint()..color = const Color(0x662B3B4E);
    for (var i = 0; i < 4; i++) {
      final x = 26 + i * (size.x - 52) / 4 + 8;
      canvas.drawRect(Rect.fromLTWH(x, size.y * 0.42, 42, 46), window);
    }

    final onTop = location.doorOnTop;
    final doorLeft = (size.x - doorWidth) / 2;
    final doorTop = onTop ? 0.0 : size.y - doorHeight;
    final doorRect = Rect.fromLTWH(doorLeft, doorTop, doorWidth, doorHeight);
    final light = Paint()..color = const Color(0xFFFFF3D6);

    canvas.drawRect(doorRect.inflate(4), light);
    canvas.drawRect(doorRect, Paint()..color = const Color(0xFF5B3A1E));
    canvas.drawRect(
      Rect.fromLTWH(doorLeft + 8, doorTop + 6, doorWidth - 16, doorHeight - 14),
      Paint()..color = const Color(0xFF8C6239),
    );
    canvas.drawCircle(
      Offset(doorLeft + doorWidth - 16, doorTop + doorHeight / 2),
      4,
      light,
    );

    // Step and entrance marker on the street side of the door.
    final stepTop = onTop ? -24.0 : size.y + 6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (size.x - doorWidth - 40) / 2,
          stepTop,
          doorWidth + 40,
          14,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF9E9E9E),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 10, onTop ? -38 : size.y + 26, 20, 6),
      light,
    );

    drawCenteredLabel(
      canvas,
      Vector2(size.x, size.y * 0.6),
      location.name,
      color: Colors.white,
      fontSize: 28,
      shadow: true,
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
  bool get isSeat => false;
  @override
  Vector2 get interactPosition => position;

  /// Body contact: the marker's own 56px circle.
  @override
  Rect get touchRect => Rect.fromCenter(
    center: Offset(position.x, position.y),
    width: 72,
    height: 72,
  );

  NpcMarker({required this.npcId, required this.npcName, required Vector2 at})
    : super(
        position: at,
        size: Vector2(56, 56),
        anchor: Anchor.center,
        priority: 60,
      );

  /// Initial letter never changes: lay out once instead of every frame.
  late final TextPainter _initialPainter = TextPainter(
    text: TextSpan(
      text: npcName.isEmpty ? '?' : npcName[0],
      style: const TextStyle(color: Colors.white, fontSize: 24),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF4A86E8);
    canvas.drawCircle(const Offset(28, 28), 26, paint);
    final tp = _initialPainter;
    tp.paint(canvas, Offset(28 - tp.width / 2, 28 - tp.height / 2));
  }

  @override
  Future<void> onInteract(LifeInteractContext ctx) async {
    ctx.talkTo(npcId);
  }
}
