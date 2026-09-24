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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Save data is corrupt.')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFFB3261E),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B3A2D), Color(0xFF2E7D5B), Color(0xFF8FC1A3)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(110),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'LIFE TRAIL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'An original small-town life simulator',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _MenuButton(
                    icon: Icons.play_arrow_rounded,
                    label: 'New Game',
                    subtitle: 'Start a fresh life in town',
                    primary: true,
                    onPressed: _newGame,
                  ),
                  const SizedBox(height: 10),
                  _MenuButton(
                    icon: Icons.play_circle_outline,
                    label: 'Continue',
                    subtitle: 'Pick up where you left off',
                    enabled: _hasSave,
                    onPressed: _hasSave ? _continue : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MenuButton(
                          icon: Icons.save_outlined,
                          label: 'Slots',
                          compact: true,
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/save-load'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MenuButton(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          compact: true,
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/settings'),
                        ),
                      ),
                    ],
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

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool primary;
  final bool compact;
  final bool enabled;
  final VoidCallback? onPressed;

  const _MenuButton({
    required this.icon,
    required this.label,
    this.subtitle,
    this.primary = false,
    this.compact = false,
    this.enabled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final onTap = enabled ? onPressed : null;
    final bg = primary
        ? const Color(0xFFFFD966)
        : Colors.white.withAlpha(onTap == null ? 110 : 235);
    final fg = primary ? const Color(0xFF3A2C26) : const Color(0xFF22301F);
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        elevation: primary ? 4 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: compact ? 12 : 13,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary
                        ? Colors.black.withAlpha(20)
                        : const Color(0xFF2E7D5B).withAlpha(28),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: fg, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: compact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: fg,
                        ),
                      ),
                      if (subtitle != null && !compact)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: fg.withAlpha(170),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: fg.withAlpha(150),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
