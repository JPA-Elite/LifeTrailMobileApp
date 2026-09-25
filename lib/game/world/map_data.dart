import 'dart:ui' show Rect;

import '../../models/location_dialogue.dart';

const double kWorldWidth = 3900;
const double kWorldHeight = 2900;

// --- Highways -------------------------------------------------------------

/// Five parallel town bands, each split by its own east-west highway.
const double kHighwayHeight = 160;
const double kSidewalkHeight = 46;
const List<double> kHighwayTops = [430, 990, 1590, 2190];

/// Bottom edge of the highway starting at [top].
double highwayBottom(double top) => top + kHighwayHeight;

/// True when the vertical span [top, bottom] touches any highway asphalt.
bool overlapsHighway(double top, double bottom) =>
    kHighwayTops.any((t) => top < t + kHighwayHeight && bottom > t);

/// North-south street crossing every highway.
const double kCrossStreetLeft = 2780;
const double kCrossStreetWidth = 200;
const double kCrossStreetRight = kCrossStreetLeft + kCrossStreetWidth;

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

/// Asphalt + sidewalks, drawn under everything else. The cross street is
/// drawn first so every highway stays continuous over the junctions.
List<TownStrip> buildTownRoads() => [
  const TownStrip(
    x: kCrossStreetLeft,
    y: 0,
    w: kCrossStreetWidth,
    h: kWorldHeight,
    color: 0xFF555555,
  ),
  for (final top in kHighwayTops) ...[
    TownStrip(
      x: 0,
      y: top,
      w: kWorldWidth,
      h: kHighwayHeight,
      color: 0xFF4A4A4A,
    ),
    TownStrip(
      x: 0,
      y: top - kSidewalkHeight,
      w: kWorldWidth,
      h: kSidewalkHeight,
      color: 0xFFC9C4B8,
    ),
    TownStrip(
      x: 0,
      y: top + kHighwayHeight,
      w: kWorldWidth,
      h: kSidewalkHeight,
      color: 0xFFC9C4B8,
    ),
  ],
];

// --- Buildings ------------------------------------------------------------

