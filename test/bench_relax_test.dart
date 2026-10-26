import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/state/game_state.dart';
import 'package:lifetrail/game/world/interactable.dart';
import 'package:lifetrail/game/world/interior_data.dart';
import 'package:lifetrail/game/world/interior_world.dart';
import 'package:lifetrail/game/world/map_data.dart';
import 'package:lifetrail/game/world/town_world.dart';
import 'package:lifetrail/screens/bench_relax_screen.dart';
import 'package:lifetrail/screens/relax_scene_screen.dart';

/// Pushes the bench scene like GameScreen does and exposes its result.
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
              MaterialPageRoute(builder: (_) => const BenchRelaxScreen()),
            );
            onResult(result);
          },
          child: const Text('Open bench'),
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

Future<void> _openBench(WidgetTester tester) async {
  await tester.tap(find.text('Open bench'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('street benches are bench-flavoured relaxation seats', () {
    final bench = StreetProp(
      decoration: const TownDecoration('bench', 500, 500, 84),
    );
    expect(bench.isSeat, isTrue);
    expect(bench.opensRelaxScene, isTrue);
    expect(bench.relaxSpot, RelaxSpot.bench);

    final tree = StreetProp(
      decoration: const TownDecoration('tree', 500, 500, 132),
    );
    expect(tree.isSeat, isFalse);
    expect(tree.opensRelaxScene, isFalse);
  });

  test('a workbench is not mistaken for a park bench', () {
    const workbenchProp = InteriorProp(
      x: 600,
      y: 200,
      w: 400,
      h: 220,
      color: 0xFFB45F06,
      label: 'WORKBENCH',
      interactLabel: 'Open Repair menu',
      opensMenu: true,
    );
    final workbench = InteriorPropBlock(
      prop: workbenchProp,
      locationId: 'repair',
    );
    expect(workbench.opensRelaxScene, isFalse);

    const parkBenchProp = InteriorProp(
      x: 540,
      y: 700,
      w: 300,
      h: 110,
      color: 0xFFC79A6B,
      label: 'BENCH',
      interactLabel: 'Sit on the bench',
    );
    final parkBench = InteriorPropBlock(
      prop: parkBenchProp,
      locationId: 'park',
    );
    expect(parkBench.opensRelaxScene, isTrue);
    expect(parkBench.relaxSpot, RelaxSpot.bench);
  });

  testWidgets('bench scene rises and auto-leaves at full happiness', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = GameState();
    state.player = state.player.copyWith(happiness: 98);
    SofaRelaxResult? result;
    await tester.pumpWidget(_app(state, (r) => result = r));
    await _openBench(tester);

    expect(find.byType(BenchRelaxScreen), findsOneWidget);
    expect(find.text('Town · park bench'), findsOneWidget);
    expect(find.text('Leave the bench'), findsOneWidget);
    expect(find.text('98'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(state.player.happiness, 99);

    await tester.pump(const Duration(seconds: 5));
    expect(state.player.happiness, 100);
    expect(find.text('Pure bliss!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(result, isNotNull);
    expect(result!.gained, 2);
    expect(result!.reachedFull, isTrue);
    expect(find.byType(BenchRelaxScreen), findsNothing);
  });

  testWidgets('leaving the bench stops the happiness timer', (tester) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = GameState();
    state.player = state.player.copyWith(happiness: 40);
    SofaRelaxResult? result;
    await tester.pumpWidget(_app(state, (r) => result = r));
    await _openBench(tester);

    await tester.pump(const Duration(seconds: 5));
    expect(state.player.happiness, 41);

    await tester.tap(find.text('Leave the bench'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(result, isNotNull);
    expect(result!.gained, 1);
    expect(result!.reachedFull, isFalse);

    await tester.pump(const Duration(seconds: 12));
    expect(state.player.happiness, 41);
  });
}
