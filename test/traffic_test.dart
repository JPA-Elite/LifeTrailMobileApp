import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/life_game.dart';
import 'package:lifetrail/game/world/map_data.dart';
import 'package:lifetrail/game/world/town_world.dart';
import 'package:lifetrail/game/world/vehicle.dart';

class _FakeHost implements TrafficHost {
  LightPhase phase = LightPhase.green;
  bool blocked = false;
  double? pedDist;
  final List<VehicleComponent> lane = [];

  @override
  LightPhase phaseAtJunction(int index) => phase;

  @override
  bool crossingBlocked(int index) => blocked;

  @override
  double? pedestrianAhead(VehicleComponent self) => pedDist;

  @override
  double? gapAhead(VehicleComponent self) {
    double? best;
    for (final v in lane) {
      if (identical(v, self)) continue;
      final gap = (v.position.x - self.position.x) * self.dir -
          v.halfLen -
          self.halfLen;
      if (gap > -10 && (best == null || gap < best)) best = gap;
    }
    return best;
  }

  @override
  double? speedAhead(VehicleComponent self) {
    VehicleComponent? best;
    var bestDist = double.infinity;
    for (final v in lane) {
      if (identical(v, self)) continue;
      final d = (v.position.x - self.position.x) * self.dir;
      if (d > -10 && d < bestDist) {
        bestDist = d;
        best = v;
      }
    }
    return best?.speed;
  }
}

CrossStreetVehicle _verticalCar(
  _FakeHost host, {
  double y = 300,
  int dir = 1,
  bool Function(int junction)? blocked,
  double? Function(CrossStreetVehicle self)? playerAhead,
}) {
  return CrossStreetVehicle(
    host: host,
    kind: VehicleKind.car,
    streetLeft: kWestStreetLeft,
    dir: dir,
    spawn: Vector2(crossLaneCenterX(kWestStreetLeft, dir), y),
    cruiseSpeed: 200,
    color: Colors.blue,
    junctionBlocked: blocked,
    playerAhead: playerAhead,
  );
}

VehicleComponent _eastboundCar(_FakeHost host, double x) {
  return VehicleComponent(
    host: host,
    kind: VehicleKind.car,
    highwayTop: kHighwayTops[0],
    junction: 0,
    dir: 1,
    spawn: Vector2(x, laneCenterY(kHighwayTops[0], 1)),
    cruiseSpeed: 300,
    color: Colors.red,
  );
}

void _step(VehicleComponent v, int frames) {
  for (var i = 0; i < frames; i++) {
    v.update(1 / 60);
  }
}

