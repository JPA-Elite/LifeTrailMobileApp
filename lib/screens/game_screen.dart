import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/life_game.dart';
import '../game/state/game_state.dart';
import '../game/world/interactable.dart';
import '../services/game_data_service.dart';
import '../services/save_service.dart';
import '../services/audio_service.dart';
import '../widgets/game_hud.dart';
import '../widgets/action_buttons.dart';
import '../widgets/dialogue_box.dart';
import '../models/location_dialogue.dart';
import '../models/quest_model.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  LifeGame? _game;
  Interactable? _nearest;
  bool _running = false;
  String _message = '';
  DialogueNode? _dialogue;
  String? _dialogueNpcId;
  String? _locationSheet;
  final _save = PrefsSaveService();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await GameDataService().loadAll();
    final gs = ref.read(gameStateProvider);
    if (!gs.isLoaded) {
      gs.loadSnapshot(
        player: gs.player,
        time: gs.time,
        npcs: Map.of(GameDataService().npcs),
        quests: Map.of(GameDataService().quests),
        flags: {},
        inventory: [],
      );
    }
    _game = LifeGame(
      onNearestChanged: (n) => setState(() => _nearest = n),
      onEnterLocation: (id) => setState(() => _locationSheet = id),
      onTalkTo: _talkTo,
      onMessage: (m) => setState(() => _message = m),
    );
    setState(() {});
    _refreshNpcMarkers();
  }

  void _refreshNpcMarkers() {
    final gs = ref.read(gameStateProvider);
    final positions = <String, Vector2>{
      'alex': Vector2(1500, 850),
      'maria': Vector2(1650, 850),
      'ben': Vector2(1600, 1600),
    };
    _game?.spawnNpcMarkers(positions, {
      for (final e in gs.npcs.entries) e.key: e.value.name,
    });
  }

  void _talkTo(String npcId) {
    final gs = ref.read(gameStateProvider);
    final data = GameDataService();
    final npc = gs.npcs[npcId];
    if (npc == null) return;
    AudioService().interact();
    gs.applyActivity('talk');
    gs.adjustRelationship(npcId, 1);
    if (npcId == 'maria') {
      gs.startQuest('missing_wallet');
      gs.completeObjective('missing_wallet', 'talk_maria');
    }
    gs.setFlag('met_$npcId');
    final nodes = data.dialogues[npc.dialogueId] ?? [];
    if (nodes.isEmpty) {
      setState(() => _message = '${npc.name}: Hello!');
      return;
    }
    setState(() {
      _dialogueNpcId = npcId;
      _dialogue = nodes.firstWhere(
        (n) => n.id == 'start',
        orElse: () => nodes.first,
      );
    });
  }

  void _advanceDialogue() {
    final data = GameDataService();
    if (_dialogue == null || _dialogueNpcId == null) return;
    if (_dialogue!.next == null) {
      setState(() => _dialogue = null);
      return;
    }
    final nodes = data.dialogues[_dialogueNpcId!] ?? [];
    final next = nodes.where((n) => n.id == _dialogue!.next);
    setState(() => _dialogue = next.isEmpty ? null : next.first);
  }

  void _choose(DialogueChoice choice) {
    final gs = ref.read(gameStateProvider);
    if (choice.effects['relationship'] != null && _dialogueNpcId != null) {
      gs.adjustRelationship(_dialogueNpcId!, choice.effects['relationship']!);
    }
    if (choice.setFlag != null) gs.setFlag(choice.setFlag!);
    final data = GameDataService();
    if (choice.next == null) {
      setState(() => _dialogue = null);
      return;
    }
    final nodes = data.dialogues[_dialogueNpcId!] ?? [];
    final next = nodes.where((n) => n.id == choice.next);
    setState(() => _dialogue = next.isEmpty ? null : next.first);
  }

  Future<void> _quickSave() async {
    final gs = ref.read(gameStateProvider);
    final snap = gs.snapshot();
    await _save.saveGame(
      'slot1',
      buildSaveData(
        player: snap.player,
        time: snap.time,
        npcs: snap.npcs,
        quests: snap.quests,
        flags: snap.flags,
        inventory: snap.inventory,
        weather: snap.weather,
        chapter: snap.chapter,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Game saved (Slot 1)')));
    }
  }

  double _nightAlpha() {
    final gs = ref.watch(gameStateProvider);
    final h = gs.time.hour;
    if (h >= 6 && h < 17) return 0.0;
    if (h >= 17 && h < 19) return 0.15;
    if (h >= 19 || h < 5) return 0.42;
    return 0.05;
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameStateProvider);
    _game?.setNightAlpha(_nightAlpha());
    _game?.setRunning(_running);

    return Scaffold(
      body: Stack(
        children: [
          if (_game != null)
            Positioned.fill(child: GameWidget(game: _game!))
          else
            const Center(child: CircularProgressIndicator()),
          const GameHud(),
          ActionButtons(
            interactLabel: _nearest?.interactLabel,
            onInteract: () => _game?.interactNearest(),
            onPhone: () => _openPhone(),
            running: _running,
            onRunChanged: (v) => setState(() => _running = v),
          ),
          if (_message.isNotEmpty)
            Positioned(
              top: 90,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _message = ''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          if (_dialogue != null)
            DialogueBox(
              node: _dialogue!,
              onChoice: _choose,
              onNext: _advanceDialogue,
              onClose: () => setState(() => _dialogue = null),
            ),
          if (_locationSheet != null)
            _LocationPanel(
              locationId: _locationSheet!,
              onClose: () => setState(() => _locationSheet = null),
              onMessage: (m) => setState(() => _message = m),
            ),
          Positioned(
            left: 12,
            bottom: 12,
            child: SafeArea(
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _quickSave,
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Save'),
                  ),
                  const SizedBox(width: 6),
                  if (gs.isExhausted)
                    const Chip(
                      label: Text(
                        'Exhausted! Eat or sleep',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPhone() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _PhoneSheet(),
    );
  }
}

class _LocationPanel extends ConsumerWidget {
  final String locationId;
  final VoidCallback onClose;
  final void Function(String) onMessage;

  const _LocationPanel({
    required this.locationId,
    required this.onClose,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(gameStateProvider);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 340,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    _title(locationId),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
                ],
              ),
              Text(
                'Day ${gs.time.day} · ${gs.time.clockLabel} · Energy ${gs.player.energy}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              ..._actions(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  String _title(String id) {
    switch (id) {
      case 'home':
        return 'Home';
      case 'school':
        return 'School';
      case 'plaza':
        return 'Plaza';
      case 'church':
        return 'Church';
      case 'park':
        return 'Park';
      case 'workplace':
        return 'Sunbeam Café';
      default:
        return id;
    }
  }

  List<Widget> _actions(BuildContext context, WidgetRef ref) {
    final gs = ref.read(gameStateProvider);
    Widget btn(String label, VoidCallback fn, {bool enabled = true}) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: ElevatedButton(onPressed: enabled ? fn : null, child: Text(label)),
    );

    switch (locationId) {
      case 'home':
        return [
          btn('Eat breakfast (+10 energy, 30m)', () {
            gs.eatMeal();
            onMessage('You ate a warm meal. Energy restored a little.');
          }),
          btn('Study (+Edu, 60m)', () {
            gs.study();
            onMessage('You studied. Education +2.');
          }),
          btn('Rest (+20 energy, 30m)', () => gs.applyActivity('rest')),
          btn('Sleep → next day (saves)', () {
            AudioService().sleep();
            gs.sleep();
            onMessage('Day ${gs.time.day} begins. Energy restored.');
            onClose();
          }),
        ];
      case 'school':
        final quiz = GameDataService().quizBySubject['mathematics'] ?? [];
        return [
          Text(
            'Attendance: ${(gs.player.attendanceRate * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12),
          ),
          btn('Attend class (90m)', () {
            gs.attendClass(present: true);
            onMessage('Class finished. Education +2.');
          }),
          btn('Take quiz (${quiz.length} questions)', () {
            onClose();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const QuizScreen(subject: 'mathematics'),
              ),
            );
          }),
          btn('Skip class (warning!)', () {
            gs.attendClass(present: false);
            onMessage('You skipped class. A warning was recorded.');
          }),
        ];
      case 'plaza':
        return [
          btn('Look for Maria\'s wallet', () {
            if (gs.quests['missing_wallet']?.status == QuestStatus.active) {
              gs.completeObjective('missing_wallet', 'search_plaza');
              gs.addItem('wallet_maria', 1);
              onMessage('You found a brown wallet near the benches!');
            } else {
              onMessage('The plaza is lively. Vendors and students pass by.');
              gs.applyActivity('walk');
            }
          }),
          btn('Ask vendor about wallet', () {
            gs.completeObjective('missing_wallet', 'talk_vendor');
            onMessage('Vendor: "Yes! Someone left a wallet here."');
          }),
          btn('Return wallet to Maria', () {
            if (gs.snapshot().inventory.any(
              (e) => e.itemId == 'wallet_maria',
            )) {
              gs.removeItem('wallet_maria', 1);
              gs.completeObjective('missing_wallet', 'return_wallet');
              AudioService().coins();
              onMessage('Maria is delighted! +₱200, relationship up.');
            } else {
              onMessage('You do not have the wallet yet.');
            }
          }),
          btn('Buy bread ₱25', () {
            final r = gs.removeMoney(25);
            if (r.ok) {
              gs.addItem('bread', 1);
              onMessage('Bought bread. Check inventory to eat it.');
            } else {
              onMessage('Not enough money.');
            }
          }),
        ];
      case 'church':
        return [
          btn('Attend service (90m)', () {
            gs.applyActivity('church');
            gs.setFlag('visited_church');
            onMessage('A calm community service. You feel welcome.');
          }),
          btn('Volunteer (+relationship)', () {
            gs.applyActivity('church');
            gs.adjustRelationship('maria', 2);
            onMessage('You helped set up chairs. Maria appreciates it.');
          }),
        ];
      case 'park':
        return [
          btn('Exercise (60m)', () {
            gs.applyActivity('exercise');
            onMessage('You jogged around the park.');
          }),
          btn('Relax (30m)', () => gs.applyActivity('rest')),
        ];
      case 'workplace':
        return [
          Text(
            'Shift: 17:00–20:00 · Salary ₱300',
            style: const TextStyle(fontSize: 12),
          ),
          btn('Start café shift (mini-game)', () {
            onClose();
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CafeGameScreen()));
          }),
        ];
      default:
        return [btn('Look around', () => gs.applyActivity('walk'))];
    }
  }
}

