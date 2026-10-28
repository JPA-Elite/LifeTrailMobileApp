import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/game/state/game_state.dart';
import 'package:lifetrail/game/state/phone_state.dart';
import 'package:lifetrail/models/game_time.dart';
import 'package:lifetrail/models/npc_model.dart';
import 'package:lifetrail/models/player_model.dart';
import 'package:lifetrail/screens/phone/contacts_app.dart';
import 'package:lifetrail/screens/phone/finance_app.dart';
import 'package:lifetrail/screens/phone/messages_app.dart';
import 'package:lifetrail/screens/phone/school_app.dart';

const _npcs = {
  'alex': NpcModel(
    id: 'alex',
    name: 'Alex',
    age: 16,
    personality: 'cheerful',
    relationship: 24,
    schedule: [
      ScheduleEntry(
        weekday: 'any',
        start: '08:00',
        end: '15:30',
        location: 'school',
      ),
      ScheduleEntry(
        weekday: 'any',
        start: '15:30',
        end: '18:00',
        location: 'plaza',
      ),
    ],
  ),
  'maria': NpcModel(
    id: 'maria',
    name: 'Maria',
    age: 17,
    personality: 'kind',
    relationship: 12,
    schedule: [
      ScheduleEntry(
        weekday: 'any',
        start: '07:00',
        end: '15:00',
        location: 'plaza',
      ),
    ],
  ),
  'ben': NpcModel(
    id: 'ben',
    name: 'Ben',
    age: 18,
    personality: 'calm',
    relationship: 8,
    schedule: [
      ScheduleEntry(
        weekday: 'any',
        start: '09:00',
        end: '15:00',
        location: 'school',
      ),
    ],
  ),
};

GameState _state() {
  final gs = GameState();
  gs.loadSnapshot(
    player: const PlayerModel(
      money: 1250,
      education: 20,
      intelligence: 14,
      attendanceTaken: 10,
      attendancePresent: 9,
    ),
    time: const GameTime(day: 1, minutes: 8 * 60 + 30),
    npcs: _npcs,
    quests: {},
    flags: {},
    inventory: [],
  );
  return gs;
}

Widget _host(
  Widget child, {
  required GameState game,
  PhoneState? phone,
  FinanceState? finance,
}) {
  final phoneState = phone ?? PhoneState(replyDelay: Duration.zero);
  if (phone == null) {
    phoneState.seed(game.npcs, now: game.time);
  }
  return ProviderScope(
    overrides: [
      gameStateProvider.overrideWith((ref) => game),
      phoneStateProvider.overrideWith((ref) => phoneState),
      financeStateProvider.overrideWith((ref) => finance ?? FinanceState()),
    ],
    child: MaterialApp(home: child),
  );
}

