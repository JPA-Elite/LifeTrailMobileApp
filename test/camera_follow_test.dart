import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/life_game.dart';
import 'package:lifetrail/game/world/interior_data.dart';

/// Landscape phone: 800x360 logical pixels.
const double _screenWidth = 800;
const double _screenHeight = 360;

/// Bottom-left joystick centre for the default 12px margin / 64px radius.
const Offset _joystickCentre = Offset(12 + 64.0, _screenHeight - 12 - 64.0);

void main() {
  testWidgets('camera stays steady on furniture and inside the scene', (
    tester,
  ) async {
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
      random: Random(7),
    );
    await tester.pumpWidget(GameWidget(game: game));
    for (var i = 0; i < 40 && !game.isReady; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await game.enterLocation('park');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final world = game.activeWorld!.worldSize;
    void expectInsideWorld() {
      final view = game.camera.visibleWorldRect;
      expect(view.left, greaterThanOrEqualTo(-0.01));
      expect(view.top, greaterThanOrEqualTo(-0.01));
      expect(view.right, lessThanOrEqualTo(world.x + 0.01));
      expect(view.bottom, lessThanOrEqualTo(world.y + 0.01));
    }

    // --- Pressed against furniture: the view must settle and stay put ---
    final bench = buildInterior(
      'park',
    ).props.firstWhere((p) => p.label == 'BENCH');
    game.player!.position.setValues(bench.x + bench.w / 2, bench.y - 30);
    game.player!.previousPosition.setValues(
      bench.x + bench.w / 2,
      bench.y - 30,
    );
    await tester.pump(const Duration(milliseconds: 16));

    final gesture = await tester.startGesture(_joystickCentre);
    await gesture.moveBy(const Offset(0, 95));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final settled = game.camera.viewfinder.position.clone();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // The old follow-before-collision path nudged the camera into the
    // bench and back, which read as screen shake.
    expect((game.camera.viewfinder.position - settled).length, lessThan(0.01));
    expect(game.camera.viewfinder.position.y, lessThan(bench.y));
    await gesture.up();

    // --- Clamping, panning and zooming all stay inside the scene ---
    game.player!.position.setValues(world.x - 50, world.y - 40);
    game.player!.previousPosition.setValues(world.x - 50, world.y - 40);
    await tester.pump(const Duration(milliseconds: 16));
    expectInsideWorld();

    game.panBy(const Offset(600, 400));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expectInsideWorld();
    }

    game.pinchStart();
    game.pinchZoomBy(3.0);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expectInsideWorld();
    }

    // Tear the game down explicitly so Flame has no queued lifecycle work
    // when the test binding resets.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 16));
  });
}
