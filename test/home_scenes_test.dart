import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide DayPeriod;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/life_game.dart';
import 'package:lifetrail/game/state/game_state.dart';
import 'package:lifetrail/game/systems/core_systems.dart';
import 'package:lifetrail/game/world/interactable.dart';
import 'package:lifetrail/game/world/interior_data.dart';
import 'package:lifetrail/models/cooking.dart';
import 'package:lifetrail/models/game_time.dart';
import 'package:lifetrail/models/tv_show.dart';
import 'package:lifetrail/screens/cooking_screen.dart';
import 'package:lifetrail/screens/dining_table_screen.dart';
import 'package:lifetrail/screens/retro_browser.dart';
import 'package:lifetrail/screens/tv_screen.dart';
import 'package:lifetrail/screens/window_view_screen.dart';

Widget _scene(GameState state, Widget child) {
  return ProviderScope(
    overrides: [gameStateProvider.overrideWith((ref) => state)],
    child: MaterialApp(home: child),
  );
}

Future<void> _setPhoneLandscape(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _setCompactLandscape(WidgetTester tester) async {
  tester.view.physicalSize = const Size(850, 393);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Home scene markers', () {
    testWidgets('the TV, kitchen, table and window trigger from inside', (
      tester,
    ) async {
      Interactable? nearest;
      final game = LifeGame(
        onNearestChanged: (n) => nearest = n,
        onEnterLocation: (_) {},
        onOpenLocationMenu: (_) {},
        onLeftLocation: (_) {},
        onTalkTo: (_) {},
        onMessage: (_) {},
        random: Random(11),
      );
      await tester.pumpWidget(GameWidget(game: game));
      for (var i = 0; i < 30 && !game.isReady; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await game.enterLocation('home');
      await tester.pump(const Duration(milliseconds: 16));

      void stand(double x, double y) {
        game.player!.position.setValues(x, y);
        game.player!.previousPosition.setValues(x, y);
        game.update(1 / 60);
        game.update(1 / 60);
      }

      // Free floor beneath the centre window, above the TV cabinet.
      stand(800, 190);
      expect(nearest?.interactLabel, 'Look out the window');
      expect((nearest! as WindowView).opensWindowView, isTrue);

      // South-east of the TV set, clear of the front door.
      stand(950, 880);
      expect(nearest?.interactLabel, 'Turn on the TV');
      expect((nearest! as Television).opensTvScene, isTrue);

      // South of the dining table.
      stand(1480, 940);
      expect(nearest?.interactLabel, 'Look at the table');
      expect((nearest! as DiningTable).opensDiningScene, isTrue);

      // West of the kitchen counter.
      stand(1040, 370);
      expect(nearest?.interactLabel, 'Open Home menu');
      expect((nearest! as CookingStation).opensCookingScene, isTrue);
    });

    test('TV, kitchen, table and centre window opt into their scenes', () {
      final home = buildInterior('home');
      final tv = home.props.firstWhere((prop) => prop.label == 'TV');
      final kitchen = home.props.firstWhere((prop) => prop.label == 'KITCHEN');
      final table = home.props.firstWhere((prop) => prop.label == 'TABLE');
      expect(tv.tvScene, isTrue);
      expect(kitchen.cookScene, isTrue);
      expect(table.diningScene, isTrue);
      expect(home.props.where((prop) => prop.tvScene), hasLength(1));
      expect(home.props.where((prop) => prop.cookScene), hasLength(1));
      expect(home.props.where((prop) => prop.diningScene), hasLength(1));
      expect(home.windows.where((window) => window.interactive), hasLength(1));
    });
  });

  group('Television', () {
    test('ships four channels, all backed by energy-costing activities', () {
      final state = GameState();
      expect(TvCatalog.channels, hasLength(4));
      for (final channel in TvCatalog.channels) {
        final cfg = Activities.of(channel.activityId);
        expect(cfg.energyDelta, lessThan(0));
        expect(cfg.minutes, greaterThan(0));
      }

      state.applyActivity('tv_movie');
      expect(state.player.energy, 72);
      expect(state.time.minutes, 7 * 60 + 120);
    });

    testWidgets('selecting a channel spends energy and starts the program', (
      tester,
    ) async {
      await _setPhoneLandscape(tester);
      final state = GameState();
      await tester.pumpWidget(_scene(state, const TvScreen()));
      await tester.pump();

      expect(find.text('Movie Night'), findsOneWidget);
      expect(find.text('Browse the Internet'), findsOneWidget);
      expect(find.text('Watch the News'), findsOneWidget);

      await tester.tap(find.text('Movie Night'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(state.player.energy, 72);
      expect(state.time.minutes, 7 * 60 + 120);
      expect(find.text('Neon Harbor'), findsWidgets);
      expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
    });

    testWidgets('internet channel opens the touch browser and charges once', (
      tester,
    ) async {
      await _setPhoneLandscape(tester);
      final state = GameState();
      await tester.pumpWidget(_scene(state, const TvScreen()));
      await tester.pump();

      await tester.tap(find.text('Browse the Internet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(state.player.energy, 76);
      expect(state.time.minutes, 7 * 60 + 60);
      expect(find.byType(RetroBrowser), findsOneWidget);
      expect(find.text('The small web, hand-indexed.'), findsOneWidget);
      expect(find.byKey(const ValueKey('retroweb_cursor')), findsNothing);
      expect(find.text('TAP to open · SWIPE to scroll'), findsOneWidget);

      // Browsing pages is free inside the already-paid TV visit.
      await tester.tap(find.text('The Harbor Herald'));
      await tester.pump();
      expect(
        find.text('Ferry strike ends with a handshake and free coffee'),
        findsOneWidget,
      );
      expect(state.player.energy, 76);
      expect(state.time.minutes, 7 * 60 + 60);

      await tester.tap(find.byIcon(Icons.power_settings_new_rounded));
      await tester.pump();
      expect(find.text('LIFETRAIL TV'), findsOneWidget);
    });
  });

  group('Cooking and pantry', () {
    test('starter pantry seeds once and cooking consumes the right stock', () {
      final state = GameState();
      state.ensureStarterPantry();
      expect(state.itemCount('bread'), PantryCatalog.starterStock['bread']);
      expect(state.hasFlag('pantry_seeded'), isTrue);
      final seededBread = state.itemCount('bread');

      state.ensureStarterPantry();
      expect(state.itemCount('bread'), seededBread);

      final breakfast = CookingCatalog.breakfast;
      final canCook = state.cookMeal(breakfast);
      expect(canCook, isTrue);
      expect(state.itemCount('bread'), seededBread - 1);
      expect(state.itemCount('egg'), 2);
      expect(state.itemCount('meal_breakfast'), 1);
      expect(state.player.energy, 76);
      expect(state.time.minutes, 7 * 60 + 45);

      expect(state.eatCookedMeal('meal_breakfast'), isTrue);
      expect(state.itemCount('meal_breakfast'), 0);
      expect(state.player.energy, 94);
      expect(state.time.minutes, 7 * 60 + 75);
    });

    test('cooking is atomic when an ingredient is missing', () {
      final state = GameState();
      state.ensureStarterPantry();
      state.removeItem('egg', 4);
      final bread = state.itemCount('bread');
      expect(state.cookMeal(CookingCatalog.breakfast), isFalse);
      expect(state.itemCount('bread'), bread);
      expect(state.itemCount('meal_breakfast'), 0);
    });

    test('a custom plate scales energy and stove time with every portion', () {
      final small = CookingCatalog.planCustom({'chicken': 3});
      final large = CookingCatalog.planCustom({'chicken': 6});

      expect(small.energy, 28);
      expect(small.cookMinutes, 48);
      expect(small.eatMinutes, 26);
      expect(small.cookEnergyCost, 3);

      expect(large.energy, 52);
      expect(large.cookMinutes, 84);
      expect(large.eatMinutes, 42);
      expect(large.cookEnergyCost, 5);
      expect(large.energy, greaterThan(small.energy));
      expect(large.cookMinutes, greaterThan(small.cookMinutes));
      expect(large.eatMinutes, greaterThan(small.eatMinutes));

      // A plate is capped at six portions however many are requested.
      expect(CookingCatalog.planCustom({'chicken': 9}).portions, 6);
      expect(
        CookingCatalog.planCustom({'chicken': 9}).ingredients['chicken'],
        6,
      );
    });

    test('custom cooking spends stock, time and energy atomically', () {
      final state = GameState();
      state.ensureStarterPantry();
      final plan = CookingCatalog.planCustom({'chicken': 2});
      expect(state.canCookCustom(plan), isTrue);

      final chicken = state.itemCount('chicken');
      final cooked = state.cookCustomMeal(plan);
      expect(cooked, isNotNull);
      expect(state.itemCount('chicken'), chicken - 2);
      expect(state.itemCount(plan.mealId), 1);
      expect(state.player.energy, 77);
      expect(state.time.minutes, 7 * 60 + plan.cookMinutes);
      expect(
        state.cookedMeals.any((meal) => meal.mealId == plan.mealId),
        isTrue,
      );

      final before = state.player.energy;
      expect(state.eatCookedMeal(plan.mealId), isTrue);
      expect(state.itemCount(plan.mealId), 0);
      expect(state.player.energy, before + plan.energy);
      expect(state.time.minutes, 7 * 60 + plan.cookMinutes + plan.eatMinutes);
    });

    testWidgets('the kitchen builds a custom plate and times the cook', (
      tester,
    ) async {
      await _setPhoneLandscape(tester);
      final state = GameState();
      state.ensureStarterPantry();
      final chicken = state.itemCount('chicken');
      await tester.pumpWidget(_scene(state, const CookingScreen()));
      await tester.pump();

      expect(find.text('PANTRY STOCK'), findsOneWidget);
      expect(find.text('Custom plate'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('add-chicken')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('add-chicken')));
      await tester.pump();

      expect(find.text('+20 energy'), findsOneWidget);
      expect(find.text('36 min cook'), findsOneWidget);
      expect(find.text('21 min meal'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('start-custom-cook')));
      await tester.pump();
      expect(
        find.textContaining('Cooking Little Chicken Skillet'),
        findsOneWidget,
      );
      expect(state.itemCount('chicken'), chicken);
      expect(find.textContaining('min left'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1200));
      expect(state.itemCount('chicken'), chicken);

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();
      expect(state.itemCount('chicken'), chicken - 2);
      expect(state.cookedMeals.where((meal) => meal.isCustom), hasLength(1));
      expect(find.textContaining('is plated'), findsOneWidget);
      expect(find.text('Set the table'), findsOneWidget);
    });

    testWidgets('the kitchen cooks breakfast and plates it for the table', (
      tester,
    ) async {
      await _setPhoneLandscape(tester);
      final state = GameState();
      state.ensureStarterPantry();
      final bread = state.itemCount('bread');
      await tester.pumpWidget(_scene(state, const CookingScreen()));
      await tester.pump();

      expect(find.text('PANTRY STOCK'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('classic-mode')));
      await tester.pump();

      expect(find.text('Sunrise Breakfast'), findsOneWidget);
      expect(find.text('Midday Rice Bowl'), findsOneWidget);
      expect(find.text('Sunset Noodle Pot'), findsOneWidget);

      await tester.tap(find.text('Cook').first);
      await tester.pump();
      expect(find.textContaining('Cooking Sunrise Breakfast'), findsOneWidget);
      expect(state.itemCount('bread'), bread);
      expect(state.itemCount('meal_breakfast'), 0);

      await tester.pump(const Duration(milliseconds: 1400));
      expect(state.itemCount('meal_breakfast'), 0);

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();
      expect(state.itemCount('bread'), bread - 1);
      expect(state.itemCount('meal_breakfast'), 1);
      expect(state.player.energy, 76);
      expect(find.text('Set the table'), findsOneWidget);
    });
  });

  group('Dining table', () {
    testWidgets('a cooked meal is eaten over time and then restores energy', (
      tester,
    ) async {
      await _setPhoneLandscape(tester);
      final state = GameState();
      state.player = state.player.copyWith(energy: 40);
      state.addItem('meal_breakfast', 1);
      await tester.pumpWidget(_scene(state, const DiningTableScreen()));
      await tester.pump();

      expect(find.text('Sunrise Breakfast'), findsOneWidget);
      expect(find.text('ON THE TABLE'), findsOneWidget);

      await tester.tap(find.text('Sunrise Breakfast'));
      await tester.pump();
      await tester.tap(find.textContaining('Sit down & eat'));
      await tester.pump();

      expect(find.textContaining('Eating Sunrise Breakfast'), findsOneWidget);
      expect(find.textContaining('min left'), findsOneWidget);
      expect(state.itemCount('meal_breakfast'), 1);
      expect(state.player.energy, 40);
      expect(state.time.minutes, 7 * 60);

      await tester.pump(const Duration(milliseconds: 1200));
      expect(state.itemCount('meal_breakfast'), 1);

      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump();
      expect(state.itemCount('meal_breakfast'), 0);
      expect(state.player.energy, 58);
      expect(state.time.minutes, 7 * 60 + 30);
      expect(find.text('Nothing plated yet.'), findsOneWidget);
    });

    testWidgets('a custom plate shows its own energy and eating timer', (
      tester,
    ) async {
      await _setPhoneLandscape(tester);
      final state = GameState();
      state.player = state.player.copyWith(energy: 40);
      final plan = CookingCatalog.planCustom({'rice': 2, 'chicken': 1});
      state.addItem(plan.mealId, 1);
      await tester.pumpWidget(_scene(state, const DiningTableScreen()));
      await tester.pump();

      expect(find.text('CUSTOM'), findsOneWidget);
      expect(find.textContaining('+${plan.energy} energy'), findsWidgets);
      expect(find.textContaining('${plan.eatMinutes}m'), findsWidgets);

      await tester.tap(find.textContaining('Sit down & eat'));
      await tester.pump();
      expect(find.textContaining('Eating ${plan.name}'), findsOneWidget);
      expect(state.itemCount(plan.mealId), 1);

      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
      expect(state.itemCount(plan.mealId), 0);
      expect(state.player.energy, 40 + plan.energy);
      expect(state.time.minutes, 7 * 60 + plan.eatMinutes);
    });

    testWidgets('an empty table points the player back to the kitchen', (
      tester,
    ) async {
      await _setPhoneLandscape(tester);
      final state = GameState();
      await tester.pumpWidget(_scene(state, const DiningTableScreen()));
      await tester.pump();

      expect(find.text('Nothing plated yet.'), findsOneWidget);
      expect(find.text('Go to the kitchen'), findsOneWidget);
    });
  });

  group('Compact phone layout', () {
    testWidgets('kitchen and dining scenes fit a short landscape screen', (
      tester,
    ) async {
      await _setCompactLandscape(tester);
      final state = GameState();
      state.ensureStarterPantry();

      await tester.pumpWidget(_scene(state, const CookingScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('add-egg')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('start-custom-cook')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Cooking'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(state.cookedMeals.where((meal) => meal.isCustom), hasLength(1));

      await tester.pumpWidget(_scene(state, const DiningTableScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.textContaining('Sit down & eat'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Eating'), findsWidgets);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Window view', () {
    testWidgets('the neighbourhood changes from morning to noon to night', (
      tester,
    ) async {
      await _setPhoneLandscape(tester);
      final state = GameState();
      await tester.pumpWidget(_scene(state, const WindowViewScreen()));
      await tester.pump();

      expect(find.text('Morning light'), findsOneWidget);
      expect(find.text('Maple Apartments'), findsOneWidget);
      expect(find.text('Corner Bakery'), findsOneWidget);

      state.advanceMinutes(6 * 60); // 13:00 — noon light.
      await tester.pump();
      expect(find.text('Noon light'), findsOneWidget);

      state.advanceMinutes(5 * 60); // 18:00 — evening.
      await tester.pump();
      expect(find.text('Evening light'), findsOneWidget);

      state.advanceMinutes(4 * 60); // 22:00 — night.
      await tester.pump();
      expect(find.text('Night light'), findsOneWidget);
    });

    test('the four periods map to the expected clock labels', () {
      expect(GameTime(day: 1, minutes: 8 * 60).period, DayPeriod.morning);
      expect(GameTime(day: 1, minutes: 13 * 60).period, DayPeriod.afternoon);
      expect(GameTime(day: 1, minutes: 18 * 60).period, DayPeriod.evening);
      expect(GameTime(day: 1, minutes: 22 * 60).period, DayPeriod.night);
    });
  });
}
