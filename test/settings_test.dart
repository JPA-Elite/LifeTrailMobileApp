import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/state/game_state.dart';
import 'package:lifetrail/models/game_time.dart';
import 'package:lifetrail/models/player_model.dart';
import 'package:lifetrail/screens/settings_screen.dart';
import 'package:lifetrail/services/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AudioService().enabled = true;
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sound switch persists through AudioService', (tester) async {
    await pumpSettings(tester);

    expect(AudioService().enabled, isTrue);
    await tester.tap(find.byKey(const ValueKey('settings_sound')));
    await tester.pumpAndSettle();

    expect(AudioService().enabled, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AudioService.prefsKey), isFalse);
  });

  testWidgets('about tab shows the loaded life stats', (tester) async {
    await pumpSettings(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    container
        .read(gameStateProvider)
        .loadSnapshot(
          player: const PlayerModel(health: 77, energy: 42, money: 1234),
          time: GameTime.morning(4),
          npcs: const {},
          quests: const {},
          flags: const {},
          inventory: const [],
        );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('settings_tab_about')));
    await tester.pumpAndSettle();

    expect(find.text('YOUR LIFE SO FAR'), findsOneWidget);
    expect(find.text('77/100'), findsOneWidget);
    expect(find.text('42/100'), findsOneWidget);
    expect(find.text('\$1,234'), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_about_no_game')), findsNothing);
  });

  testWidgets('terms tab carries local-only privacy text', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const ValueKey('settings_tab_terms')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings_terms_title')), findsOneWidget);
    final termsList = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('4. Privacy'),
      220,
      scrollable: termsList.first,
    );
    await tester.pumpAndSettle();
    expect(find.text('4. Privacy'), findsOneWidget);
    expect(
      find.textContaining('does not collect personal information'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleting a save slot removes only that slot', (tester) async {
    SharedPreferences.setMockInitialValues({
      'lifetrail_save_slot1': jsonEncode({
        'player': {'money': 500},
        'time': {'day': 2, 'minutes': 420},
      }),
      'lifetrail_save_slot2': jsonEncode({
        'player': {'money': 900},
        'time': {'day': 5, 'minutes': 600},
      }),
    });
    await pumpSettings(tester);

    expect(find.byKey(const ValueKey('settings_slot_slot1')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings_slot_slot2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings_delete_slot1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings_confirm_delete')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('lifetrail_save_slot1'), isFalse);
    expect(prefs.containsKey('lifetrail_save_slot2'), isTrue);
  });

  testWidgets('reset all clears every slot and returns to the menu', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'lifetrail_save_slot1': jsonEncode({'player': {}, 'time': {}}),
      'lifetrail_save_slot2': jsonEncode({'player': {}, 'time': {}}),
      'lifetrail_save_slot3': jsonEncode({'player': {}, 'time': {}}),
    });
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          initialRoute: '/settings',
          routes: {
            '/': (_) => const Scaffold(body: Center(child: Text('Main menu'))),
            '/settings': (_) => const SettingsScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings_reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings_confirm_reset')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    for (final slot in ['slot1', 'slot2', 'slot3']) {
      expect(prefs.containsKey('lifetrail_save_$slot'), isFalse);
    }
    expect(find.text('Main menu'), findsOneWidget);
  });

  testWidgets('fits a compact landscape phone without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800 * 3, 360 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpSettings(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('settings_tab_terms')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