void main() {
  test('signals cycle green -> yellow -> red with stagger', () {
    final sys = TrafficSystem();
    expect(sys.phaseAt(0), LightPhase.green);
    sys.update(7.5);
    expect(sys.phaseAt(0), LightPhase.yellow);
    sys.update(2.0);
    expect(sys.phaseAt(0), LightPhase.red);
    // Junction 1 is offset by 3s: green while junction 0 is red.
    final sys2 = TrafficSystem()..update(10.0);
    expect(sys2.phaseAt(0), LightPhase.red);
    expect(sys2.phaseAt(1), LightPhase.green);
  });

  test('car halts behind stop line on red, rolls on green', () {
    final host = _FakeHost()..phase = LightPhase.red;
    final car = _eastboundCar(host, stopLineX(1) - 200);
    _step(car, 600);
    expect(car.speed, 0);
    expect(
      car.position.x + car.halfLen,
      lessThanOrEqualTo(stopLineX(1) - 4 + 1),
    );

    host.phase = LightPhase.green;
    _step(car, 120);
    expect(car.speed, greaterThan(100));
    expect(car.position.x + car.halfLen, greaterThan(stopLineX(1)));
  });

  test('car yields to player on crosswalk even on green', () {
    final host = _FakeHost()
      ..phase = LightPhase.green
      ..blocked = true;
    final car = _eastboundCar(host, stopLineX(1) - 200);
    _step(car, 600);
    expect(car.speed, 0);
    expect(
      car.position.x + car.halfLen,
      lessThanOrEqualTo(stopLineX(1) - 4 + 1),
    );
  });

  test('car halts for a pedestrian in its lane, rolls when clear', () {
    final host = _FakeHost()
      ..phase = LightPhase.green
      ..pedDist = 150;
    final car = _eastboundCar(host, 500);
    final startX = car.position.x;
    _step(car, 300);
    expect(car.speed, 0);
    // Stopped ~24px before the person, never reached them.
    final front = car.position.x + car.halfLen;
    expect(front, lessThanOrEqualTo(startX + car.halfLen + 150 - 24 + 1));
    expect(front, lessThan(startX + car.halfLen + 150));
    host.pedDist = null;
    _step(car, 120);
    expect(car.speed, greaterThan(100));
  });

  test('fast follower never overlaps a slow leader', () {
    final host = _FakeHost()..phase = LightPhase.green;
    final leader = VehicleComponent(
      host: host,
      kind: VehicleKind.car,
      highwayTop: kHighwayTops[0],
      junction: 0,
      dir: 1,
      spawn: Vector2(1500, laneCenterY(kHighwayTops[0], 1)),
      cruiseSpeed: 120,
      color: Colors.blue,
    );
    final follower = VehicleComponent(
      host: host,
      kind: VehicleKind.car,
      highwayTop: kHighwayTops[0],
      junction: 0,
      dir: 1,
      spawn: Vector2(900, laneCenterY(kHighwayTops[0], 1)),
      cruiseSpeed: 330,
      color: Colors.red,
    );
    host.lane.addAll([leader, follower]);
    for (var i = 0; i < 1200; i++) {
      leader.update(1 / 60);
      follower.update(1 / 60);
      final gap = leader.position.x -
          follower.position.x -
          leader.halfLen -
          follower.halfLen;
      expect(gap, greaterThanOrEqualTo(-1));
    }
    // Settled into a queue behind the leader, not inside it.
    expect(follower.speed, lessThanOrEqualTo(leader.speed + 1));
  });

  test('both north-south streets are paved with walkable pavement', () {
    final roads = buildTownRoads();
    final bands = buildPedestrianBands();
    for (final left in kVerticalStreetLefts) {
      expect(
        roads.any(
          (s) =>
              s.x == left &&
              s.w == kCrossStreetWidth &&
              s.h == kWorldHeight,
        ),
        isTrue,
        reason: 'missing asphalt for the street at x=$left',
      );
      expect(
        roads.any(
          (s) =>
              s.x == left + kCrossStreetWidth &&
              s.w == kVerticalSidewalkWidth,
        ),
        isTrue,
        reason: 'missing pavement for the street at x=$left',
      );
      expect(
        bands.any(
          (b) =>
              b.left >= left + kCrossStreetWidth &&
              b.right <= left + kCrossStreetWidth + kVerticalSidewalkWidth,
        ),
        isTrue,
        reason: 'nobody can walk the street at x=$left',
      );
    }
  });

  test('street props stay off both north-south streets', () {
    for (final decoration in buildTownDecorations()) {
      if (!decoration.solid) continue;
      final prop = StreetProp(decoration: decoration);
      for (final left in kVerticalStreetLefts) {
        final corridor = Rect.fromLTRB(
          left - kVerticalSidewalkWidth,
          0,
          left + kCrossStreetWidth + kVerticalSidewalkWidth,
          kWorldHeight,
        );
        expect(
          prop.toRect().overlaps(corridor),
          isFalse,
          reason:
              '${decoration.kind} at (${decoration.x}, ${decoration.y}) '
              'blocks the street at x=$left',
        );
      }
    }
  });

  test('no building overlaps either north-south street', () {
    for (final lot in buildTownLocations()) {
      final body = Rect.fromLTWH(lot.x, lot.y, lot.w, lot.h);
      for (final left in kVerticalStreetLefts) {
        final corridor = Rect.fromLTRB(
          left - kVerticalSidewalkWidth,
          0,
          left + kCrossStreetWidth + kVerticalSidewalkWidth,
          kWorldHeight,
        );
        expect(
          body.overlaps(corridor),
          isFalse,
          reason: '${lot.id} overlaps the street at x=$left',
        );
      }
    }
  });

  test('vertical traffic drives both ways in its own lane', () {
    final host = _FakeHost();
    for (final left in kVerticalStreetLefts) {
      for (final dir in const [1, -1]) {
        final x = crossLaneCenterX(left, dir);
        expect(x, greaterThan(left));
        expect(x, lessThan(left + kCrossStreetWidth));
      }
    }

    final south = _verticalCar(host, y: 300);
    _step(south, 60);
    expect(south.position.y, greaterThan(300));
    expect(south.position.x, crossLaneCenterX(kWestStreetLeft, 1));

    final north = _verticalCar(host, y: 1500, dir: -1);
    _step(north, 60);
    expect(north.position.y, lessThan(1500));

    // Drawing a vertical vehicle must not throw (rotated car art).
    for (final vehicle in [south, north]) {
      final recorder = PictureRecorder();
      vehicle.renderTree(Canvas(recorder));
      recorder.endRecording();
    }
  });

  test('vertical traffic waits at a busy junction, then rolls', () {
    final host = _FakeHost();
    var busy = true;
    final car = _verticalCar(host, y: 800, blocked: (_) => busy);
    _step(car, 600);
    expect(car.speed, 0);
    // Holds behind the line before the second highway (top = 990).
    expect(
      car.position.y + car.halfLen,
      lessThanOrEqualTo(kHighwayTops[1] - 46 - 6 + 1),
    );

    busy = false;
    _step(car, 240);
    expect(car.position.y + car.halfLen, greaterThan(kHighwayTops[1] - 46));
  });

  test('vertical traffic yields to the player in its lane', () {
    final host = _FakeHost();
    double? person = 120;
    final car = _verticalCar(host, y: 500, playerAhead: (_) => person);
    _step(car, 300);
    expect(car.speed, 0);
    person = null;
    _step(car, 120);
    expect(car.speed, greaterThan(100));
  });

  testWidgets('town spawns sparse traffic on both north-south streets', (
    tester,
  ) async {
    final game = LifeGame(
      onNearestChanged: (_) {},
      onEnterLocation: (_) {},
      onOpenLocationMenu: (_) {},
      onLeftLocation: (_) {},
      onTalkTo: (_) {},
      onMessage: (_) {},
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: GameWidget(game: game))),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final town = game.town!;
    expect(town.crossVehicles, hasLength(4));
    // Side streets stay much quieter than the highways.
    expect(town.crossVehicles.length, lessThan(town.vehicles.length));
    expect(
      town.crossVehicles.map((v) => v.streetLeft).toSet(),
      kVerticalStreetLefts.toSet(),
    );
    for (final vehicle in town.crossVehicles) {
      final left = vehicle.streetLeft;
      expect(vehicle.position.x, greaterThan(left));
      expect(vehicle.position.x, lessThan(left + kCrossStreetWidth));
    }
  });
}
