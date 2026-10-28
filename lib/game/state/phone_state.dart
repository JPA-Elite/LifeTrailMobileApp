import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/game_time.dart';
import '../../models/npc_model.dart';

/// Session-wide phone data: the contact book, every message thread and the
/// unread/typing state. Kept outside the widget tree so closing and
/// reopening the phone never loses a conversation.
final phoneStateProvider = ChangeNotifierProvider<PhoneState>(
  (ref) => PhoneState(),
);

/// Session-wide bank app state. Login, identity verification and PIN
/// changes live here so the Finance app keeps its session while closed.
final financeStateProvider = ChangeNotifierProvider<FinanceState>(
  (ref) => FinanceState(),
);

/// One person in the phone's contact book.
class PhoneContact {
  PhoneContact({
    required this.id,
    required this.name,
    required this.age,
    required this.personality,
    required this.phone,
    this.favorite = false,
  });

  final String id;
  final String name;
  final int age;
  final String personality;
  final String phone;
  bool favorite;
}

/// One chat bubble. [day] is the in-game day so threads can show dates.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.fromMe,
    required this.clock,
    required this.day,
  });

  final String text;
  final bool fromMe;
  final String clock;
  final int day;
}

/// Contact book + text messenger for the in-game phone.
///
/// Threads are seeded from the town's NPC roster (names, ages and
/// personalities come from `npcs.json`), and every message the player sends
/// earns a short, personality-appropriate reply after [replyDelay].
class PhoneState extends ChangeNotifier {
  PhoneState({this.replyDelay = const Duration(milliseconds: 1600)});

  /// How long a friend "types" before their reply lands. Tests pass
  /// [Duration.zero].
  final Duration replyDelay;

  final Map<String, PhoneContact> _contacts = {};
  final Map<String, List<ChatMessage>> _threads = {};
  final Map<String, int> _unread = {};
  final Set<String> _typing = {};
  final Map<String, int> _activity = {};
  final Map<String, Timer> _replyTimers = {};

  int _clock = 0;
  String? _activeContactId;

  /// Contacts with an existing conversation, newest activity first.
  List<PhoneContact> get inbox {
    final out = _contacts.values
        .where((c) => (_threads[c.id] ?? const []).isNotEmpty)
        .toList();
    out.sort((a, b) {
      final diff = (_activity[b.id] ?? 0) - (_activity[a.id] ?? 0);
      if (diff != 0) return diff;
      return a.name.compareTo(b.name);
    });
    return out;
  }

