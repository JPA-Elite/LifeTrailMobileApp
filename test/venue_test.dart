import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/state/game_state.dart';
import 'package:lifetrail/game/systems/venue_system.dart';
import 'package:lifetrail/game/world/interior_data.dart';
import 'package:lifetrail/game/world/town_world.dart';
import 'package:lifetrail/models/game_time.dart';
import 'package:lifetrail/models/quest_model.dart';
import 'package:lifetrail/models/venue.dart';
import 'package:lifetrail/screens/venue_scene_screen.dart';

/// Pushes a venue scene the way GameScreen does and reports what it popped.
class _VenueHost extends StatelessWidget {
  const _VenueHost({required this.venue, required this.onResult});

  final Venue venue;
  final ValueChanged<VenueSceneResult?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.of(context).push<VenueSceneResult>(
              MaterialPageRoute(builder: (_) => VenueSceneScreen(venue: venue)),
            );
            onResult(result);
          },
          child: const Text('Open venue'),
        ),
      ),
    );
  }
}

Widget _app(
  GameState state,
  Venue venue,
  ValueChanged<VenueSceneResult?> onResult,
) {
  return ProviderScope(
    overrides: [gameStateProvider.overrideWith((ref) => state)],
    child: MaterialApp(home: _VenueHost(venue: venue, onResult: onResult)),
  );
}

