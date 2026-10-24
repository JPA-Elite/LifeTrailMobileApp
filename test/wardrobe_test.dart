import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/state/game_state.dart';
import 'package:lifetrail/game/world/interior_data.dart';
import 'package:lifetrail/models/outfit.dart';
import 'package:lifetrail/models/player_model.dart';
import 'package:lifetrail/screens/wardrobe_screen.dart';

/// Tiny host that pushes the wardrobe the same way GameScreen does and
/// exposes the result the scene pops with.
class _Host extends StatelessWidget {
  const _Host({required this.onResult});

  final ValueChanged<WardrobeResult?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.of(context).push<WardrobeResult>(
              MaterialPageRoute(builder: (_) => const WardrobeScreen()),
            );
            onResult(result);
          },
          child: const Text('Open closet'),
        ),
      ),
    );
  }
}

void main() {
  group('Outfit catalog', () {
    test('ships five tees and five shorts with safe lookups', () {
      expect(OutfitCatalog.shirts, hasLength(5));
      expect(OutfitCatalog.shorts, hasLength(5));
      expect(
        OutfitCatalog.shirts.map((item) => item.name).toSet(),
        hasLength(5),
      );
      expect(
        OutfitCatalog.shorts.map((item) => item.name).toSet(),
        hasLength(5),
      );
      expect(OutfitCatalog.shirtAt(-4), OutfitCatalog.shirts.first);
      expect(OutfitCatalog.shirtAt(99), OutfitCatalog.shirts.last);
      expect(OutfitCatalog.shortsAt(-4), OutfitCatalog.shorts.first);
      expect(OutfitCatalog.shortsAt(99), OutfitCatalog.shorts.last);
      expect(OutfitCatalog.lookName(0, 0), 'Sunny Everyday');
    });
  });

  group('Player outfit persistence', () {
    test('round-trips the chosen indexes', () {
      const player = PlayerModel(shirtIndex: 3, shortsIndex: 4);
      final json = player.toJson();
      final restored = PlayerModel.fromJson(json);
      expect(restored.shirtIndex, 3);
      expect(restored.shortsIndex, 4);
    });

    test('clamps out-of-range saved indexes and keeps old saves valid', () {
      final clamped = PlayerModel.fromJson({
        ...const PlayerModel().toJson(),
        'shirtIndex': 99,
        'shortsIndex': -2,
      });
      expect(clamped.shirtIndex, OutfitCatalog.shirts.length - 1);
      expect(clamped.shortsIndex, 0);

      final oldSave = PlayerModel.fromJson(
        {...const PlayerModel().toJson()}
          ..remove('shirtIndex')
          ..remove('shortsIndex'),
      );
      expect(oldSave.shirtIndex, 0);
      expect(oldSave.shortsIndex, 0);
    });
  });

  group('Game state outfit', () {
    test('applies, clamps and notifies only on real changes', () {
      final state = GameState();
      var notifications = 0;
      state.addListener(() => notifications++);

      state.setOutfit(shirtIndex: 2, shortsIndex: 3);
      expect(state.player.shirtIndex, 2);
      expect(state.player.shortsIndex, 3);
      expect(notifications, 1);

      state.setOutfit(shirtIndex: 2, shortsIndex: 3);
      expect(notifications, 1);

      state.setOutfit(shirtIndex: 99, shortsIndex: -1);
      expect(state.player.shirtIndex, OutfitCatalog.shirts.length - 1);
      expect(state.player.shortsIndex, 0);
      expect(notifications, 2);
    });
  });

  group('Home closet', () {
    test('only the closet opts into the wardrobe scene', () {
      final home = buildInterior('home');
      final wardrobes = home.props.where((prop) => prop.wardrobe).toList();
      expect(wardrobes, hasLength(1));
      expect(wardrobes.single.label, 'CLOSET');
      expect(wardrobes.single.interactLabel, 'Open the closet');
    });
  });

  testWidgets('tapping cards wears the pieces and Done returns changed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(gameStateProvider);
    WardrobeResult? result;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: _Host(onResult: (value) => result = value)),
      ),
    );

    await tester.tap(find.text('Open closet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.text('Coral Classic'), findsOneWidget);
    expect(find.text('Denim Days'), findsOneWidget);
    expect(find.text('Mint Fresh'), findsOneWidget);
    expect(find.text('Sage Stroll'), findsOneWidget);

    await tester.tap(find.text('Mint Fresh'));
    await tester.pump(const Duration(milliseconds: 240));
    expect(state.player.shirtIndex, 1);
    expect(state.player.shortsIndex, 0);

    await tester.tap(find.text('Sage Stroll'));
    await tester.pump(const Duration(milliseconds: 240));
    expect(state.player.shirtIndex, 1);
    expect(state.player.shortsIndex, 1);
    expect(find.text('Mint Fresh  ·  Sage Stroll'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(result, isNotNull);
    expect(result!.changed, isTrue);
  });
}
