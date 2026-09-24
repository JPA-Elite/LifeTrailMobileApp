import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/life_game.dart';
import '../game/state/game_state.dart';
import '../game/world/interactable.dart';
import '../services/game_data_service.dart';
import '../services/save_service.dart';
import '../services/audio_service.dart';
import '../game/world/map_data.dart';
import '../widgets/game_hud.dart';
import '../widgets/action_buttons.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/mini_map.dart';
import '../models/location_dialogue.dart';
import '../models/npc_model.dart';
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
  String? _error;
  final _save = PrefsSaveService();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Register schedule-sync listener once (not inside build).
    ref.listenManual<GameState>(gameStateProvider, (prev, next) {
      if (prev?.time.minutes != next.time.minutes ||
          prev?.time.day != next.time.day) {
        Future.microtask(_refreshNpcMarkers);
      }
    });
    _boot();
  }

  Future<void> _boot() async {
    try {
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
        // Walking through a door swaps the Flame world for the interior
        // scene, so close the action sheet: inside, the room's own
        // activity point opens it again.
        onEnterLocation: (id) => setState(() => _locationSheet = null),
        onOpenLocationMenu: (id) => setState(() => _locationSheet = id),
        onLeftLocation: (id) => setState(() => _locationSheet = null),
        onTalkTo: _talkTo,
        onMessage: (m) => setState(() => _message = m),
      );
      if (mounted) setState(() {});
      _waitForGameReady();
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to start game: $e');
    }
  }

  Future<void> _waitForGameReady() async {
    for (var i = 0; i < 200; i++) {
      final game = _game;
      if (!mounted) return;
      if (game != null && game.isReady) {
        _refreshNpcMarkers();
        // Trigger a rebuild in case the first frame rendered
        // while the game was still loading.
        if (mounted) setState(() {});
        return;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
    // Timed out but the GameWidget (shown unconditionally below) will
    // still finish loading on its own; refresh markers anyway.
    _refreshNpcMarkers();
  }

  void _refreshNpcMarkers() {
    final game = _game;
    if (game == null || !game.isReady) return;
    final gs = ref.read(gameStateProvider);
    // Summertime Saga: NPCs appear only where schedule says they are, and
    // they loiter by the door of that place. Positions come from the map
    // data so the markers can never drift out of sync with the town layout.
    final locCenters = <String, Vector2>{
      for (final l in buildTownLocations())
        l.id: Vector2(l.x + l.w / 2, l.doorOnTop ? l.y : l.y + l.h),
    };
    final positions = <String, Vector2>{};
    for (final e in gs.npcs.entries) {
      final loc = e.value.locationFor(gs.time.weekdayLabel, gs.time.minutes);
      final base = locCenters[loc] ?? Vector2(1600, 850);
      // small offset per NPC to avoid overlap (like Summertime Saga crowd)
      final offset = switch (e.key) {
        'alex' => Vector2(-80, -10),
        'maria' => Vector2(80, 10),
        'ben' => Vector2(0, 40),
        _ => Vector2.zero(),
      };
      positions[e.key] = base + offset;
    }
    _game?.spawnNpcMarkers(positions, {
      for (final e in gs.npcs.entries) e.key: e.value.name,
    });
  }

  void _talkTo(String npcId) {
    final gs = ref.read(gameStateProvider);
    final data = GameDataService();
    final npc = gs.npcs[npcId];
    if (npc == null) return;
    // Summertime Saga: NPC availability mirrors schedule
    final expectedLoc = npc.locationFor(gs.time.weekdayLabel, gs.time.minutes);
    // Not hard-blocking talk, but flavor if you catch them out of place
    AudioService().interact();
    if (!gs.canDoActivity('talk')) {
      setState(() => _message = 'Too tired to talk. Rest!');
      return;
    }
    gs.applyActivity('talk');
    gs.adjustRelationship(npcId, 1);
    gs.setFlag('met_$npcId');
    _syncNpcQuests(gs, npc, expectedLoc);
    final allNodes = data.dialogues[npc.dialogueId] ?? [];
    // Filter nodes by Summertime Saga gates (relationship/flags/quest)
    final nodes = allNodes
        .where(
          (n) => n.isAvailable(
            relationship: npc.relationship,
            flags: gs.flags,
            quests: gs.quests,
          ),
        )
        .toList();
    if (nodes.isEmpty) {
      setState(() => _message = '${npc.name} ($expectedLoc): Hello!');
      return;
    }
    // Prefer 'start' that is available, else first available
    final start = nodes.where((n) => n.id == 'start');
    setState(() {
      _dialogueNpcId = npcId;
      _dialogue = start.isNotEmpty ? start.first : nodes.first;
    });
  }

  /// Summertime Saga flow: talking to an NPC starts any quest of theirs that
  /// has already unlocked, then advances its location/time-gated objectives.
  ///
  /// [locationId] is where the schedule says the NPC currently is, i.e. the
  /// only place they can be talked to.
  void _syncNpcQuests(GameState gs, NpcModel npc, String locationId) {
    final now = gs.time.minutes;
    for (final id in gs.quests.keys.toList()) {
      if (gs.quests[id]?.npcId != npc.id) continue;
      if (gs.quests[id]!.status == QuestStatus.available) gs.startQuest(id);
      if (gs.quests[id]!.status != QuestStatus.active) continue;
      switch (id) {
        case 'missing_wallet':
          gs.completeObjective(id, 'talk_maria');
          break;
        case 'alex_confide':
          // "Talk to Alex at the plaza after school (15:30-18:00)"
          if (locationId == 'plaza' && now >= 15 * 60 + 30 && now < 18 * 60) {
            gs.completeObjective(id, 'talk_alex_plaza');
          }
          // "Impress Alex with your charm"
          if (gs.player.charm >= 12) gs.completeObjective(id, 'charm_check');
          // "Return when Alex trusts you"
          if (npc.relationship >= 18) gs.completeObjective(id, 'earn_trust');
          // Opens the gated [Confide] branch in alex.json.
          gs.setFlag('alex_confided_check');
          break;
        case 'gym_initiation':
          // "Talk to Ben at the café after 17:00"
          if (locationId == 'workplace' && now >= 17 * 60) {
            gs.completeObjective(id, 'talk_ben_work');
          }
          // "Reach Strength 14 at park gym"
          if (gs.player.strength >= 14) {
            gs.completeObjective(id, 'train_strength');
          }
          break;
      }
    }
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
    // Summertime Saga: choices may affect relationship + stats via effects map
    for (final e in choice.effects.entries) {
      switch (e.key) {
        case 'relationship':
          if (_dialogueNpcId != null) {
            gs.adjustRelationship(_dialogueNpcId!, e.value);
          }
          break;
        case 'charm':
          gs.addCharm(e.value);
          break;
        case 'intelligence':
          gs.addIntelligence(e.value);
          break;
        case 'strength':
          gs.addStrength(e.value);
          break;
        case 'money':
          if (e.value >= 0) {
            gs.addMoney(e.value);
          } else {
            gs.removeMoney(-e.value);
          }
          break;
        case 'happiness':
          gs.applyEnergy(0); // placeholder, happiness via applyActivity better
          break;
      }
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

  Future<void> _leaveLocation() async {
    setState(() => _locationSheet = null);
    await _game?.exitLocation();
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
    final game = _game;
    if (game != null) {
      game.setNightAlpha(_nightAlpha());
      game.setRunning(_running);
    }

    return Scaffold(
      body: Stack(
        children: [
          if (_error != null)
            Positioned.fill(
              child: Container(
                color: const Color(0xFFEFE8D5),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                ),
              ),
            )
          else if (_game != null)
            // Show the GameWidget immediately so Flame can run onLoad.
            // Gating this on `isReady` deadlocked: onLoad only runs after
            // the widget mounts, so `isReady` never became true.
            Positioned.fill(
              child: GameWidget(
                game: _game!,
                loadingBuilder: (_) => Container(
                  color: const Color(0xFFEFE8D5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorBuilder: (_, ex) => Container(
                  color: const Color(0xFFEFE8D5),
                  child: Center(child: Text('Game failed to load: $ex')),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: const Color(0xFFEFE8D5),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          GameHud(onSave: _quickSave),
          // Map of wherever the player currently is: the town, or the room
          // of the building they walked into.
          if (game != null)
            Align(
              alignment: Alignment.topRight,
              child: SafeArea(
                bottom: false,
                left: false,
                right: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 78, right: 10),
                  child: MiniMap(
                    position: game.playerMapPosition,
                    scene: game.miniMapScene,
                  ),
                ),
              ),
            ),
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
              onLeave: _leaveLocation,
              onMessage: (m) => setState(() => _message = m),
            ),
          // Balanced status chip: centered at the bottom so it never
          // overlaps the joystick (bottom-left) or action buttons
          // (bottom-right), and the screen feels symmetric.
          if (gs.isExhausted)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: SafeArea(
                  child: Chip(
                    backgroundColor: Colors.red.shade700,
                    label: const Text(
                      'Exhausted! Eat or sleep',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
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
  final VoidCallback onLeave;
  final void Function(String) onMessage;

  const _LocationPanel({
    required this.locationId,
    required this.onClose,
    required this.onLeave,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(gameStateProvider);
    final screenH = MediaQuery.of(context).size.height;
    // Full-width bottom sheet: stretches edge-to-edge so neither the
    // left nor right side looks spacious/empty on mobile.
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: screenH * 0.65),
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          // Bottom inset only: the sheet is edge-to-edge, and applying the
          // left/right system insets inside it padded just one side (phone
          // cutout) so the content looked shifted / too spacious.
          top: false,
          left: false,
          right: false,
          bottom: true,
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
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  'Day ${gs.time.day} · ${gs.time.clockLabel} · Energy ${gs.player.energy}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                ..._actions(context, ref),
                const Divider(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onLeave,
                    icon: const Icon(Icons.exit_to_app, size: 18),
                    label: Text('Leave ${_title(locationId)}'),
                  ),
                ),
              ],
            ),
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

  String _hoursLabel(String id) {
    switch (id) {
      case 'school':
        return 'Mon–Fri 08:00–15:30';
      case 'plaza':
        return 'Daily 07:00–20:00';
      case 'church':
        return 'Sun 09:00–13:00, Sat 15:00–18:00';
      case 'park':
        return 'Daily 06:00–21:00';
      case 'workplace':
        return 'Mon–Sat 17:00–20:30';
      case 'home':
        return 'Always open';
      default:
        return '—';
    }
  }

  List<Widget> _actions(BuildContext context, WidgetRef ref) {
    final gs = ref.read(gameStateProvider);
    final isOpen = gs.isLocationOpen(locationId);
    Widget btn(String label, VoidCallback fn, {bool enabled = true}) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: ElevatedButton(onPressed: enabled ? fn : null, child: Text(label)),
    );

    if (!isOpen) {
      return [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Text(
            '${_title(locationId)} is closed now.\nOpen hours: ${_hoursLabel(locationId)}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        btn('Wait 60m', () {
          gs.advanceMinutes(60);
          onMessage('Time passes... ${gs.time.clockLabel}');
        }),
        btn('Look around (outside)', () {
          gs.applyActivity('walk');
          onMessage('You wander nearby for a while.');
        }),
      ];
    }

    switch (locationId) {
      case 'home':
        return [
          btn('Eat breakfast (+10 energy, 30m)', () {
            if (!gs.canDoActivity('eat')) {
              onMessage('Too exhausted to eat? Rest first!');
              return;
            }
            gs.eatMeal();
            onMessage('You ate a warm meal. Energy +10.');
          }, enabled: gs.canDoActivity('eat')),
          btn('Study (+Int +1, Edu +1, 60m)', () {
            if (!gs.canDoActivity('study')) {
              onMessage('Too tired to study. Rest!');
              return;
            }
            gs.study();
            onMessage('You studied. Intelligence +1, Education +1.');
          }, enabled: gs.canDoActivity('study')),
          btn('Rest (+20 energy, 30m)', () {
            gs.applyActivity('rest');
            onMessage('You rested a bit.');
          }),
          btn(
            'Socialize with family (+Charm 2, 45m)',
            () {
              if (!gs.canDoActivity('socialize')) {
                onMessage('Need energy.');
                return;
              }
              gs.socialize();
              onMessage('Family chat. Charm +2.');
            },
            enabled: gs.canDoActivity('socialize'),
          ),
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
            'Attendance: ${(gs.player.attendanceRate * 100).toStringAsFixed(0)}% · Int ${gs.player.intelligence}',
            style: const TextStyle(fontSize: 12),
          ),
          if (gs.isExhausted)
            const Text(
              'Exhausted! Rest at home first.',
              style: TextStyle(fontSize: 11, color: Colors.red),
            ),
          btn(
            'Attend class (90m, Int+1 Edu+2)',
            () {
              if (!gs.canDoActivity('class')) {
                onMessage('Too tired for class!');
                return;
              }
              gs.attendClass(present: true);
              onMessage('Class finished. Intelligence +1, Education +2.');
            },
            enabled: gs.canDoActivity('class') && !gs.isExhausted,
          ),
          btn('Library study (+Int, 60m)', () {
            if (!gs.canDoActivity('study')) {
              onMessage('Too tired.');
              return;
            }
            gs.study();
            onMessage('Quiet library study. Intelligence +1.');
          }, enabled: gs.canDoActivity('study')),
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
            // Summertime Saga: requires being on quest stage
            if (gs.quests['missing_wallet']?.status != QuestStatus.active) {
              onMessage('Vendor: "Come back if you have a reason."');
              return;
            }
            gs.completeObjective('missing_wallet', 'talk_vendor');
            onMessage('Vendor: "Yes! Someone left a wallet here."');
          }),
          btn('Return wallet to Maria (needs wallet)', () {
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
          btn(
            'Chat & charm training (+Charm 2, 45m)',
            () {
              if (!gs.canDoActivity('socialize')) {
                onMessage('Too tired.');
                return;
              }
              gs.socialize();
              onMessage('You chatted with locals. Charm +2.');
            },
            enabled: gs.canDoActivity('socialize'),
          ),
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
          btn('Attend service (+Charm 1, 90m)', () {
            gs.applyActivity('church');
            gs.setFlag('visited_church');
            onMessage('A calm service. Charm +1.');
          }),
          btn('Volunteer (+Rel Maria, +Charm)', () {
            if (!gs.canDoActivity('church')) {
              onMessage('Too tired.');
              return;
            }
            gs.applyActivity('church');
            gs.adjustRelationship('maria', 2);
            onMessage('You helped set up. Maria +2 rel, Charm +1.');
          }),
        ];
      case 'park':
        {
          final gymQuest = gs.quests['gym_initiation'];
          return [
            btn('Gym: Lift weights (+Str 2, 60m)', () {
              if (!gs.canDoActivity('gym')) {
                onMessage('Need energy!');
                return;
              }
              gs.applyActivity('gym');
              // Gym Initiation: "Reach Strength 14 at park gym"
              if (gymQuest?.status == QuestStatus.active &&
                  gs.player.strength >= 14) {
                gs.completeObjective('gym_initiation', 'train_strength');
              }
              onMessage('Pump! Strength +2.');
            }, enabled: gs.canDoActivity('gym')),
            btn('Jog (+Str 1, 60m)', () {
              gs.applyActivity('exercise');
              onMessage('You jogged. Strength +1.');
            }),
            btn(
              'Meditate/Relax (+Energy, 30m)',
              () => gs.applyActivity('rest'),
            ),
            if (gymQuest?.status == QuestStatus.active)
              btn('Spar with Ben', () {
                gs.applyActivity('exercise');
                gs.adjustRelationship('ben', 2);
                gs.completeObjective('gym_initiation', 'spar_ben');
                onMessage('You spar with Ben. He nods, impressed.');
              }),
          ];
        }
      case 'workplace':
        return [
          Text(
            'Shift: 17:00–20:30 · Salary ₱300 (Energy -25)',
            style: const TextStyle(fontSize: 12),
          ),
          if (gs.isExhausted)
            const Text(
              'Too tired for shift! Rest first.',
              style: TextStyle(fontSize: 11, color: Colors.red),
            ),
          btn('Start café shift (mini-game)', () {
            if (!gs.canDoActivity('work')) {
              onMessage('Need energy for shift!');
              return;
            }
            onClose();
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CafeGameScreen()));
          }, enabled: gs.canDoActivity('work')),
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
