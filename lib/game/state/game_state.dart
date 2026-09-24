import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_model.dart';
import '../../models/game_time.dart';
import '../../models/npc_model.dart';
import '../../models/quest_model.dart';
import '../../models/item_model.dart';
import '../systems/core_systems.dart';
import 'game_snapshot.dart';

final gameStateProvider = ChangeNotifierProvider<GameState>(
  (ref) => GameState(),
);

class GameState extends ChangeNotifier {
  PlayerModel player = const PlayerModel();
  GameTime time = GameTime.morning(1);
  Map<String, NpcModel> npcs = {};
  Map<String, QuestModel> quests = {};
  Map<String, int> flags = {};
  List<InventoryStack> inventory = [];
  String weather = WeatherKind.sunny;
  int chapter = 1;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  void loadSnapshot({
    required PlayerModel player,
    required GameTime time,
    required Map<String, NpcModel> npcs,
    required Map<String, QuestModel> quests,
    required Map<String, int> flags,
    required List<InventoryStack> inventory,
    String weather = 'sunny',
    int chapter = 1,
  }) {
    this.player = player;
    this.time = time;
    this.npcs = npcs;
    this.quests = quests;
    this.flags = flags;
    this.inventory = inventory;
    this.weather = weather;
    this.chapter = chapter;
    _loaded = true;
    notifyListeners();
  }

  void markLoaded() {
    _loaded = true;
    notifyListeners();
  }

  GameStateSnapshot snapshot() => GameStateSnapshot(
    player: player,
    time: time,
    npcs: npcs,
    quests: quests,
    flags: flags,
    inventory: inventory,
    weather: weather,
    chapter: chapter,
  );

  void advanceMinutes(int minutes) {
    time = time.addMinutes(minutes);
    notifyListeners();
  }

  MoneyResult addMoney(int amount) {
    player = player.copyWith(money: player.money + amount);
    notifyListeners();
    return const MoneyResult(true);
  }

  MoneyResult removeMoney(int amount) {
    final check = MoneySystem.canAfford(player.money, amount);
    if (!check.ok) return check;
    player = player.copyWith(money: player.money - amount);
    notifyListeners();
    return const MoneyResult(true);
  }

  void applyEnergy(int delta) {
    player = player.copyWith(energy: player.energy + delta);
    notifyListeners();
  }

  bool get isExhausted => player.energy < 10;

  void applyActivity(String activityId) {
    final cfg = Activities.of(activityId);
    if (!EnergySystem.canDo(player.energy, cfg.energyDelta) &&
        cfg.energyDelta < 0) {
      return;
    }
    advanceMinutes(cfg.minutes);
    player = player.copyWith(
      energy: player.energy + cfg.energyDelta,
      happiness: player.happiness + cfg.happinessDelta,
      health: player.health + cfg.healthDelta,
    );
    notifyListeners();
  }

  void eatMeal() => applyActivity('eat');

  void study() {
    applyActivity('study');
    player = player.copyWith(
      education: player.education + 2,
      intelligence: player.intelligence + 1,
    );
    notifyListeners();
  }

  void attendClass({bool present = true}) {
    player = player.copyWith(
      attendanceTaken: player.attendanceTaken + 1,
      attendancePresent: player.attendancePresent + (present ? 1 : 0),
    );
    if (present) {
      applyActivity('class');
      player = player.copyWith(
        education: player.education + 2,
        intelligence: player.intelligence + 1,
      );
    } else {
      advanceMinutes(Activities.of('class').minutes);
      flags['school_warning'] = (flags['school_warning'] ?? 0) + 1;
    }
    notifyListeners();
  }

  void adjustRelationship(String npcId, int delta) {
    final npc = npcs[npcId];
    if (npc == null) return;
    npcs[npcId] = npc.copyWith(relationship: npc.relationship + delta);
    notifyListeners();
  }

  void setFlag(String key, [int value = 1]) {
    flags[key] = value;
    notifyListeners();
  }

  bool hasFlag(String key) => (flags[key] ?? 0) > 0;

  void startQuest(String id) {
    final q = quests[id];
    if (q == null || q.status != QuestStatus.available) return;
    quests[id] = q.copyWith(status: QuestStatus.active);
    notifyListeners();
  }

  void completeObjective(String questId, String objectiveId) {
    final q = quests[questId];
    if (q == null || q.status != QuestStatus.active) return;
    final updated = q.objectives
        .map((o) => o.id == objectiveId ? o.copyWith(done: true) : o)
        .toList();
    var next = q.copyWith(objectives: updated);
    if (next.isComplete) {
      next = next.copyWith(status: QuestStatus.completed);
      addMoney(next.rewardMoney);
      if (next.rewardRelationship != 0) {
        adjustRelationship(next.npcId, next.rewardRelationship);
      }
      player = player.copyWith(happiness: player.happiness + 2);
      if (next.rewardFlag != null) setFlag(next.rewardFlag!);
    }
    quests[questId] = next;
    notifyListeners();
  }

  void addItem(String itemId, int count) {
    final idx = inventory.indexWhere((e) => e.itemId == itemId);
    if (idx >= 0) {
      inventory[idx] = inventory[idx].copyWith(
        count: inventory[idx].count + count,
      );
    } else {
      inventory.add(InventoryStack(itemId, count));
    }
    notifyListeners();
  }

  bool removeItem(String itemId, int count) {
    final idx = inventory.indexWhere((e) => e.itemId == itemId);
    if (idx < 0 || inventory[idx].count < count) return false;
    final left = inventory[idx].count - count;
    if (left <= 0) {
      inventory.removeAt(idx);
    } else {
      inventory[idx] = inventory[idx].copyWith(count: left);
    }
    notifyListeners();
    return true;
  }

  void sleep() {
    final nextDay = time.day + 1;
    final wake = GameTime(day: nextDay, minutes: 7 * 60);
    time = wake;
    player = player.copyWith(
      energy: PlayerModel.energyMax,
      health: player.health + 5,
    );
    weather = WeatherKind.sunny;
    notifyListeners();
  }

  String get pesoBalance => '₱${player.money}';
}
