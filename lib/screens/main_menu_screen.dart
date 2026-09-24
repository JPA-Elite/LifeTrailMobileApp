import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/state/game_state.dart';
import '../services/game_data_service.dart';
import '../services/save_service.dart';
import '../models/game_time.dart';
import '../models/player_model.dart';
import '../models/item_model.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuState();
}

class _MainMenuState extends ConsumerState<MainMenuScreen> {
  final _save = PrefsSaveService();
  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final has = await _save.hasSave('slot1');
    if (mounted) setState(() => _hasSave = has);
  }

  Future<void> _newGame() async {
    await GameDataService().loadAll();
    ref
        .read(gameStateProvider)
        .loadSnapshot(
          player: const PlayerModel(),
          time: GameTime.morning(1),
          npcs: Map.of(GameDataService().npcs),
          quests: Map.of(GameDataService().quests),
          flags: {},
          inventory: [const InventoryStack('bread', 1)],
        );
    if (mounted) Navigator.of(context).pushReplacementNamed('/game');
  }

  Future<void> _continue() async {
    await GameDataService().loadAll();
    final data = await _save.loadGame('slot1');
    if (data == null) return;
    try {
      final gs = ref.read(gameStateProvider);
      final player = PlayerModel.fromJson(
        Map<String, dynamic>.from(data['player'] as Map),
      );
      final time = GameTime.fromJson(
        Map<String, dynamic>.from(data['time'] as Map),
      );
      final rels = Map<String, dynamic>.from(data['npcs'] as Map? ?? {});
      final questsRaw = Map<String, dynamic>.from(data['quests'] as Map? ?? {});
      final quests = Map<String, dynamic>.fromEntries(
        GameDataService().quests.entries.map((e) {
          if (questsRaw.containsKey(e.key)) {
            try {
              return MapEntry(
                e.key,
                ref.read(gameStateProvider).quests[e.key] ?? e.value,
              );
            } catch (_) {}
          }
          return MapEntry(e.key, e.value);
        }),
      );
      gs.loadSnapshot(
        player: player,
        time: time,
        npcs: Map.of(GameDataService().npcs)
          ..updateAll(
            (k, v) => v.copyWith(relationship: (rels[k] as num?)?.toInt() ?? 0),
          ),
        quests: quests.map((k, v) => MapEntry(k, v as dynamic)),
        flags: Map<String, int>.from(data['flags'] as Map? ?? {}),
        inventory: ((data['inventory'] as List?) ?? [])
            .map(
              (e) =>
                  InventoryStack.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
        weather: data['weather'] as String? ?? 'sunny',
        chapter: (data['chapter'] as num?)?.toInt() ?? 1,
      );
      if (mounted) Navigator.of(context).pushReplacementNamed('/game');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Save data is corrupt.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'LIFE TRAIL',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
                ),
                const Text(
                  'An original small-town life simulator',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _newGame,
                  child: const Text('New Game'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _hasSave ? _continue : null,
                  child: const Text('Continue'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/save-load'),
                  child: const Text('Save Slots'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                  child: const Text('Settings'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Landscape · touch controls · one full playable day',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