Future<void> _openVenue(WidgetTester tester) async {
  await tester.tap(find.text('Open venue'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

VenueAction _action(String venueId, String actionId) => VenueCatalog
    .forId(venueId)!
    .actions
    .firstWhere((a) => a.id == actionId);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('catalog', () {
    test('covers every enterable town building except home', () {
      final town = TownWorld(onNearestChanged: (_) {});
      final enterable = town.buildings
          .map((b) => b.location.id)
          .where((id) => id != 'home')
          .toSet();

      expect(VenueCatalog.all, hasLength(20));
      expect(VenueCatalog.forId('home'), isNull);
      for (final id in enterable) {
        expect(
          VenueCatalog.forId(id),
          isNotNull,
          reason: '$id has no venue scenario',
        );
      }
      // No venue points at a building the town does not have.
      for (final venue in VenueCatalog.all) {
        expect(enterable, contains(venue.id), reason: venue.id);
      }
    });

    test('every venue is fully authored', () {
      final scenes = <VenueScene>{};
      for (final venue in VenueCatalog.all) {
        scenes.add(venue.scene);
        expect(venue.title, isNotEmpty);
        expect(venue.subtitle, isNotEmpty);
        expect(venue.tagline, isNotEmpty);
        expect(venue.intro.length, greaterThan(30), reason: venue.id);
        if (venue.id == 'bank') {
          // Withdraw allowance, balance, savings, ceiling fan, pay rent.
          expect(venue.actions, hasLength(5), reason: venue.id);
          expect(venue.actions.map((a) => a.id), contains('pay_rent'));
        } else {
          expect(venue.actions, hasLength(4), reason: venue.id);
        }
        expect(
          venue.actions.map((a) => a.id).toSet(),
          hasLength(venue.actions.length),
          reason: '${venue.id} has duplicate action ids',
        );
        for (final action in venue.actions) {
          expect(action.label, isNotEmpty);
          expect(action.blurb, isNotEmpty);
        }
      }
      // One hand-painted backdrop per building.
      expect(scenes, hasLength(20));
    });

    test('every town layout has exactly one venue prop with a prompt', () {
      final town = TownWorld(onNearestChanged: (_) {});
      for (final building in town.buildings) {
        final id = building.location.id;
        final layout = buildInterior(id);
        final venueProps = layout.props.where((p) => p.venueScene).toList();
        if (id == 'home') {
          expect(venueProps, isEmpty, reason: 'home keeps its own scenes');
          continue;
        }
        expect(venueProps, hasLength(1), reason: '$id venue prop count');
        expect(venueProps.single.opensMenu, isTrue, reason: id);
        expect(
          venueProps.single.interactLabel,
          startsWith('Step '),
          reason: id,
        );
      }
    });
  });

  group('actions', () {
    test('an ordinary action spends money, time and energy', () {
      final state = GameState();
      state.player = state.player.copyWith(money: 500, energy: 80);
      final beforeMinutes = state.time.day * 1440 + state.time.minutes;

      final outcome = applyVenueAction(
        state,
        _action('workplace', 'order_flat_white'),
      );

      expect(outcome.ok, isTrue);
      expect(state.player.money, 455);
      expect(state.player.energy, 90);
      expect(state.player.happiness, 73);
      expect(
        state.time.day * 1440 + state.time.minutes - beforeMinutes,
        20,
      );
    });

    test('a blocked action spends nothing at all', () {
      final state = GameState();
      state.player = state.player.copyWith(money: 0, energy: 80);
      final beforeMinutes = state.time.day * 1440 + state.time.minutes;
      final beforeEnergy = state.player.energy;

      final outcome = applyVenueAction(
        state,
        _action('workplace', 'order_flat_white'),
      );

      expect(outcome.ok, isFalse);
      expect(outcome.message, contains('₱45'));
      expect(state.player.money, 0);
      expect(state.player.energy, beforeEnergy);
      expect(state.time.day * 1440 + state.time.minutes, beforeMinutes);
    });

    test('exhaustion blocks an energy-costing action', () {
      final state = GameState();
      state.player = state.player.copyWith(energy: 5, money: 500);

      final outcome = applyVenueAction(
        state,
        _action('park', 'gym_session'),
      );

      expect(outcome.ok, isFalse);
      expect(outcome.message, contains('tired'));
      expect(state.player.energy, 5);
      expect(state.player.strength, 10);
    });

    test('class attendance bumps attendance, education and intelligence', () {
      final state = GameState();
      state.player = state.player.copyWith(energy: 90);

      final outcome = applyVenueAction(
        state,
        _action('school', 'attend_class'),
      );

      expect(outcome.ok, isTrue);
      expect(state.player.attendanceTaken, 1);
      expect(state.player.attendancePresent, 1);
      // The class activity grants +2 education / +1 intelligence exactly
      // once; attendClass must not double-count it.
      expect(state.player.education, 12);
      expect(state.player.intelligence, 11);
    });

    test('the bank allowance adds cash once per withdrawal', () {
      final state = GameState();
      state.player = state.player.copyWith(money: 100);

      final outcome = applyVenueAction(
        state,
        _action('bank', 'withdraw_allowance'),
      );

      expect(outcome.ok, isTrue);
      expect(state.player.money, 300);
    });

    test('the allowance cannot be farmed twice on the same day', () {
      final state = GameState();
      state.player = state.player.copyWith(money: 0);

      final first = applyVenueAction(
        state,
        _action('bank', 'withdraw_allowance'),
      );
      final moneyAfterFirst = state.player.money;
      final minutesAfterFirst = state.time.day * 1440 + state.time.minutes;

      final second = applyVenueAction(
        state,
        _action('bank', 'withdraw_allowance'),
      );

      expect(first.ok, isTrue);
      expect(second.ok, isFalse);
      expect(second.message, contains('already collected'));
      expect(state.player.money, moneyAfterFirst);
      expect(
        state.time.day * 1440 + state.time.minutes,
        minutesAfterFirst,
      );

      // Tomorrow it opens again.
      state.time = state.time.addMinutes(24 * 60);
      final third = applyVenueAction(
        state,
        _action('bank', 'withdraw_allowance'),
      );
      expect(third.ok, isTrue);
      expect(state.player.money, moneyAfterFirst + 200);
    });

    test('paying the rent clears the overdue flag and cannot repeat', () {
      final state = GameState();
      state.player = state.player.copyWith(money: 1000);
      state.time = state.time.addMinutes(7 * 24 * 60);

      expect(state.isDebtOverdue, isTrue);

      final first = applyVenueAction(
        state,
        _action('bank', 'pay_rent'),
      );

      expect(first.ok, isTrue);
      expect(state.player.money, 500);
      expect(state.rentPaid, isTrue);
      expect(state.isDebtOverdue, isFalse);

      final second = applyVenueAction(
        state,
        _action('bank', 'pay_rent'),
      );
      expect(second.ok, isFalse);
      expect(state.player.money, 500);
    });

    test('pantry restock fills the shelves', () {
      final state = GameState();
      state.player = state.player.copyWith(money: 500);
      state.inventory.clear();

      final outcome = applyVenueAction(
        state,
        _action('supermarket', 'stock_pantry'),
      );

      expect(outcome.ok, isTrue);
      expect(state.inventory, isNotEmpty);
      expect(state.player.money, 380);
    });

    test('the wallet only turns up while the quest is active', () {
      final state = GameState();
      const quest = QuestModel(
        id: 'missing_wallet',
        title: 'Missing Wallet',
        description: 'Find Maria\'s wallet.',
        npcId: 'maria',
        status: QuestStatus.active,
        objectives: [
          QuestObjective(id: 'search_plaza', description: 'Search the plaza'),
        ],
      );
      state.quests['missing_wallet'] = quest;

      final outcome = applyVenueAction(
        state,
        _action('plaza', 'find_wallet'),
      );

      expect(outcome.ok, isTrue);
      expect(outcome.message, contains('wallet'));
      expect(state.itemCount('wallet_maria'), 1);
      expect(state.quests['missing_wallet']!.status, QuestStatus.completed);
    });

    test('wallet search finds nothing when the quest is not active', () {
      final state = GameState();

      final outcome = applyVenueAction(
        state,
        _action('plaza', 'find_wallet'),
      );

      expect(outcome.ok, isTrue);
      expect(state.itemCount('wallet_maria'), 0);
      expect(state.quests.containsKey('missing_wallet'), isFalse);
    });

    test('booking a hotel room sleeps to the next morning at 07:00', () {
      final state = GameState();
      state.player = state.player.copyWith(money: 500, energy: 10);
      final day = state.time.day;

      final outcome = applyVenueAction(
        state,
        _action('hotel', 'book_room'),
      );

      expect(outcome.ok, isTrue);
      expect(state.time.day, day + 1);
      expect(state.time.minutes, 7 * 60);
      expect(state.player.energy, 100);
      expect(state.player.money, 200);
    });

    test('an item action adds a stack to the bag', () {
      final state = GameState();
      state.player = state.player.copyWith(money: 100);
      state.inventory.clear();

      final outcome = applyVenueAction(
        state,
        _action('pizzahut', 'eat_pizza'),
      );

      expect(outcome.ok, isTrue);
      expect(state.player.money, 30);
      expect(state.player.energy, 90);
    });

    test('every action in the catalog is reachable and priced sensibly', () {
      for (final venue in VenueCatalog.all) {
        for (final action in venue.actions) {
          expect(action.moneyCost, greaterThanOrEqualTo(0));
          expect(action.moneyGain, greaterThanOrEqualTo(0));
          expect(action.minutes, greaterThanOrEqualTo(0));
          expect(action.costChips, isNotEmpty, reason: action.id);
        }
      }
    });

    test('a quiz is charged once, not once per question', () {
      final state = GameState();
      state.player = state.player.copyWith(energy: 80);
      final beforeMinutes = state.time.day * 1440 + state.time.minutes;

      final result = state.finishQuiz(correct: 5, total: 5);

      expect(result.ok, isTrue);
      expect(result.passed, isTrue);
      expect(
        state.time.day * 1440 + state.time.minutes - beforeMinutes,
        15,
      );
      expect(state.player.energy, 78);
      expect(state.player.education, 12);
      expect(state.player.intelligence, 12);
      expect(state.player.happiness, 73);
      expect(state.player.money, 550);
    });

    test('opening hours gate entry, and all-night venues stay open', () {
      final state = GameState();
      state.time = const GameTime(day: 1, minutes: 22 * 60); // Mon 22:00

      expect(state.canEnterBuilding('home'), isTrue);
      expect(state.canEnterBuilding('bank'), isFalse);
      expect(state.canEnterBuilding('school'), isFalse);
      expect(state.canEnterBuilding('hospital'), isTrue);
      expect(state.canEnterBuilding('police'), isTrue);
      expect(state.canEnterBuilding('hotel'), isTrue);

      final reason = venueUnavailableReason(
        state,
        _action('bank', 'check_balance'),
        venue: VenueCatalog.bank,
      );
      expect(reason, isNotNull);
      expect(reason, contains('closed'));
    });

    test('sleeping with overdue rent costs health and happiness', () {
      final state = GameState();
      state.player = state.player.copyWith(health: 80, happiness: 70);
      state.time = const GameTime(day: 8, minutes: 22 * 60);

      state.sleep();

      expect(state.time.minutes, 7 * 60);
      expect(state.player.health, 78);
      expect(state.player.happiness, 67);
    });
  });

  group('scene', () {
    testWidgets('renders compact without overflowing and pops a menu result', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final state = GameState();
      VenueSceneResult? result;
      await tester.pumpWidget(
        _app(state, VenueCatalog.school, (r) => result = r),
      );
      await _openVenue(tester);

      expect(find.byType(VenueSceneScreen), findsOneWidget);
      expect(find.text('School'), findsOneWidget);
      expect(find.text('Sit through class'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The panel scrolls in portrait; bring the footer into view.
      await tester.scrollUntilVisible(
        find.text('Full menu'),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Full menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(result, isNotNull);
      expect(result!.openMenu, isTrue);
      expect(result!.leaveBuilding, isFalse);
    });

    testWidgets('renders landscape and pops a leave result', (tester) async {
      tester.view.physicalSize = const Size(1180, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final state = GameState();
      VenueSceneResult? result;
      await tester.pumpWidget(
        _app(state, VenueCatalog.beach, (r) => result = r),
      );
      await _openVenue(tester);

      expect(find.byType(VenueSceneScreen), findsOneWidget);
      expect(find.text('Beach'), findsOneWidget);
      expect(find.text('Swim out past the break'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Leave'));
      await tester.tap(find.text('Leave'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(result, isNotNull);
      expect(result!.leaveBuilding, isTrue);
      expect(result!.openMenu, isFalse);
    });

    testWidgets('tapping an action applies it and shows the notice', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1180, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final state = GameState();
      state.player = state.player.copyWith(money: 500, energy: 80);
      await tester.pumpWidget(
        _app(state, VenueCatalog.cafe, (_) {}),
      );
      await _openVenue(tester);

      await tester.tap(find.text('Order a flat white'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(state.player.money, 455);
      expect(state.player.energy, 90);
      expect(find.textContaining('resets your whole afternoon'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a blocked action shows an error and keeps the money', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1180, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final state = GameState();
      state.player = state.player.copyWith(money: 0, energy: 80);
      await tester.pumpWidget(
        _app(state, VenueCatalog.cafe, (_) {}),
      );
      await _openVenue(tester);

      await tester.tap(find.text('Order a flat white'));
      await tester.pump();

      expect(state.player.money, 0);
      expect(state.player.energy, 80);
      expect(find.textContaining('need ₱45'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets('a closed venue shows its hours and refuses to serve', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1180, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final state = GameState();
      state.player = state.player.copyWith(money: 500);
      // Monday 22:00 — the bank shut at 16:00.
      state.time = const GameTime(day: 1, minutes: 22 * 60);
      await tester.pumpWidget(
        _app(state, VenueCatalog.bank, (_) {}),
      );
      await _openVenue(tester);

      expect(find.textContaining('Closed right now'), findsOneWidget);
      expect(find.textContaining('Mon–Fri 09:00–16:00'), findsOneWidget);

      await tester.ensureVisible(find.text('Withdraw your allowance'));
      await tester.tap(find.text('Withdraw your allowance'));
      await tester.pump();

      expect(state.player.money, 500);
      expect(state.flags['allowance_day'], isNull);
      expect(tester.takeException(), isNull);
    });
  });
}
