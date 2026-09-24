import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/models/location_dialogue.dart';
import 'package:lifetrail/widgets/dialogue_box.dart';
import 'package:lifetrail/widgets/game_hud.dart';

/// Landscape phone: 2400x1080 @3x -> 800x360 logical pixels.
const double kScreenWidth = 800;
const double kScreenHeight = 360;

void useLandscapePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(kScreenWidth * 3, kScreenHeight * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('HUD spans the full screen width', (tester) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: Stack(children: [GameHud()])),
        ),
      ),
    );

    expect(tester.getSize(find.byType(GameHud)).width, kScreenWidth);
  });

  testWidgets('HUD cards are equally tall (no spacious short card)', (
    tester,
  ) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: Stack(children: [GameHud()])),
        ),
      ),
    );

    Size card(String label) => tester.getSize(
      find
          .ancestor(
            of: find.textContaining(label),
            matching: find.byType(Container),
          )
          .first,
    );

    final clock = card('₱');
    final vitals = card('HP');
    final skills = card('Edu');

    expect(clock.height, vitals.height);
    expect(skills.height, clock.height);
    // Cards stay edge-to-edge with symmetric 8px gutters and 6px gaps.
    expect(
      clock.width + vitals.width + skills.width + 6 + 6 + 16,
      kScreenWidth,
    );
  });

  testWidgets('Dialogue box is 90% of the screen width', (tester) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          child: Scaffold(
            body: Stack(
              children: [
                DialogueBox(
                  node: const DialogueNode(
                    id: 'start',
                    speaker: 'Alex',
                    text: 'Hey! Are you going to the plaza later?',
                  ),
                  onChoice: (_) {},
                  onNext: () {},
                  onClose: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final box = tester.getSize(
      find
          .descendant(
            of: find.byType(DialogueBox),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(box.width, kScreenWidth * 0.9);
    // Floats above the bottom edge (centered card, not full-bleed).
    expect(tester.getBottomLeft(find.byType(DialogueBox)).dy, kScreenHeight);
  });
}