  /// Full contact book: favourites first, then alphabetical.
  List<PhoneContact> get contacts {
    final out = _contacts.values.toList();
    out.sort((a, b) {
      if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return out;
  }

  bool get isEmpty => _contacts.isEmpty;

  int get totalUnread => _unread.values.fold(0, (a, b) => a + b);

  PhoneContact? contact(String id) => _contacts[id];

  List<ChatMessage> messagesOf(String id) =>
      List.unmodifiable(_threads[id] ?? const []);

  ChatMessage? lastMessageOf(String id) {
    final thread = _threads[id];
    if (thread == null || thread.isEmpty) return null;
    return thread.last;
  }

  int unreadOf(String id) => _unread[id] ?? 0;

  bool isTyping(String id) => _typing.contains(id);

  bool hasThread(String id) => (_threads[id] ?? const []).isNotEmpty;

  /// Called when the phone opens: creates a contact and a seeded
  /// conversation for every NPC that does not have one yet. Safe to call
  /// repeatedly as the roster grows.
  void seed(
    Map<String, NpcModel> npcs, {
    required GameTime now,
  }) {
    var changed = false;
    for (final npc in npcs.values) {
      if (_contacts.containsKey(npc.id)) continue;
      _contacts[npc.id] = PhoneContact(
        id: npc.id,
        name: npc.name,
        age: npc.age,
        personality: npc.personality,
        phone: _phoneNumber(npc.id),
      );
      final thread = _seedThreadFor(npc, now);
      _threads[npc.id] = thread;
      _unread[npc.id] = thread.isNotEmpty && !thread.last.fromMe ? 1 : 0;
      _activity[npc.id] = _clock++;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Marks a thread as read (called when the chat is opened).
  void markRead(String id) {
    if ((_unread[id] ?? 0) == 0) return;
    _unread[id] = 0;
    notifyListeners();
  }

  /// The chat screen tells the messenger which thread is on screen, so
  /// replies arriving while it is open don't count as unread.
  void setActiveContact(String? id) {
    _activeContactId = id;
    if (id != null) markRead(id);
  }

  /// Quiet counterpart to [setActiveContact] for when the chat closes.
  ///
  /// Deliberately does not notify: it runs from the chat's `dispose`, and
  /// rebuilding listeners while the tree is finalizing is not allowed. The
  /// flag only decides whether a late reply counts as unread, so nothing is
  /// rendered from it anyway.
  void clearActiveContact(String id) {
    if (_activeContactId != id) return;
    _activeContactId = null;
  }

  void toggleFavorite(String id) {
    final c = _contacts[id];
    if (c == null) return;
    c.favorite = !c.favorite;
    notifyListeners();
  }

  /// Sends [text] to [contactId] and schedules their reply.
  void sendMessage(
    String contactId,
    String text, {
    required String clockLabel,
    required int day,
  }) {
    final trimmed = text.trim();
    final contact = _contacts[contactId];
    if (trimmed.isEmpty || contact == null) return;
    final thread = _threads.putIfAbsent(contactId, () => []);
    thread.add(
      ChatMessage(
        text: trimmed,
        fromMe: true,
        clock: clockLabel,
        day: day,
      ),
    );
    _activity[contactId] = _clock++;
    notifyListeners();
    _scheduleReply(contactId);
  }

  void _scheduleReply(String contactId) {
    _replyTimers.remove(contactId)?.cancel();
    _typing.add(contactId);
    notifyListeners();

    final timer = Timer(replyDelay, () {
      _replyTimers.remove(contactId);
      final thread = _threads[contactId];
      final contact = _contacts[contactId];
      if (thread == null || contact == null) return;
      final last = thread.isNotEmpty ? thread.last : null;
      thread.add(
        ChatMessage(
          text: _replyFor(contact, thread.length),
          fromMe: false,
          clock: last?.clock ?? '07:00',
          day: last?.day ?? 1,
        ),
      );
      _typing.remove(contactId);
      _activity[contactId] = _clock++;
      if (_activeContactId != contactId) {
        _unread[contactId] = (_unread[contactId] ?? 0) + 1;
      }
      notifyListeners();
    });
    _replyTimers[contactId] = timer;
  }

  String _replyFor(PhoneContact contact, int seed) {
    final lines = switch (contact.personality.toLowerCase()) {
      'cheerful' => const [
        'haha yes! 😄',
        'omw, see you in a bit!',
        'say less. bringing snacks 😤',
        'that made my whole day tbh',
      ],
      'kind' => const [
        'aww, thank you 💛',
        'of course! let me know if you need anything.',
        'I was just thinking about you. how are you?',
        'you always know what to say 🥹',
      ],
      'calm' => const [
        'sounds good to me.',
        'no rush. I\'ll be around.',
        'cool. see you then.',
        'take your time — it\'s a slow afternoon.',
      ],
      _ => const [
        'haha for sure!',
        'yeah! what\'s up?',
        'I\'ll text you later 😊',
      ],
    };
    return lines[seed % lines.length];
  }

  List<ChatMessage> _seedThreadFor(NpcModel npc, GameTime now) {
    final seeds = switch (npc.id) {
      'alex' => const [
        (false, 'yo! plaza later? 🌳'),
        (true, 'after class, maybe around 4?'),
        (false, 'deal. bring snacks 😤'),
      ],
      'maria' => const [
        (false, 'hey! did you see my wallet? I think I dropped it near the plaza 😭'),
      ],
      'ben' => const [
        (false, 'gym at 5? I\'ll spot you.'),
      ],
      _ => const [
        (false, 'hey! how\'s your day going?'),
      ],
    };

    final messages = <ChatMessage>[];
    for (var i = 0; i < seeds.length; i++) {
      final at = now.addMinutes(-(seeds.length - i) * 11 - 3);
      messages.add(
        ChatMessage(
          text: seeds[i].$2,
          fromMe: seeds[i].$1,
          clock: at.clockLabel,
          day: at.day,
        ),
      );
    }
    return messages;
  }

  String _phoneNumber(String id) {
    final sum = id.codeUnits.fold<int>(0, (a, b) => a + b);
    return '+63 917 555 ${(1000 + sum * 37 % 9000).toString().padLeft(4, '0')}';
  }

  @override
  void dispose() {
    for (final timer in _replyTimers.values) {
      timer.cancel();
    }
    _replyTimers.clear();
    super.dispose();
  }
}

/// A tiny fake-but-believable student savings account.
///
/// The account is view-only by design: there are no methods to deposit or
/// withdraw here, so the dashboard cannot move money even by accident.
class FinanceState extends ChangeNotifier {
  static const String demoMobile = '0917 555 0142';
  static const String demoBirthday = '03/14/2008';
  static const String demoPin = '112233';
  static const String accountNumber = 'LT-2069-0417';
  static const String accountHolder = 'LifeTrail Student';
  static const String branch = 'Riverside Branch';

  String _pin = demoPin;
  bool _loggedIn = false;
  bool _verified = false;
  String? _error;

  bool get loggedIn => _loggedIn;
  bool get verified => _verified;
  String? get error => _error;

  /// True while the account still uses the demo PIN. The login card only
  /// shows the demo credentials until the player resets it.
  bool get usesDemoPin => _pin == demoPin;

  bool login(String mobile, String pin) {
    if (_digits(mobile) != _digits(demoMobile) || pin != _pin) {
      _error = 'Mobile number or PIN is incorrect.';
      notifyListeners();
      return false;
    }
    _error = null;
    _loggedIn = true;
    _verified = false;
    notifyListeners();
    return true;
  }

  /// Step one of "Forgot password?" — matches the mobile number and the
  /// birthday on file.
  bool verifyIdentity({
    required String mobile,
    required String birthday,
  }) {
    if (_digits(mobile) != _digits(demoMobile) ||
        birthday.trim() != demoBirthday) {
      _error = 'That mobile number and birthday do not match our records.';
      notifyListeners();
      return false;
    }
    _error = null;
    _verified = true;
    notifyListeners();
    return true;
  }

  /// Step two of "Forgot password?" — only available after a successful
  /// [verifyIdentity].
  bool resetPin({required String pin, required String confirm}) {
    if (!_verified) {
      _error = 'Verify your identity first.';
      notifyListeners();
      return false;
    }
    if (pin.length != 6 || int.tryParse(pin) == null) {
      _error = 'Choose a 6-digit numeric PIN.';
      notifyListeners();
      return false;
    }
    if (pin != confirm) {
      _error = 'Those PINs do not match.';
      notifyListeners();
      return false;
    }
    _pin = pin;
    _verified = false;
    _error = null;
    notifyListeners();
    return true;
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void cancelReset() {
    _verified = false;
    _error = null;
    notifyListeners();
  }

  void logout() {
    _loggedIn = false;
    _verified = false;
    _error = null;
    notifyListeners();
  }

  String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');
}
