import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/life_game.dart';
import 'package:lifetrail/game/world/interactable.dart';
import 'package:lifetrail/game/world/interior_world.dart';

/// Regression test: big home furniture must trigger from any side you can
/// stand on. Previously the 150px center-distance cap meant the bed bottom,
/// the kitchen, and the TV could never trigger at all.
void main() {
  testWidgets('home furniture triggers from every side', (tester) async {
    Interactable? nearest;
    final game = LifeGame(
      onNearestChanged: (n) => nearest = n,
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

    await game.enterLocation('home');
    await tester.pump(const Duration(milliseconds: 16));
    expect(game.isInsideBuilding, isTrue);

    void stand(double x, double y) {
      game.player!.position.setValues(x, y);
      game.player!.previousPosition.setValues(x, y);
      // Two ticks: the first feeds the fresh position to the room, the
      // second depth-sorts on it.
      game.update(1 / 60);
      game.update(1 / 60);
    }

    InteriorPropBlock blockOf(String label) => (game.activeWorld! as InteriorWorld)
        .children
        .whereType<InteriorPropBlock>()
        .firstWhere((b) => b.prop.label == label);

    // Below the bed (bottom surface).
    stand(190, 545);
    expect(nearest?.interactLabel, 'Sleep in bed');
    // South of the bed: player in front, drawn over it.
    expect(blockOf('BED').priority, lessThan(game.player!.priority));

    // West of the kitchen (left surface).
    stand(1040, 370);
    expect(nearest?.interactLabel, 'Open Home menu');

    // South-east of the TV (bottom surface, clear of the exit door).
    stand(950, 880);
    expect(nearest?.interactLabel, 'Turn on the TV');

    // North of the TV: player behind it, drawn under it (no more
    // sinking INTO the furniture).
    stand(775, 480);
    expect(blockOf('TV').priority, greaterThan(game.player!.priority));
  });
}