class _PhoneSheet extends ConsumerWidget {
  const _PhoneSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(gameStateProvider);
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PHONE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Day ${gs.time.day} · ${gs.time.weekdayLabel} ${gs.time.clockLabel} · ${gs.pesoBalance}',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                children: [
                  _tile(
                    context,
                    Icons.chat,
                    'Messages',
                    () => _info(
                      context,
                      ref,
                      'Messages',
                      'Alex: "Are you coming to the plaza?"',
                    ),
                  ),
                  _tile(
                    context,
                    Icons.people,
                    'Contacts',
                    () => _info(
                      context,
                      ref,
                      'Contacts',
                      gs.npcs.values
                          .map((n) => '${n.name} (${n.relationship})')
                          .join('\n'),
                    ),
                  ),
                  _tile(
                    context,
                    Icons.calendar_month,
                    'Calendar',
                    () => _info(
                      context,
                      ref,
                      'Calendar',
                      'Mon–Fri: School\nSun: Church 10:00\nCafé shifts 17:00–20:00',
                    ),
                  ),
                  _tile(
                    context,
                    Icons.map,
                    'Map',
                    () => _info(
                      context,
                      ref,
                      'Map',
                      'School (N) · Plaza (center) · Home (S) · Café (far S)',
                    ),
                  ),
                  _tile(
                    context,
                    Icons.wallet,
                    'Finance',
                    () => _info(
                      context,
                      ref,
                      'Finance',
                      'Balance: ${gs.pesoBalance}\nTip: work at the café.',
                    ),
                  ),
                  _tile(
                    context,
                    Icons.backpack,
                    'Quests',
                    () => _info(
                      context,
                      ref,
                      'Quests',
                      gs.quests.values
                          .map(
                            (q) =>
                                '${q.title}: ${q.status.name}\n${q.objectives.map((o) => '${o.done ? '[x]' : '[ ]'} ${o.description}').join('\n')}',
                          )
                          .join('\n\n'),
                    ),
                  ),
                  _tile(
                    context,
                    Icons.school,
                    'School',
                    () => _info(
                      context,
                      ref,
                      'School',
                      'Attendance: ${(gs.player.attendanceRate * 100).toStringAsFixed(0)}%\nEducation: ${gs.player.education}',
                    ),
                  ),
                  _tile(context, Icons.settings, 'Settings', () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/settings');
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  void _info(BuildContext context, WidgetRef ref, String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class QuizScreen extends ConsumerStatefulWidget {
  final String subject;
  const QuizScreen({super.key, required this.subject});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameStateProvider);
    final questions = GameDataService().quizBySubject[widget.subject] ?? [];
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No questions yet.')),
      );
    }
    final q = questions[_index % questions.length];
    final choices = (q['choices'] as List).cast<String>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.subject} quiz')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    q['q'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(choices.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          final correct = i == (q['answer'] as int);
                          if (correct) {
                            gs.attendClass(present: true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Correct! Education +2'),
                              ),
                            );
                          } else {
                            gs.applyActivity('class');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Not quite. Try again!'),
                              ),
                            );
                          }
                          setState(() => _index++);
                          if (_index >= questions.length) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(choices[i]),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CafeGameScreen extends ConsumerStatefulWidget {
  const CafeGameScreen({super.key});

  @override
  ConsumerState<CafeGameScreen> createState() => _CafeGameState();
}