void _useTallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('phone data', () {
    test('seeding creates a contact and a thread for every NPC', () {
      final phone = PhoneState(replyDelay: Duration.zero);
      phone.seed(_npcs, now: const GameTime(day: 1, minutes: 600));

      expect(phone.contacts.map((c) => c.name), containsAll(['Alex', 'Maria', 'Ben']));
      expect(phone.inbox, hasLength(3));
      expect(phone.totalUnread, 3);
      expect(phone.messagesOf('alex'), isNotEmpty);
      expect(phone.messagesOf('alex').last.fromMe, isFalse);
      expect(phone.contact('alex')!.phone, contains('+63'));
    });

    test('sending a message earns a reply and an unread badge', () async {
      final phone = PhoneState(replyDelay: Duration.zero);
      phone.seed(_npcs, now: const GameTime(day: 1, minutes: 600));
      phone.markRead('alex');

      phone.sendMessage(
        'alex',
        'see you at the plaza?',
        clockLabel: '16:05',
        day: 1,
      );
      expect(phone.messagesOf('alex').last.fromMe, isTrue);
      expect(phone.messagesOf('alex').last.text, 'see you at the plaza?');
      expect(phone.isTyping('alex'), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(phone.isTyping('alex'), isFalse);
      expect(phone.messagesOf('alex').last.fromMe, isFalse);
      expect(phone.unreadOf('alex'), 1);
    });

    test('a reply arriving while the chat is open is not unread', () async {
      final phone = PhoneState(replyDelay: Duration.zero);
      phone.seed(_npcs, now: const GameTime(day: 1, minutes: 600));
      phone.setActiveContact('alex');
      phone.markRead('alex');

      phone.sendMessage(
        'alex',
        'hello!',
        clockLabel: '16:05',
        day: 1,
      );
      await Future<void>.delayed(Duration.zero);
      expect(phone.unreadOf('alex'), 0);
    });

    test('favourites sort to the top and survive toggling', () {
      final phone = PhoneState();
      phone.seed(_npcs, now: const GameTime(day: 1, minutes: 600));
      phone.toggleFavorite('maria');
      expect(phone.contacts.first.name, 'Maria');
      expect(phone.contact('maria')!.favorite, isTrue);
      phone.toggleFavorite('maria');
      expect(phone.contact('maria')!.favorite, isFalse);
    });
  });

  group('finance session', () {
    test('rejects a wrong mobile or PIN and accepts the demo login', () {
      final finance = FinanceState();
      expect(finance.login('0917 000 0000', FinanceState.demoPin), isFalse);
      expect(finance.error, isNotNull);
      expect(finance.login(FinanceState.demoMobile, '000000'), isFalse);
      expect(finance.loggedIn, isFalse);

      expect(finance.login(FinanceState.demoMobile, FinanceState.demoPin), isTrue);
      expect(finance.loggedIn, isTrue);
      expect(finance.error, isNull);
    });

    test('reset requires identity verification, then swaps the PIN', () {
      final finance = FinanceState();
      expect(
        finance.resetPin(pin: '654321', confirm: '654321'),
        isFalse,
        reason: 'identity must be verified first',
      );

      expect(
        finance.verifyIdentity(
          mobile: FinanceState.demoMobile,
          birthday: '01/01/2000',
        ),
        isFalse,
      );
      expect(
        finance.verifyIdentity(
          mobile: FinanceState.demoMobile,
          birthday: FinanceState.demoBirthday,
        ),
        isTrue,
      );

      expect(finance.resetPin(pin: '123', confirm: '123'), isFalse);
      expect(finance.resetPin(pin: '654321', confirm: '111111'), isFalse);
      expect(finance.resetPin(pin: '654321', confirm: '654321'), isTrue);
      expect(finance.usesDemoPin, isFalse);

      expect(finance.login(FinanceState.demoMobile, FinanceState.demoPin), isFalse);
      expect(finance.login(FinanceState.demoMobile, '654321'), isTrue);
    });
  });

  group('finance app', () {
    testWidgets('signs in and shows a locked, view-only balance', (tester) async {
      _useTallPhone(tester);
      await tester.pumpWidget(_host(const FinanceApp(), game: _state()));

      expect(find.text('LifeTrail Bank'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), FinanceState.demoMobile);
      await tester.enterText(fields.at(1), FinanceState.demoPin);
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Finance'), findsOneWidget);
      expect(find.textContaining('1,250'), findsOneWidget);
      expect(find.text('View only'), findsOneWidget);
      expect(find.text('Deposit'), findsOneWidget);
      expect(find.text('Withdraw'), findsOneWidget);

      await tester.tap(find.text('Withdraw'));
      await tester.pump();
      expect(
        find.textContaining('disabled on this view-only student account'),
        findsOneWidget,
      );
    });

    testWidgets('resets the PIN from the forgot password flow', (tester) async {
      _useTallPhone(tester);
      final finance = FinanceState();
      await tester.pumpWidget(
        _host(const FinanceApp(), game: _state(), finance: finance),
      );

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Verify it’s you'), findsOneWidget);

      var fields = find.byType(TextField);
      await tester.enterText(fields.at(0), FinanceState.demoMobile);
      await tester.enterText(fields.at(1), FinanceState.demoBirthday);
      await tester.tap(find.text('Verify identity'));
      await tester.pumpAndSettle();

      fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '654321');
      await tester.enterText(fields.at(1), '654321');
      await tester.tap(find.text('Save new PIN'));
      await tester.pumpAndSettle();

      expect(find.text('PIN updated'), findsOneWidget);
      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();
      expect(find.text('LifeTrail Bank'), findsOneWidget);
      expect(finance.usesDemoPin, isFalse);
    });
  });

  group('school app', () {
    testWidgets('shows the live timetable, grades, attendance and notices', (
      tester,
    ) async {
      _useTallPhone(tester);
      await tester.pumpWidget(_host(const SchoolApp(), game: _state()));

      expect(find.text('Riverside High'), findsOneWidget);
      expect(find.text('Grade 10 · Section A'), findsOneWidget);
      expect(find.text('Mathematics'), findsWidgets);
      expect(find.textContaining('Campus open'), findsOneWidget);

      await tester.tap(find.text('Grades'));
      await tester.pumpAndSettle();
      expect(find.text('General average'), findsOneWidget);
      expect(find.text('Science'), findsWidgets);

      await tester.tap(find.text('Attendance'));
      await tester.pumpAndSettle();
      expect(find.text('This quarter'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Good standing'), findsOneWidget);

      await tester.tap(find.text('Notices'));
      await tester.pumpAndSettle();
      expect(find.text('Science fair sign-ups open'), findsOneWidget);
    });
  });

  group('messages and contacts', () {
    testWidgets('opens a thread, sends a message and receives a reply', (
      tester,
    ) async {
      _useTallPhone(tester);
      final game = _state();
      final phone = PhoneState(replyDelay: Duration.zero);
      phone.seed(game.npcs, now: game.time);

      await tester.pumpWidget(
        _host(const MessagesApp(), game: game, phone: phone),
      );
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);

      await tester.tap(find.text('Alex'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'plaza at 4?');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      expect(find.text('plaza at 4?'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('haha yes! 😄'), findsOneWidget);
    });

    testWidgets('contact details show schedule and can be favourited', (
      tester,
    ) async {
      _useTallPhone(tester);
      final game = _state();
      final phone = PhoneState(replyDelay: Duration.zero);
      phone.seed(game.npcs, now: game.time);

      await tester.pumpWidget(
        _host(const ContactsApp(), game: game, phone: phone),
      );
      expect(find.text('Contacts'), findsOneWidget);
      expect(find.text('3 people · 0 favourite'), findsOneWidget);

      await tester.tap(find.text('Alex'));
      await tester.pumpAndSettle();
      expect(find.text("TODAY'S SCHEDULE"), findsOneWidget);
      expect(find.text('School'), findsWidgets);
      expect(find.textContaining('+63'), findsOneWidget);

      await tester.tap(find.byTooltip('Add favourite'));
      await tester.pump();
      expect(phone.contact('alex')!.favorite, isTrue);
    });
  });
}
