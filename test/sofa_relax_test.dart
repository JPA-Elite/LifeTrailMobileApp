import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/state/game_state.dart';
import 'package:lifetrail/game/world/interior_data.dart';
import 'package:lifetrail/screens/sofa_relax_screen.dart';

/// A tiny host that pushes the sofa scene like GameScreen does and exposes
/// the result the scene pops with.
class _Host extends StatelessWidget {
  const _Host({required this.onResult});

  final ValueChanged<SofaRelaxResult?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.of(context).push<SofaRelaxResult>(
              MaterialPageRoute(builder: (_) => const SofaRelaxScreen()),
            );
            onResult(result);
          },
          child: const Text('Open sofa'),
        ),
      ),
    );
  }
}

Widget _app(GameState state, ValueChanged<SofaRelaxResult?> onResult) {
  return ProviderScope(
    overrides: [gameStateProvider.overrideWith((ref) => state)],
    child: MaterialApp(home: _Host(onResult: onResult)),
  );
}

Future<void> _openSofa(WidgetTester tester) async {
  await tester.tap(find.text('Open sofa'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('only the home sofa opts into the relaxation scene', () {
    final home = buildInterior('home');
    final sofa = home.props.firstWhere((p) => p.label == 'SOFA');
    expect(sofa.relaxScene, isTrue);
    expect(home.props.where((p) => p.relaxScene), hasLength(1));

    final park = buildInterior('park');
    expect(park.props.any((p) => p.relaxScene), isFalse);
  });

  test('happiness gains clamp at the maximum', () {
    final state = GameState();
    state.player = state.player.copyWith(happiness: 99);
    expect(state.addHappiness(1), 100);
    expect(state.addHappiness(5), 100);
    expect(state.player.happiness, 100);
  });

  testWidgets('happiness rises every five seconds and auto-leaves at 100', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = GameState();
    state.player = state.player.copyWith(happiness: 97);
    SofaRelaxResult? result;
    await tester.pumpWidget(_app(state, (r) => result = r));
    await _openSofa(tester);

    expect(find.byType(SofaRelaxScreen), findsOneWidget);
    expect(find.text('97'), findsOneWidget);
    expect(find.text('Leave the sofa'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(state.player.happiness, 98);
    expect(find.text('98'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(state.player.happiness, 99);

    await tester.pump(const Duration(seconds: 5));
    expect(state.player.happiness, 100);
    expect(find.text('Pure bliss!'), findsOneWidget);

    // The scene celebrates briefly, then stands the player up by itself.
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(result, isNotNull);
    expect(result!.gained, 3);
    expect(result!.reachedFull, isTrue);
    expect(state.player.happiness, 100);
    expect(find.byType(SofaRelaxScreen), findsNothing);
  });

  testWidgets('leave button stops the sitting and keeps gained happiness', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = GameState();
    state.player = state.player.copyWith(happiness: 50);
    SofaRelaxResult? result;
    await tester.pumpWidget(_app(state, (r) => result = r));
    await _openSofa(tester);

    await tester.pump(const Duration(seconds: 5));
    expect(state.player.happiness, 51);

    await tester.tap(find.text('Leave the sofa'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(result, isNotNull);
    expect(result!.gained, 1);
    expect(result!.reachedFull, isFalse);
    expect(find.byType(SofaRelaxScreen), findsNothing);

    // The timer is cancelled: no more points after standing up.
    await tester.pump(const Duration(seconds: 12));
    expect(state.player.happiness, 51);
  });

  testWidgets('opening at full happiness adds nothing and leaves', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = GameState();
    state.player = state.player.copyWith(happiness: 100);
    SofaRelaxResult? result;
    await tester.pumpWidget(_app(state, (r) => result = r));
    await _openSofa(tester);

    expect(find.text('Pure bliss!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(result, isNotNull);
    expect(result!.gained, 0);
    expect(result!.reachedFull, isTrue);
    expect(state.player.happiness, 100);
  });
}
