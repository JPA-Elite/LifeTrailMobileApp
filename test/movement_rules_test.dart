import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/life_game.dart';
import 'package:lifetrail/game/state/game_state.dart';
import 'package:lifetrail/game/world/town_world.dart';
import 'package:lifetrail/game/world/vehicle.dart';
import 'package:lifetrail/models/game_time.dart';
import 'package:lifetrail/models/player_model.dart';

const double _screenWidth = 800;
const double _screenHeight = 360;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('vehicles only count as crash hazards while they are moving', () {
    final town = TownWorld(onNearestChanged: (_) {});
    final car = VehicleComponent(
      host: town,
      kind: VehicleKind.car,
      highwayTop: 430,
      junction: 0,
      dir: 1,
      spawn: Vector2(500, 470),
      cruiseSpeed: 0,
      color: Colors.red,
    );
    town.vehicles.add(car);
    final feet = Rect.fromCenter(
      center: const Offset(500, 470),
      width: 36,
      height: 38,
    );

    car.speed = 120;
    expect(town.movingVehicleOverlapping(feet), same(car));

    car.speed = 0;
    expect(town.movingVehicleOverlapping(feet), isNull);
  });

  test('energy and health changes clamp at zero and full', () {
    final state = GameState();
    state.player = const PlayerModel(energy: 1, health: 1);

    state.changeEnergy(-5);
    state.changeHealth(-1);
    expect(state.player.energy, 0);
    expect(state.player.health, 0);

    state.player = const PlayerModel(energy: 99, health: 99);
    state.changeEnergy(5);
    state.changeHealth(5);
    expect(state.player.energy, PlayerModel.energyMax);
    expect(state.player.health, PlayerModel.healthMax);
  });

  test('reset clears the loaded session', () {
    final state = GameState()
      ..loadSnapshot(
        player: const PlayerModel(money: 9999),
        time: GameTime.morning(4),
        npcs: const {},
        quests: const {},
        flags: const {'seen': 1},
        inventory: const [],
        chapter: 3,
      );
    expect(state.isLoaded, isTrue);

    state.reset();

    expect(state.isLoaded, isFalse);
    expect(state.player.money, 500);
    expect(state.time.day, 1);
    expect(state.flags, isEmpty);
    expect(state.chapter, 1);
  });

  testWidgets('walking and running drain energy at the right cadence', (
    tester,
  ) async {
    final points = <int>[];
    final game = await _readyGame(tester, onExertion: points.add);
    final hero = game.player!;

    hero.running = false;
    hero.moveInput = Vector2(1, 0);
    // 61 seconds of walking at the clamped 50 ms tick.
    for (var i = 0; i < 1220; i++) {
      game.update(0.05);
    }
    expect(points, [1], reason: 'one point per 60 seconds of walking');

    points.clear();
    hero.running = true;
    // 31 seconds of running.
    for (var i = 0; i < 620; i++) {
      game.update(0.05);
    }
    expect(points, [1], reason: 'one point per 30 seconds of running');
  });

  testWidgets('a stopped vehicle blocks the player instead of being walked '
      'through', (tester) async {
    final game = await _readyGame(tester);
    final town = game.town!;
    for (final vehicle in town.vehicles) {
      vehicle.speed = 0;
      vehicle.position = Vector2(-5000, -5000);
    }
    // Red for junction 0 keeps the chosen car parked at its stop line, so it
    // is a genuine stopped obstacle rather than a slow-moving one.
    town.traffic.t = 9.0;
    final car = town.vehicles.first
      ..position = Vector2(2650, 470)
      ..speed = 0;

    final hero = game.player!;
    hero.position = Vector2(2550, 470);
    hero.previousPosition.setFrom(hero.position);
    hero.moveInput = Vector2(1, 0);
    hero.running = false;

    for (var i = 0; i < 90; i++) {
      game.update(1 / 60);
    }

    expect(hero.feetRect.overlaps(car.toRect()), isFalse);
    expect(
      hero.position.x,
      lessThan(car.toRect().left),
      reason: 'the player never passes the car body',
    );
  });

  testWidgets('a moving vehicle hurts once, then respects the cooldown', (
    tester,
  ) async {
    final crashes = <VehicleKind>[];
    final game = await _readyGame(tester, onVehicleCrash: crashes.add);
    final town = game.town!;
    for (final vehicle in town.vehicles) {
      vehicle.speed = 0;
      vehicle.position = Vector2(-5000, -5000);
    }
    town.vehicles.first
      ..position = Vector2(1500, 470)
      ..speed = 120;

    final hero = game.player!;
    hero.position = Vector2(1500, 470);
    hero.previousPosition.setFrom(hero.position);
    hero.moveInput = Vector2.zero();

    game.update(1 / 60);
    expect(crashes, [VehicleKind.car]);

    game.update(1 / 60);
    expect(crashes, [VehicleKind.car], reason: 'two-second crash cooldown');
  });
}

Future<LifeGame> _readyGame(
  WidgetTester tester, {
  void Function(int points)? onExertion,
  void Function(VehicleKind kind)? onVehicleCrash,
}) async {
  tester.view.physicalSize = const Size(_screenWidth * 3, _screenHeight * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final game = LifeGame(
    onNearestChanged: (_) {},
    onEnterLocation: (_) {},
    onOpenLocationMenu: (_) {},
    onLeftLocation: (_) {},
    onTalkTo: (_) {},
    onMessage: (_) {},
    onExertion: onExertion,
    onVehicleCrash: onVehicleCrash,
    random: Random(7),
  );
  await tester.pumpWidget(GameWidget(game: game));
  for (var i = 0; i < 80 && !game.isReady; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(game.isReady, isTrue);
  // Stop the joystick from overwriting the scripted movement input. The
  // component itself is harmless without a touch stream.
  game.joystick = null;
  return game;
}
