import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/models/web_site.dart';
import 'package:lifetrail/screens/retro_browser.dart';
import 'package:lifetrail/screens/retro_site_page.dart';
import 'package:lifetrail/screens/retro_web_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RetroWeb directory', () {
    test('has exactly one hundred unique destinations', () {
      expect(WebSiteCatalog.directory, hasLength(100));
      final ids = WebSiteCatalog.directory.map((site) => site.id).toSet();
      final domains = WebSiteCatalog.directory
          .map((site) => site.domain)
          .toSet();
      expect(ids, hasLength(100));
      expect(domains, hasLength(100));
      expect(
        ids.contains(WebSiteCatalog.home.id),
        isFalse,
        reason: 'the portal is separate from the 100 destinations',
      );
    });

    test('every site is complete and every internal link resolves', () {
      for (final site in WebSiteCatalog.directory) {
        expect(site.name.trim(), isNotEmpty, reason: site.id);
        expect(site.domain.trim(), isNotEmpty, reason: site.id);
        expect(site.tagline.trim(), isNotEmpty, reason: site.id);
        expect(site.headline.trim(), isNotEmpty, reason: site.id);
        expect(site.summary.trim(), isNotEmpty, reason: site.id);
        expect(
          WebSiteCatalog.categoryOrder.contains(site.category),
          isTrue,
          reason: '${site.id} has category ${site.category}',
        );
        expect(site.links.length, greaterThanOrEqualTo(3), reason: site.id);
        expect(site.linksResolve, isTrue, reason: site.id);
        expect(site.bullets.length, greaterThanOrEqualTo(3), reason: site.id);
        expect(site.tags.length, greaterThanOrEqualTo(2), reason: site.id);
        if (site.kind == WebKind.quiz) {
          expect(
            site.questions.length,
            greaterThanOrEqualTo(2),
            reason: site.id,
          );
          for (final question in site.questions) {
            expect(question.options.length, greaterThanOrEqualTo(3));
            expect(
              question.answer,
              inInclusiveRange(0, question.options.length),
            );
          }
        }
        if (site.kind == WebKind.shop) {
          expect(
            site.products.length,
            greaterThanOrEqualTo(2),
            reason: site.id,
          );
        }
      }
      expect(WebSiteCatalog.home.linksResolve, isTrue);
    });

    test('category counts add up to the directory', () {
      var total = 0;
      for (final category in WebSiteCatalog.categoryOrder) {
        final count = WebSiteCatalog.countIn(category);
        expect(count, greaterThanOrEqualTo(3), reason: category);
        total += count;
      }
      expect(total, 100);
      expect(WebSiteCatalog.countIn('Tech'), 9);
      expect(WebSiteCatalog.countIn('Quizzes'), 8);
      expect(WebSiteCatalog.countIn('Art'), 4);
    });

    test('search matches names, topics, and domains', () {
      expect(
        WebSiteCatalog.search('bread').map((site) => site.id),
        contains('soup_of_day'),
      );
      expect(
        WebSiteCatalog.search('space').map((site) => site.id),
        contains('orbital_notes'),
      );
      expect(
        WebSiteCatalog.search('quizjar.fun').map((site) => site.id),
        contains('quiz_jar'),
      );
      expect(WebSiteCatalog.search('   '), hasLength(100));
      expect(WebSiteCatalog.search('no-such-site-anywhere'), isEmpty);
    });

    test('random picks come from the directory', () {
      final random = Random(7);
      for (var i = 0; i < 30; i++) {
        expect(
          WebSiteCatalog.directory.contains(WebSiteCatalog.random(random)),
          isTrue,
        );
      }
    });
  });

  group('RetroWeb browser', () {
    testWidgets('portal opens a site, counts pages, and goes back', (
      tester,
    ) async {
      final visited = <int>[];
      await _pumpBrowser(tester, onPagesVisited: visited.add);

      expect(find.text('The small web, hand-indexed.'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);

      await tester.tap(find.text('The Harbor Herald'));
      await tester.pump();

      expect(
        find.text('Ferry strike ends with a handshake and free coffee'),
        findsOneWidget,
      );
      expect(visited, [1]);
      expect(find.text('1 page visited'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();
      expect(find.text('The small web, hand-indexed.'), findsOneWidget);
    });

    testWidgets('directory filters by category and opens a site', (
      tester,
    ) async {
      await _pumpBrowser(tester);

      await tester.tap(find.byIcon(Icons.grid_view_rounded).first);
      await tester.pump();
      expect(find.text('The directory · 100 sites'), findsOneWidget);

      await tester.tap(find.text('Tech 9').last);
      await tester.pump();
      expect(find.text('The directory · 9 sites'), findsOneWidget);

      await tester.tap(find.text('Silicon Sand').last);
      await tester.pump();
      expect(
        find.text('The \$12 router that thinks it is a server'),
        findsOneWidget,
      );
    });

    testWidgets('address search opens a quiz and answers a question', (
      tester,
    ) async {
      await _pumpBrowser(tester);

      await tester.tap(find.byKey(const ValueKey('retroweb_address')));
      await tester.pump();
      expect(find.text('Search the directory'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('retroweb_search_field')),
        'quiz jar',
      );
      await tester.pump();
      expect(find.text('The Quiz Jar'), findsWidgets);

      await tester.tap(find.text('Open first result'));
      await tester.pump();

      expect(find.text('The general knowledge jar, shaken'), findsOneWidget);

      await tester.tap(find.text('Pacific'));
      await tester.pump();
      expect(find.text('Score 1'), findsOneWidget);
      expect(find.textContaining('The Pacific covers'), findsWidgets);
      expect(find.textContaining('Correct.'), findsWidgets);
    });

    testWidgets('dragging moves the cursor, a tap clicks under it', (
      tester,
    ) async {
      await _pumpBrowser(tester);

      final cursor = find.byKey(const ValueKey('retroweb_cursor'));
      expect(cursor, findsOneWidget);
      final before = tester.getTopLeft(cursor);

      await tester.dragFrom(
        const Offset(480, 320),
        const Offset(90, 24),
        touchSlopX: 0,
        touchSlopY: 0,
      );
      await tester.pump();

      final after = tester.getTopLeft(cursor);
      expect(after.dx - before.dx, closeTo(90, 4));
      expect(after.dy - before.dy, closeTo(24, 4));
    });

    testWidgets('dragging on a page moves the cursor without scrolling', (
      tester,
    ) async {
      await _pumpBrowser(tester);
      await tester.tap(find.text('The Harbor Herald'));
      await tester.pump();

      final cursor = find.byKey(const ValueKey('retroweb_cursor'));
      final before = tester.getTopLeft(cursor);
      final masthead = find.text('The Harbor Herald').first;
      final mastheadTop = tester.getTopLeft(masthead);

      await tester.dragFrom(
        const Offset(480, 360),
        const Offset(0, -150),
        touchSlopX: 0,
        touchSlopY: 0,
      );
      await tester.pump();

      expect(tester.getTopLeft(cursor).dy - before.dy, closeTo(-150, 4));
      expect(tester.getTopLeft(masthead), mastheadTop);
    });

    testWidgets('the corner joystick steers the cursor without clicking', (
      tester,
    ) async {
      await _pumpBrowser(tester);

      final cursor = find.byKey(const ValueKey('retroweb_cursor'));
      final base = find.byKey(const ValueKey('retroweb_stick_base'));
      final knob = find.byKey(const ValueKey('retroweb_stick_knob'));
      expect(base, findsOneWidget);
      expect(knob, findsOneWidget);
      final before = tester.getTopLeft(cursor);
      final center = tester.getCenter(base);

      // The stick lives in the lower-right corner, clear of the scroll rail.
      final screen = tester.getSize(find.byType(RetroBrowser));
      expect(center.dx, greaterThan(screen.width * 0.85));
      expect(center.dy, greaterThan(screen.height * 0.75));

      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.moveTo(center + const Offset(0, -26));
      await tester.pump();
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();

      final after = tester.getTopLeft(cursor);
      expect(after.dy, lessThan(before.dy - 30));
      expect(after.dx, closeTo(before.dx, 6));
      // A stick press is not a click: the portal is still on screen.
      expect(find.text('The small web, hand-indexed.'), findsOneWidget);
      // Releasing recentres the knob.
      expect(tester.getCenter(knob), center);

      // Steering down and right steers the same way on screen.
      final down = await tester.startGesture(center);
      await tester.pump();
      await down.moveTo(center + const Offset(26, 26));
      await tester.pump();
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await down.up();
      await tester.pump();

      final steered = tester.getTopLeft(cursor);
      expect(steered.dy, greaterThan(after.dy + 20));
      expect(steered.dx, greaterThan(after.dx + 20));
    });

    testWidgets('bookmarking from the toolbar fills the bookmark list', (
      tester,
    ) async {
      await _pumpBrowser(tester);
      await tester.tap(find.text('The Harbor Herald'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.bookmark_border_rounded).first);
      await tester.pump();
      expect(find.byIcon(Icons.bookmark_rounded), findsWidgets);

      await tester.tap(find.byIcon(Icons.bookmarks_rounded).first);
      await tester.pump();
      expect(find.text('Bookmarks · 1'), findsOneWidget);
      expect(find.textContaining('The Harbor Herald'), findsWidgets);
    });

    testWidgets('surprise opens a valid directory site', (tester) async {
      final visited = <int>[];
      await _pumpBrowser(tester, onPagesVisited: visited.add);

      await tester.tap(find.byIcon(Icons.casino_rounded).first);
      await tester.pump();

      expect(visited, hasLength(1));
      expect(find.text('100 sites'), findsOneWidget);
      // The portal is gone, so a destination masthead is showing.
      expect(find.text('The small web, hand-indexed.'), findsNothing);
    });

    testWidgets('fits a compact 850x393 television without overflowing', (
      tester,
    ) async {
      await _pumpBrowser(tester, size: const Size(850, 393));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('The Harbor Herald'));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.grid_view_rounded).first);
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('retroweb_address')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('RetroWeb site templates', () {
    testWidgets('every layout renders its lead story at 850x393', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(850, 393);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = WebCursorController();
      final scroll = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(scroll.dispose);

      for (final site in WebSiteCatalog.directory) {
        await tester.pumpWidget(
          WebCursorScope(
            controller: controller,
            child: MaterialApp(
              home: Scaffold(
                backgroundColor: webInk,
                body: RetroSitePage(
                  site: site,
                  scrollController: scroll,
                  onOpenSite: (_) {},
                  onToast: (_) {},
                  isBookmarked: false,
                  onToggleBookmark: () {},
                  onOpenDirectory: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.text(site.headline),
          findsWidgets,
          reason: 'headline missing for ${site.id}',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'layout overflow on ${site.id}',
        );
      }
    });
  });
}

Future<void> _pumpBrowser(
  WidgetTester tester, {
  Size size = const Size(1000, 600),
  ValueChanged<int>? onPagesVisited,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: RetroBrowser(onExit: () {}, onPagesVisited: onPagesVisited),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}