class _CafeGameState extends ConsumerState<CafeGameScreen> {
  final _orders = ['Coffee', 'Bread', 'Coffee + Bread', 'Juice'];
  int _customer = 0;
  int _score = 0;
  static const int _total = 5;

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameStateProvider);
    if (_customer >= _total) {
      final ratio = _score / _total;
      final pay = ratio >= 0.9
          ? 300
          : ratio >= 0.6
          ? 270
          : 210;
      return Scaffold(
        appBar: AppBar(title: const Text('Shift complete')),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Score: $_score/$_total',
                    style: const TextStyle(fontSize: 20),
                  ),
                  Text(
                    'Pay: ₱$pay',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      gs.applyActivity('work');
                      gs.addMoney(pay);
                      gs.setFlag('worked_first_shift');
                      AudioService().coins();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Finish shift'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final order = _orders[_customer % _orders.length];
    return Scaffold(
      appBar: AppBar(
        title: Text('Café shift ${_customer + 1}/$_total · Score $_score'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Customer ${_customer + 1} orders:',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    order,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: ['Coffee', 'Bread', 'Juice', 'Coffee + Bread']
                        .map(
                          (choice) => ElevatedButton(
                            onPressed: () {
                              if (choice == order) _score++;
                              setState(() => _customer++);
                            },
                            child: Text(choice),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
