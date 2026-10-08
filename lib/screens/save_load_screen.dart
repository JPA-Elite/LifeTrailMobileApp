import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/state/game_state.dart';
import '../services/save_service.dart';

class SaveLoadScreen extends ConsumerStatefulWidget {
  const SaveLoadScreen({super.key});

  @override
  ConsumerState<SaveLoadScreen> createState() => _SaveLoadState();
}

class _SaveLoadState extends ConsumerState<SaveLoadScreen> {
  final _save = PrefsSaveService();
  List<Map<String, dynamic>> _slots = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _refresh();
  }

  Future<void> _refresh() async {
    final slots = await _save.slotSummaries();
    if (mounted) setState(() => _slots = slots);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Save Slots')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final s in _slots)
                Card(
                  child: ListTile(
                    title: Text(s['slot'] as String),
                    subtitle: Text(
                      (s['empty'] as bool)
                          ? 'Empty slot'
                          : 'Day ${s['day']} · Chapter ${s['chapter']} · ₱${s['money']}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final gs = ref.read(gameStateProvider);
                            final snap = gs.snapshot();
                            await _save.saveGame(
                              s['slot'] as String,
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
                            _refresh();
                          },
                          child: const Text('Save'),
                        ),
                        TextButton(
                          onPressed: (s['empty'] as bool)
                              ? null
                              : () async {
                                  await _save.deleteSave(s['slot'] as String);
                                  _refresh();
                                },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
