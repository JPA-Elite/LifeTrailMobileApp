import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/life_game.dart';
import 'package:lifetrail/game/player/player_component.dart';
import 'package:lifetrail/game/world/feet_collision.dart';
import 'package:lifetrail/game/world/interactable.dart';
import 'package:lifetrail/game/world/interior_data.dart';
import 'package:lifetrail/game/world/map_data.dart';
import 'package:lifetrail/game/world/mini_map_scene.dart';
import 'package:lifetrail/game/world/interior_world.dart';
import 'package:lifetrail/game/world/town_world.dart';
import 'package:lifetrail/widgets/mini_map.dart';

const enterableLocations = [
  'home',
  'school',
  'plaza',
  'church',
  'park',
  'workplace',
];

void main() {
  group('town doors', () {
    test('every building has a door on the street side to enter through', () {
      final town = TownWorld(onNearestChanged: (_) {});
      expect(town.buildings, isNotEmpty);

      for (final building in town.buildings) {
        final door = building.doorPosition;
        final onTop = building.location.doorOnTop;
        // Door sits on the wall facing the street, horizontally centered.
        expect(
          door.y,
          closeTo(
            onTop ? building.position.y : building.position.y + building.size.y,
            0.001,
          ),
        );
        expect(
          door.x,
          closeTo(building.position.x + building.size.x / 2, 0.001),
        );
        // The door - not the building centre - is the interaction anchor.
        expect(building.interactPosition, door);

        // Leaving the building drops the player just outside that door,
        // within reach of it.
        final spawn = town.doorSpawn(building.location.id);
        expect(spawn.x, closeTo(door.x, 0.001));
        if (onTop) {
          expect(spawn.y, lessThan(door.y));
        } else {
          expect(spawn.y, greaterThan(door.y));
        }
        expect(spawn.distanceTo(door), lessThan(150));
      }
    });

    test('no doorway is blocked by a building, tree, bench or lamp', () {
      final town = TownWorld(onNearestChanged: (_) {});
      const feet = FeetBody();
      for (final building in town.buildings) {
        final spawn = town.doorSpawn(building.location.id);
        final rect = feet.rectAt(spawn);
        for (final solid in town.solidBounds()) {
          expect(
            rect.overlaps(solid.toRect()),
            isFalse,
            reason:
                '${building.location.id} spawn is blocked by '
                '${solid.runtimeType}',
          );
        }
      }
    });

    test('the highway keeps buildings off the road', () {
      for (final l in buildTownLocations()) {
        final bottom = l.y + l.h;
        final top = l.y;
        final clearOfHighway = bottom <= kHighwayTop || top >= kHighwayBottom;
        expect(
          clearOfHighway,
          isTrue,
          reason: '${l.id} overlaps the highway asphalt',
        );
      }
    });
  });

  group('collision (no shaking on contact)', () {
    final wall = RectangleComponent(
      position: Vector2(100, 0),
      size: Vector2(200, 200),
    );

    test('walking into a wall settles instead of oscillating', () {
      final position = Vector2(80, 190);
      final seen = <double>{};

      for (var frame = 0; frame < 40; frame++) {
        final previous = position.clone();
        position.x += 8; // walk right, straight into the wall
        resolveFeetCollision(
          position: position,
          previous: previous,
          solids: [wall],
        );
        seen.add(double.parse(position.x.toStringAsFixed(2)));
      }

      expect(seen.length, 1, reason: 'x should settle on one value, saw $seen');
      expect(position.x, lessThan(wall.position.x));
    });

    test('pressing into a wall still lets the actor slide along it', () {
      final position = Vector2(80, 120);

      // Ten frames keeps the actor beside the wall (its base is at y 200).
      for (var frame = 0; frame < 10; frame++) {
        final previous = position.clone();
        position.x += 8; // into the wall
        position.y += 6; // and down along it
        resolveFeetCollision(
          position: position,
          previous: previous,
          solids: [wall],
        );
      }

      // Blocked horizontally the whole time, but free to keep moving down.
      expect(position.x, lessThan(wall.position.x));
      expect(position.y, greaterThan(170));
    });

    test('an actor spawned inside a solid is pushed out', () {
      final position = Vector2(150, 100);
      resolveFeetCollision(
        position: position,
        previous: position.clone(),
        solids: [wall],
      );
      final rect = const FeetBody().rectAt(position);
      expect(rect.overlaps(wall.toRect()), isFalse);
    });
  });

  group('interiors', () {
    test('every enterable location has its own room', () {
      final layouts = enterableLocations.map(buildInterior).toList();
      expect(layouts.map((l) => l.id).toSet(), enterableLocations.toSet());
      expect(layouts.map((l) => l.title).toSet().length, 6);
    });

    test('a room has walls, furniture and an exit doorway', () {
      for (final id in enterableLocations) {
        final layout = buildInterior(id);
        expect(layout.props, isNotEmpty, reason: '$id has no furniture');
        expect(
          layout.props.any((p) => p.opensMenu),
          isTrue,
          reason: '$id has no activity point to open its menu',
        );
        expect(layout.doorWidth, greaterThan(0));

        final room = InteriorWorld(layout: layout, onNearestChanged: (_) {});
        final size = room.worldSize;
        expect(size.x, greaterThan(0));
        expect(size.y, greaterThan(0));
        // You appear inside, standing in front of the exit door.
        expect(room.entrySpawn.y, lessThan(size.y));
        expect(room.doorPosition.y, greaterThan(room.entrySpawn.y));
      }
    });
  });

  group('scene swapping', () {
    testWidgets('player can walk into a building and back out', (tester) async {
      final entered = <String>[];
      final left = <String>[];
      final messages = <String>[];
      Interactable? nearest;
      final game = LifeGame(
        onNearestChanged: (value) => nearest = value,
        onEnterLocation: entered.add,
        onOpenLocationMenu: (_) {},
        onLeftLocation: left.add,
        onTalkTo: (_) {},
        onMessage: messages.add,
        // Seeded so the wandering townspeople are reproducible.
        random: Random(7),
      );

      await tester.pumpWidget(GameWidget(game: game));
      for (var i = 0; i < 30 && !game.isReady; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(game.isReady, isTrue);
      expect(game.isInsideBuilding, isFalse);
      expect(game.activeWorld, isA<TownWorld>());
      expect((game.activeWorld! as TownWorld).buildings, isNotEmpty);
      // Spawns in front of the home door, not inside the building.
      expect(
        game.player!.position.y,
        greaterThan(game.town!.doorSpawn('home').y - 1),
      );
      expect(
        game.player!.position.y,
        lessThan(game.town!.doorSpawn('home').y + 1),
      );
      for (final child in game.activeWorld!.children) {
        if (identical(child, game.player)) continue;
        expect(
          game.player!.priority,
          greaterThan(child.priority),
          reason: '${child.runtimeType} would draw over the player',
        );
      }

      // Standing in front of a door targets that door, not the building.
      final homeBuilding = game.town!.buildings.firstWhere(
        (b) => b.location.id == 'home',
      );
      expect(homeBuilding.interactLabel, 'Enter Home');
      game.player!.position = game.town!.doorSpawn('home');
      game.update(1 / 60);
      expect(nearest, isA<BuildingBlock>());
      expect(nearest!.interactLabel, 'Enter Home');

      // Entering through the door interaction puts us inside the room.
      await game.interactNearest();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.currentLocationId, 'home');
      final homeRoom = game.activeWorld! as InteriorWorld;
      expect(homeRoom.solidBounds(), isNotEmpty);
      // The room's floor, walls and props must not paint over the player.
      expect(game.player!.parent, same(homeRoom));
      expect(game.player!.isMounted, isTrue);
      for (final child in homeRoom.children) {
        if (identical(child, game.player)) continue;
        expect(
          game.player!.priority,
          greaterThan(child.priority),
          reason: '${child.runtimeType} would draw over the player',
        );
      }
      // The doorway is right there, so leaving is the available action.
      game.update(1 / 60);
      expect(nearest?.interactLabel, 'Leave Home');

      await game.enterLocation('church');
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.isInsideBuilding, isTrue);
      expect(game.currentLocationId, 'church');
      expect(entered, ['home', 'church']);
      // Player is standing inside the room, in front of the doorway.
      final room = game.activeWorld! as InteriorWorld;
      expect(game.player!.position.y, lessThan(room.worldSize.y));
      expect(game.player!.position.y, greaterThan(room.doorPosition.y - 100));
      expect(room.solidBounds(), isNotEmpty);

      // The minimap follows whichever scene the player is standing in.
      expect(buildMiniMapScene(null).title, 'Town');
      expect(game.miniMapScene.value.title, 'Church');

      await game.exitLocation();
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.isInsideBuilding, isFalse);
      expect(left, ['church']);
      expect(game.activeWorld, isA<TownWorld>());
      expect(messages, isNotEmpty);
      expect(game.miniMapScene.value.title, 'Town');
      // ... and the dot is reported for the town again.
      game.update(1 / 60);
      final town = game.town!;
      final door = town.buildings
          .firstWhere((b) => b.location.id == 'church')
          .doorPosition;
      expect(game.playerMapPosition.value.distanceTo(door), lessThan(90));

      // Townspeople wander the sidewalks by themselves.
      final walkers = town.pedestrians;
      expect(walkers, isNotEmpty);
      final before = [for (final w in walkers) w.position.clone()];
      for (var i = 0; i < 120; i++) {
        game.update(1 / 60);
      }
      final moved = [
        for (var i = 0; i < walkers.length; i++)
          if (walkers[i].position.distanceTo(before[i]) > 20) i,
      ];
      expect(
        moved,
        isNotEmpty,
        reason: 'pedestrians should walk around on their own',
      );
      const walkerBody = FeetBody(halfWidth: 15, halfHeight: 15);
      for (final walker in walkers) {
        final rect = walkerBody.rectAt(walker.position);
        for (final solid in town.solidBounds()) {
          expect(
            rect.overlaps(solid.toRect()),
            isFalse,
            reason: 'a pedestrian is stuck inside ${solid.runtimeType}',
          );
        }
      }
    });
  });

  group('minimap', () {
    test('the town map shows every building and doorway', () {
      final scene = buildMiniMapScene(null);
      expect(scene.title, 'Town');
      expect(scene.width, kWorldWidth);
      expect(scene.height, kWorldHeight);
      expect(
        scene.blocks.where((b) => b.isMarker).length,
        buildTownLocations().length,
      );
      for (final l in buildTownLocations()) {
        expect(
          scene.blocks.any((b) => b.rect == Rect.fromLTWH(l.x, l.y, l.w, l.h)),
          isTrue,
          reason: '${l.id} is missing from the town map',
        );
      }
    });

    test('each room map matches its interior layout', () {
      for (final id in enterableLocations) {
        final layout = buildInterior(id);
        final scene = buildMiniMapScene(id);
        expect(scene.title, layout.title);
        expect(scene.width, layout.width);
        expect(scene.height, layout.height);
        expect(scene.background, Color(layout.floorColor));
        for (final prop in layout.props) {
          expect(
            scene.blocks.any(
              (b) => b.rect == Rect.fromLTWH(prop.x, prop.y, prop.w, prop.h),
            ),
            isTrue,
            reason: '$id furniture is missing from its map',
          );
        }
      }
    });

    testWidgets('the minimap title and dot follow the game', (tester) async {
      final position = ValueNotifier<Vector2>(Vector2(1600, 1310));
      final scene = ValueNotifier<MiniMapScene>(buildMiniMapScene(null));
      addTearDown(position.dispose);
      addTearDown(scene.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniMap(position: position, scene: scene),
          ),
        ),
      );
      expect(find.text('Town'), findsOneWidget);

      // Walking into a building swaps the map to that room.
      scene.value = buildMiniMapScene('plaza');
      position.value = Vector2(800, 900);
      await tester.pump();
      expect(find.text('Town'), findsNothing);
      expect(find.text('Plaza'), findsOneWidget);
    });
  });

  group('touch triggers', () {
    testWidgets('standing at a bench offers "Sit", scenery never does', (
      tester,
    ) async {
      Interactable? nearest;
      final game = LifeGame(
        onNearestChanged: (value) => nearest = value,
        onEnterLocation: (_) {},
        onOpenLocationMenu: (_) {},
        onLeftLocation: (_) {},
        onTalkTo: (_) {},
        onMessage: (_) {},
        random: Random(7),
      );

      await tester.pumpWidget(GameWidget(game: game));
      for (var i = 0; i < 30 && !game.isReady; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(game.isReady, isTrue);

      final town = game.town!;
      StreetProp propOf(String kind) =>
          town.streetProps.firstWhere((p) => p.decoration.kind == kind);

      // Collision stops the feet body flush with a solid's edge, so this is
      // where the player really ends up after walking into the prop.
      void standFlushAgainst(StreetProp prop) {
        final rect = prop.toRect();
        game.player!.position = Vector2(
          rect.center.dx,
          rect.bottom + PlayerComponent.feetBody.halfHeight,
        );
      }

      // Standing at the bench: the sit action must appear.
      final bench = propOf('bench');
      standFlushAgainst(bench);
      game.update(1 / 60);
      expect(nearest, same(bench));
      expect(nearest!.isSeat, isTrue);
      expect(nearest!.interactLabel, 'Sit on the bench');

      // Stepping away again (onto the empty highway) drops the action.
      game.player!.position = Vector2(
        bench.toRect().center.dx,
        kHighwayTop + kHighwayHeight / 2,
      );
      game.update(1 / 60);
      expect(nearest, isNot(same(bench)));

      // Trees, lamps and hydrants are scenery: no action even when touching.
      for (final kind in ['tree', 'lamp', 'hydrant']) {
        final prop = propOf(kind);
        standFlushAgainst(prop);
        game.update(1 / 60);
        expect(
          nearest,
          isNot(same(prop)),
          reason: '$kind is scenery and must not show an action button',
        );
      }

      // Furniture inside a room follows the same rule: standing flush with
      // the park bench offers the sit action.
      await game.enterLocation('park');
      await tester.pump(const Duration(milliseconds: 16));
      expect(game.currentLocationId, 'park');

      final room = game.activeWorld! as InteriorWorld;
      final parkBench = room
          .solidBounds()
          .whereType<InteriorPropBlock>()
          .firstWhere((p) => p.prop.label == 'BENCH');
      game.player!.position = Vector2(
        parkBench.center.x,
        parkBench.toRect().bottom + PlayerComponent.feetBody.halfHeight,
      );
      game.update(1 / 60);
      expect(nearest, same(parkBench));
      expect(nearest!.isSeat, isTrue);
      expect(nearest!.interactLabel, 'Sit on the bench');
    });
  });

  group('stickman', () {
    test('walks toward the joystick direction, faster when running', () {
      final walker = PlayerComponent(spawn: Vector2(1600, 1310));
      walker.moveInput = Vector2(1, 0);
      walker.update(0.1);
      expect(walker.position.x, greaterThan(1600));
      expect(walker.position.y, closeTo(1310, 0.001));

      final beforeWalkingBack = walker.position.x;
      walker.moveInput = Vector2(-1, 0);
      walker.update(0.1);
      expect(walker.position.x, lessThan(beforeWalkingBack));

      final runner = PlayerComponent(spawn: Vector2(1600, 1310))
        ..running = true
        ..moveInput = Vector2(1, 0);
      runner.update(0.1);
      expect(runner.speed, greaterThan(walker.speed));
      expect(runner.position.x - 1600, greaterThan(1600 - walker.position.x));
    });

    test('collision box sits at the feet, not the whole figure', () {
      final walker = PlayerComponent(spawn: Vector2(500, 500));
      expect(walker.size.y, greaterThan(48));
      expect(walker.feetRect.height, lessThan(walker.size.y / 2));
      // Feet box stays on the ground, the tall body is drawn above it.
      expect(walker.toRect().top, lessThan(walker.feetRect.top));
      expect(walker.feetRect.bottom, greaterThanOrEqualTo(500));
    });

    test('draws a head-to-toe figure whose limbs move while walking', () async {
      // Position the figure so its 44x96 box starts at the canvas origin.
      final walker = PlayerComponent(spawn: Vector2(22, 96));

      Future<Uint8List> shoot() async {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        walker.renderTree(canvas);
        final image = await recorder.endRecording().toImage(44, 96);
        final data = await image.toByteData(format: ImageByteFormat.rawRgba);
        return data!.buffer.asUint8List();
      }

      int painted(Uint8List pixels, int fromRow, int toRow) {
        var count = 0;
        for (var y = fromRow; y < toRow; y++) {
          for (var x = 0; x < 44; x++) {
            if (pixels[(y * 44 + x) * 4 + 3] > 0) count++;
          }
        }
        return count;
      }

      final idle = await shoot();
      // Head at the top of the box, feet at the bottom.
      expect(painted(idle, 0, 30), greaterThan(0));
      expect(painted(idle, 60, 96), greaterThan(0));

      walker.moveInput = Vector2(1, 0);
      for (var i = 0; i < 12; i++) {
        walker.update(1 / 60);
      }
      final midStride = await shoot();
      expect(midStride, isNot(equals(idle)));
    });

    test('renders an animated pose without throwing', () {
      final walker = PlayerComponent(spawn: Vector2(100, 100));
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      walker.renderTree(canvas); // idle pose

      walker.moveInput = Vector2(1, -1);
      for (var i = 0; i < 20; i++) {
        walker.update(1 / 60);
      }
      walker.renderTree(canvas); // mid-stride

      walker.running = true;
      walker.update(1 / 60);
      walker.renderTree(canvas); // running
      recorder.endRecording();
    });
  });
}
