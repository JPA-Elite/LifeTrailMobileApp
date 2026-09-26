import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/world/map_data.dart';
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
}
