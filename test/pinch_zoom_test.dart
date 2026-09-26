import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/life_game.dart';

void main() {
  testWidgets('pinchStart + pinchZoomBy eases camera zoom', (tester) async {
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
    // Let onLoad finish (no pumpAndSettle: the game ticker never settles).
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(game.isLoaded, isTrue);

    final base = game.camera.viewfinder.zoom;
    debugPrint('base zoom: $base');

    // Simulate GameScreen's two-finger tracking: fingers land, spread 1.5x.
    game.pinchStart();
    game.pinchZoomBy(1.5);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final zoomed = game.camera.viewfinder.zoom;
    debugPrint('zoom after pinch out: $zoomed');
    expect(zoomed, greaterThan(base));
    expect(zoomed, closeTo(base * 1.5, 0.01));

    // Clamp holds at 3x default on extreme spread.
    game.pinchZoomBy(100);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(game.camera.viewfinder.zoom, closeTo(base * 3.0, 0.01));

    // Resize/rotation keeps the user's zoom (permanent) instead of
    // snapping back to the fitted default.
    final kept = game.camera.viewfinder.zoom;
    game.onGameResize(game.canvasSize);
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.camera.viewfinder.zoom, closeTo(kept, 0.05));

    // Single-finger drags never reach pinchZoomBy (GameScreen gates on
    // exactly two pointers), so joystick movement can't affect zoom.
    expect(game.camera.viewfinder.zoom, isNot(closeTo(base * 0.5, 0.01)));
  });
}
