import 'dart:ui' show Rect;

import '../../models/location_dialogue.dart';

const double kWorldWidth = 3200;
const double kWorldHeight = 1800;

// --- Highways -------------------------------------------------------------

/// Main east-west highway: two lanes each way.
const double kHighwayTop = 800;
const double kHighwayHeight = 220;
const double kHighwayBottom = kHighwayTop + kHighwayHeight;

/// Sidewalks hugging the highway on both sides.
const double kSidewalkHeight = 46;
const double kSidewalkNorthTop = kHighwayTop - kSidewalkHeight;
const double kSidewalkSouthBottom = kHighwayBottom + kSidewalkHeight;

/// North-south street crossing the highway (a T with a full crossroad).
const double kCrossStreetLeft = 2080;
const double kCrossStreetWidth = 200;
const double kCrossStreetRight = kCrossStreetLeft + kCrossStreetWidth;

/// Vertical band of the highway's shoulder on the outside of each sidewalk.
const double kNorthSidewalk = kSidewalkNorthTop;
const double kSouthSidewalk = kSidewalkSouthBottom;

// --- Streets --------------------------------------------------------------

class TownStrip {
  final double x;
  final double y;
  final double w;
  final double h;
  final int color;

  const TownStrip({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.color,
  });
}

/// Asphalt + sidewalks, drawn under everything else.
List<TownStrip> buildTownRoads() => [
  // Highway asphalt.
  const TownStrip(
    x: 0,
    y: kHighwayTop,
    w: kWorldWidth,
    h: kHighwayHeight,
    color: 0xFF4A4A4A,
  ),
  // Sidewalks on both shoulders.
  const TownStrip(
    x: 0,
    y: kSidewalkNorthTop,
    w: kWorldWidth,
    h: kSidewalkHeight,
    color: 0xFFC9C4B8,
  ),
  const TownStrip(
    x: 0,
    y: kHighwayBottom,
    w: kWorldWidth,
    h: kSidewalkHeight,
    color: 0xFFC9C4B8,
  ),
  // North-south street, asphalt only outside the highway band.
  const TownStrip(
    x: kCrossStreetLeft,
    y: 0,
    w: kCrossStreetWidth,
    h: kHighwayTop,
    color: 0xFF555555,
  ),
  const TownStrip(
    x: kCrossStreetLeft,
    y: kHighwayBottom,
    w: kCrossStreetWidth,
    h: kWorldHeight - kHighwayBottom,
    color: 0xFF555555,
  ),
];

// --- Buildings ------------------------------------------------------------

/// Buildings sit clear of the highway: north-side ones face south, south-side
/// ones face north, and every door opens onto a sidewalk.
List<LocationModel> buildTownLocations() => [
  const LocationModel(
    id: 'school',
    name: 'School',
    x: 1380,
    y: 430,
    w: 440,
    h: 280,
    color: 0xFF6FA8DC,
  ),
  const LocationModel(
    id: 'church',
    name: 'Church',
    x: 220,
    y: 440,
    w: 380,
    h: 260,
    color: 0xFFD9D2E9,
  ),
  const LocationModel(
    id: 'park',
    name: 'Park',
    x: 2400,
    y: 430,
    w: 420,
    h: 300,
    color: 0xFF6AA84F,
  ),
  const LocationModel(
    id: 'home',
    name: 'Home',
    x: 640,
    y: 1180,
    w: 440,
    h: 280,
    color: 0xFFE6B8AF,
    doorSide: 'top',
  ),
  const LocationModel(
    id: 'plaza',
    name: 'Plaza',
    x: 1420,
    y: 1140,
    w: 460,
    h: 320,
    color: 0xFF93C47D,
    doorSide: 'top',
  ),
  const LocationModel(
    id: 'workplace',
    name: 'Café',
    x: 2540,
    y: 1200,
    w: 420,
    h: 260,
    color: 0xFFFFD966,
    doorSide: 'top',
  ),
];

// --- Street dressing ------------------------------------------------------

class TownDecoration {
  final String kind;
  final double x;
  final double y;
  final double size;

  const TownDecoration(this.kind, this.x, this.y, this.size);

  /// Trees, benches, lamps and hydrants are physical obstacles; bushes and
  /// flower beds are purely decorative.
  bool get solid => kind != 'bush' && kind != 'flowers';
}

/// Spaced along both shoulders: street trees, benches, lamps and hedges.
/// Decoration x/y is the point where it meets the ground, and anything too
/// close to a doorway is skipped so entrances stay walkable.
List<TownDecoration> buildTownDecorations() {
  final out = <TownDecoration>[];
  final doors = buildTownLocations().map((l) => l.x + l.w / 2).toList();

  bool clearOfDoors(double x, {double margin = 170}) =>
      doors.every((dx) => (dx - x).abs() > margin);

  // Street trees on the verges either side of the highway.
  for (var x = 240.0; x < kWorldWidth - 140; x += 280) {
    if (x > kCrossStreetLeft - 140 && x < kCrossStreetRight + 140) continue;
    if (clearOfDoors(x)) {
      out.add(TownDecoration('tree', x, kSidewalkNorthTop - 12, 132));
      out.add(TownDecoration('tree', x + 150, kSidewalkSouthBottom + 12, 132));
    }
  }

  // Benches and lamps along the sidewalks, clear of the doorways so no
  // entrance is blocked.
  for (var x = 420.0; x < kWorldWidth - 220; x += 420) {
    if (x > kCrossStreetLeft - 180 && x < kCrossStreetRight + 180) continue;
    if (clearOfDoors(x, margin: 130)) {
      out.add(TownDecoration('bench', x, kSidewalkNorthTop + 24, 84));
    }
    if (clearOfDoors(x + 210, margin: 130)) {
      out.add(TownDecoration('bench', x + 210, kHighwayBottom + 26, 84));
    }
  }
  for (var x = 300.0; x < kWorldWidth - 100; x += 340) {
    if (clearOfDoors(x, margin: 100)) {
      out.add(TownDecoration('lamp', x, kSidewalkNorthTop + 8, 60));
    }
    if (clearOfDoors(x + 170, margin: 100)) {
      out.add(TownDecoration('lamp', x + 170, kHighwayBottom + 40, 60));
    }
  }

  // Hedges and flower beds in the grass, clear of the doorways.
  for (var x = 160.0; x < kWorldWidth - 260; x += 360) {
    if (clearOfDoors(x, margin: 210)) {
      out.add(TownDecoration('bush', x, kSidewalkNorthTop - 60, 96));
      out.add(
        TownDecoration('flowers', x + 180, kSidewalkSouthBottom + 96, 70),
      );
    }
  }
  out.add(const TownDecoration('hydrant', 1180, kSidewalkSouthBottom + 20, 44));
  out.add(const TownDecoration('hydrant', 2860, kSidewalkNorthTop + 20, 44));

  return out;
}

/// Where the wanderers of the town are allowed to roam: the two sidewalks
/// either side of the highway plus the cross-street pavement.
List<Rect> buildPedestrianBands() => [
  const Rect.fromLTRB(140, 758, 3060, 796),
  const Rect.fromLTRB(140, 1024, 3060, 1062),
  const Rect.fromLTRB(kCrossStreetLeft + 30, 240, kCrossStreetRight - 30, 760),
  const Rect.fromLTRB(
    kCrossStreetLeft + 30,
    1060,
    kCrossStreetRight - 30,
    1500,
  ),
];