/// Buildings sit clear of the roads: north-side ones face south, south-side
/// ones face north, and every door opens onto a street or sidewalk.
List<LocationModel> buildTownLocations() => [
  // --- Band 1: northern shops (doors face south) ---
  const LocationModel(
    id: 'repair',
    name: 'Repair Shop',
    x: 60,
    y: 90,
    w: 440,
    h: 280,
    color: 0xFF8E9E9E,
  ),
  const LocationModel(
    id: 'bookstore',
    name: 'Book Store',
    x: 1050,
    y: 90,
    w: 440,
    h: 280,
    color: 0xFFB45F06,
  ),
  const LocationModel(
    id: 'supermarket',
    name: 'Super Market',
    x: 1900,
    y: 90,
    w: 560,
    h: 280,
    color: 0xFF6AA84F,
  ),
  const LocationModel(
    id: 'pizzahut',
    name: 'Pizza Hut',
    x: 3020,
    y: 90,
    w: 480,
    h: 280,
    color: 0xFFE06666,
  ),
  // --- Band 2: hospital row (doors face south) ---
  const LocationModel(
    id: 'hospital',
    name: 'Hospital',
    x: 60,
    y: 650,
    w: 440,
    h: 280,
    color: 0xFFF1F1F1,
  ),
  const LocationModel(
    id: 'restaurant',
    name: 'Restaurant',
    x: 60,
    y: 1210,
    w: 440,
    h: 240,
    color: 0xFFE69138,
  ),
  const LocationModel(
    id: 'laundry',
    name: 'Laundry Shop',
    x: 60,
    y: 1810,
    w: 440,
    h: 280,
    color: 0xFF6FA8DC,
  ),
  // --- Band 3: home row (doors face south) ---
  const LocationModel(
    id: 'school',
    name: 'School',
    x: 2080,
    y: 650,
    w: 440,
    h: 280,
    color: 0xFF6FA8DC,
  ),
  const LocationModel(
    id: 'church',
    name: 'Church',
    x: 920,
    y: 650,
    w: 380,
    h: 260,
    color: 0xFFD9D2E9,
  ),
  const LocationModel(
    id: 'park',
    name: 'Park',
    x: 3100,
    y: 650,
    w: 420,
    h: 300,
    color: 0xFF6AA84F,
  ),
  // --- Band 4: bank row (doors face south) ---
  const LocationModel(
    id: 'home',
    name: 'Home',
    x: 1340,
    y: 1210,
    w: 440,
    h: 280,
    color: 0xFFE6B8AF,
    doorSide: 'top',
  ),
  const LocationModel(
    id: 'plaza',
    name: 'Plaza',
    x: 2120,
    y: 1210,
    w: 460,
    h: 320,
    color: 0xFF93C47D,
    doorSide: 'top',
  ),
  const LocationModel(
    id: 'workplace',
    name: 'Café',
    x: 3220,
    y: 1210,
    w: 600,
    h: 320,
    color: 0xFFFFD966,
    doorSide: 'top',
  ),
  // --- Band 4: bank row (doors face south), police included ---
  const LocationModel(
    id: 'bank',
    name: 'Bank',
    x: 780,
    y: 1810,
    w: 460,
    h: 300,
    color: 0xFFB7C9E2,
  ),
  const LocationModel(
    id: 'mall',
    name: 'Mall',
    x: 3020,
    y: 1810,
    w: 560,
    h: 320,
    color: 0xFFD5A6BD,
  ),
  const LocationModel(
    id: 'police',
    name: 'Police Station',
    x: 2120,
    y: 1810,
    w: 460,
    h: 280,
    color: 0xFF4A86E8,
  ),
  // --- Band 5: southern row (doors face north) ---
  const LocationModel(
    id: 'computer',
    name: 'Computer Center',
    x: 120,
    y: 2410,
    w: 440,
    h: 300,
    color: 0xFF8E7CC3,
    doorSide: 'top',
  ),
  const LocationModel(
    id: 'amusement',
    name: 'Amusement Park',
    x: 700,
    y: 2410,
    w: 560,
    h: 300,
    color: 0xFFFFD966,
    doorSide: 'top',
  ),
  const LocationModel(
    id: 'beach',
    name: 'Beach',
    x: 1400,
    y: 2410,
    w: 480,
    h: 300,
    color: 0xFF4DD0E1,
    doorSide: 'top',
  ),
  const LocationModel(
    id: 'fishing',
    name: 'Fishing Area',
    x: 2020,
    y: 2410,
    w: 480,
    h: 300,
    color: 0xFF6D9EEB,
    doorSide: 'top',
  ),
  const LocationModel(
    id: 'hotel',
    name: 'Hotel',
    x: 3020,
    y: 2410,
    w: 560,
    h: 300,
    color: 0xFFB39DDB,
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

/// Spaced along every highway's shoulders: street trees, benches, lamps
/// and hedges. Decoration x/y is the point where it meets the ground, and
/// anything too close to a doorway is skipped so entrances stay walkable.
List<TownDecoration> buildTownDecorations() {
  final out = <TownDecoration>[];
  final doors = buildTownLocations().map((l) => l.x + l.w / 2).toList();

  bool clearOfDoors(double x, {double margin = 170}) =>
      doors.every((dx) => (dx - x).abs() > margin);

  for (final top in kHighwayTops) {
    final bottom = top + kHighwayHeight;
    // Street trees on the verges either side of the highway.
    for (var x = 240.0; x < kWorldWidth - 140; x += 280) {
      if (x > kCrossStreetLeft - 140 && x < kCrossStreetRight + 140) continue;
      if (clearOfDoors(x)) {
        out.add(TownDecoration('tree', x, top - kSidewalkHeight - 12, 132));
        out.add(TownDecoration('tree', x + 150, bottom + kSidewalkHeight + 12, 132));
      }
    }

    // Benches and lamps along the sidewalks, clear of the doorways so no
    // entrance is blocked.
    for (var x = 420.0; x < kWorldWidth - 220; x += 420) {
      if (x > kCrossStreetLeft - 180 && x < kCrossStreetRight + 180) continue;
      if (clearOfDoors(x, margin: 130)) {
        out.add(TownDecoration('bench', x, top - kSidewalkHeight + 24, 84));
      }
      if (clearOfDoors(x + 210, margin: 130)) {
        out.add(TownDecoration('bench', x + 210, bottom + 26, 84));
      }
    }
    for (var x = 300.0; x < kWorldWidth - 100; x += 340) {
      if (clearOfDoors(x, margin: 100)) {
        out.add(TownDecoration('lamp', x, top - kSidewalkHeight + 8, 60));
      }
      if (clearOfDoors(x + 170, margin: 100)) {
        out.add(TownDecoration('lamp', x + 170, bottom + 40, 60));
      }
    }

    // Hedges and flower beds in the grass, clear of the doorways.
    for (var x = 160.0; x < kWorldWidth - 260; x += 360) {
      if (clearOfDoors(x, margin: 210)) {
        out.add(TownDecoration('bush', x, top - kSidewalkHeight - 60, 96));
        out.add(
          TownDecoration('flowers', x + 180, bottom + kSidewalkHeight + 96, 70),
        );
      }
    }
  }
  out.add(const TownDecoration('hydrant', 700, 1216, 44));
  out.add(const TownDecoration('hydrant', 3300, 1564, 44));

  return out;
}

/// Where the wanderers of the town are allowed to roam: the sidewalks of
/// every highway plus the cross-street pavement between them.
List<Rect> buildPedestrianBands() => [
  for (final top in kHighwayTops) ...[
    Rect.fromLTRB(140, top - 42, 3760, top - 4),
    Rect.fromLTRB(
      140,
      top + kHighwayHeight + 4,
      3760,
      top + kHighwayHeight + 42,
    ),
  ],
  const Rect.fromLTRB(2810, 60, 2950, 400),
  const Rect.fromLTRB(2810, 640, 2950, 960),
  const Rect.fromLTRB(2810, 1210, 2950, 1560),
  const Rect.fromLTRB(2810, 1810, 2950, 2160),
  const Rect.fromLTRB(2810, 2410, 2950, 2840),
];
