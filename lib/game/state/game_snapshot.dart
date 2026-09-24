import '../../models/player_model.dart';
import '../../models/game_time.dart';
import '../../models/npc_model.dart';
import '../../models/quest_model.dart';
import '../../models/item_model.dart';

class GameStateSnapshot {
  final PlayerModel player;
  final GameTime time;
  final Map<String, NpcModel> npcs;
  final Map<String, QuestModel> quests;
  final Map<String, int> flags;
  final List<InventoryStack> inventory;
  final String weather;
  final int chapter;

  const GameStateSnapshot({
    required this.player,
    required this.time,
    required this.npcs,
    required this.quests,
    required this.flags,
    required this.inventory,
    this.weather = 'sunny',
    this.chapter = 1,
  });

  bool hasFlag(String key) => (flags[key] ?? 0) > 0;

  Map<String, dynamic> toJson() => {
    'player': player.toJson(),
    'time': time.toJson(),
    'npcs': npcs.map((k, v) => MapEntry(k, {'relationship': v.relationship})),
    'quests': quests.map((k, v) => MapEntry(k, v.toJson())),
    'flags': flags,
    'inventory': inventory.map((e) => e.toJson()).toList(),
    'weather': weather,
    'chapter': chapter,
  };
}
