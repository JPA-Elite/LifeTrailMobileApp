import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_model.dart';
import '../../models/game_time.dart';
import '../../models/npc_model.dart';
import '../../models/quest_model.dart';
import '../../models/item_model.dart';
import '../../models/cooking.dart';
import '../../services/game_data_service.dart';
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
    // Custom plates encode their stats in the inventory item id. Re-register
    // those item definitions after loading so the table and inventory can
    // show their real names and effects.
    _registerCustomMealItems();
    _checkQuestUnlocks();
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
    // Summertime Saga: time advance may unlock new quests/events
    _checkQuestUnlocks();
    notifyListeners();
  }

  // Summertime Saga chapter debt/progression hook
  int get debtDueDay => 7;

  /// Rent owed to the landlord. Payable at the bank with [payRent].
  static const int rentCost = 500;

  bool get rentPaid => hasFlag('debt_paid');

  bool get isDebtOverdue => time.day > debtDueDay && !rentPaid;

  /// Pays the landlord and clears the overdue-rent penalty.
  ///
  /// This is the only way out of [isDebtOverdue]; the old build showed a HUD
  /// warning with no remedy at all.
  MoneyResult payRent() {
    if (rentPaid) {
      return const MoneyResult(false, 'Your rent is already settled.');
    }
    final check = removeMoney(rentCost);
    if (!check.ok) {
      return const MoneyResult(
        false,
        'You need ₱$rentCost to settle the rent.',
      );
    }
    flags['debt_paid'] = 1;
    if (quests['debt_repayment']?.status == QuestStatus.available) {
      startQuest('debt_repayment');
    }
    completeObjective('debt_repayment', 'earn_money');
    completeObjective('debt_repayment', 'pay_landlord');
    addHappiness(5);
    notifyListeners();
    return const MoneyResult(true, 'Rent paid. You can sleep easy again.');
  }

  /// Promotes every `locked` quest whose gates (flags / relationship /
  /// day / stats) are now satisfied to `available`.
  ///
  /// Silent on purpose: every caller notifies listeners itself.
  void _checkQuestUnlocks() {
    for (final entry in quests.entries.toList()) {
      final q = entry.value;
      if (q.status != QuestStatus.locked) continue;
      final npcRel = npcs[q.npcId]?.relationship ?? 0;
      if (q.canUnlock(
        flags: flags,
        quests: quests,
        relationship: npcRel,
        day: time.day,
        intelligence: player.intelligence,
        charm: player.charm,
        strength: player.strength,
      )) {
        quests[entry.key] = q.copyWith(status: QuestStatus.available);
      }
    }
  }

  MoneyResult addMoney(int amount) {
    player = player.copyWith(money: player.money + amount);
    _syncMoneyObjectives();
    notifyListeners();
    return const MoneyResult(true);
  }

  bool _syncingMoneyObjectives = false;

  /// The rent quest's first objective ("earn money") is satisfied as soon as
  /// the player actually has enough cash on hand. The re-entrancy guard
  /// matters because completing an objective can itself award money.
  void _syncMoneyObjectives() {
    if (_syncingMoneyObjectives) return;
    if (player.money < rentCost) return;
    final q = quests['debt_repayment'];
    if (q == null || q.status != QuestStatus.active) return;
    if (q.objectives.any((o) => o.id == 'earn_money' && o.done)) return;
    _syncingMoneyObjectives = true;
    completeObjective('debt_repayment', 'earn_money');
    _syncingMoneyObjectives = false;
  }

  MoneyResult removeMoney(int amount) {
    final check = MoneySystem.canAfford(player.money, amount);
    if (!check.ok) return check;
    player = player.copyWith(money: player.money - amount);
    notifyListeners();
    return const MoneyResult(true);
  }

  void applyEnergy(int delta) => changeEnergy(delta);

  /// Adds [delta] energy, clamped to the player's limits. Walking and running
  /// call this with a small negative value; activities call it directly too.
  void changeEnergy(int delta) {
    if (delta == 0) return;
    final next = (player.energy + delta)
        .clamp(0, PlayerModel.energyMax)
        .toInt();
    if (next == player.energy) return;
    player = player.copyWith(energy: next);
    notifyListeners();
  }

  /// Adds [delta] health, clamped to 0..[PlayerModel.healthMax]. Vehicle
  /// crashes call this with -1; healing items can call it with a positive
  /// value.
  void changeHealth(int delta) {
    if (delta == 0) return;
    final next = (player.health + delta)
        .clamp(0, PlayerModel.healthMax)
        .toInt();
    if (next == player.health) return;
    player = player.copyWith(health: next);
    _checkQuestUnlocks();
    notifyListeners();
  }

  /// Clears the in-memory session after "Reset all progress" deletes every
  /// save slot. The menu sees an unloaded state again, so Continue is disabled
  /// until a new game starts.
  void reset() {
    player = const PlayerModel();
    time = GameTime.morning(1);
    npcs = {};
    quests = {};
    flags = {};
    inventory = [];
    weather = WeatherKind.sunny;
    chapter = 1;
    _loaded = false;
    notifyListeners();
  }

  /// Adds [delta] happiness (clamped to the maximum) and notifies listeners.
  /// Returns the resulting value, so timed scenes can stop when the player
  /// is completely happy without poking at the model directly.
  int addHappiness(int delta) {
    final next = (player.happiness + delta)
        .clamp(0, PlayerModel.happinessMax)
        .toInt();
    if (next != player.happiness) {
      player = player.copyWith(happiness: next);
      // "Weekend Reset" closes its second objective once the player is
      // genuinely happy again (80+).
      final hike = quests['weekend_hike'];
      if (hike != null &&
          hike.status == QuestStatus.active &&
          next >= 80) {
        completeObjective('weekend_hike', 'unwind');
      }
      _checkQuestUnlocks();
      notifyListeners();
    }
    return next;
  }

  /// Changes the player's visible outfit. Indexes are clamped to the
  /// wardrobe catalog; nothing happens when the look is unchanged.
  void setOutfit({int? shirtIndex, int? shortsIndex}) {
    final next = player.copyWith(
      shirtIndex: shirtIndex,
      shortsIndex: shortsIndex,
    );
    if (next.shirtIndex == player.shirtIndex &&
        next.shortsIndex == player.shortsIndex) {
      return;
    }
    player = next;
    notifyListeners();
  }

  void addCharm(int delta) {
    player = player.copyWith(charm: player.charm + delta);
    _checkQuestUnlocks();
    notifyListeners();
  }

  void addIntelligence(int delta) {
    player = player.copyWith(intelligence: player.intelligence + delta);
    _checkQuestUnlocks();
    notifyListeners();
  }

  void addStrength(int delta) {
    player = player.copyWith(strength: player.strength + delta);
    _checkQuestUnlocks();
    notifyListeners();
  }

  /// Raises education (class attendance and study venues). Kept alongside
  /// the other stat setters so quest gates are re-checked consistently.
  void addEducation(int delta) {
    player = player.copyWith(education: player.education + delta);
    _checkQuestUnlocks();
    notifyListeners();
  }

  bool get isExhausted => player.energy < 10;

  // Returns false if blocked (energy/time/closed), like Summertime Saga's "You are too tired" / "Closed"
  bool canDoActivity(String activityId) {
    final cfg = Activities.of(activityId);
    if (!EnergySystem.canDo(player.energy, cfg.energyDelta) &&
        cfg.energyDelta < 0) {
      return false;
    }
    return true;
  }

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
      intelligence: player.intelligence + cfg.intelligenceDelta,
      strength: player.strength + cfg.strengthDelta,
      charm: player.charm + cfg.charmDelta,
      education: player.education + cfg.educationDelta,
    );
    // Stat gains from activities can satisfy a quest gate (e.g. park gym
    // raising Strength to 14 unlocks the Gym Initiation quest).
    _checkQuestUnlocks();
    notifyListeners();
  }

  // Location-gated variant: respects opening hours (Summertime Saga)
  bool isLocationOpen(String locationId) =>
      LocationHours.isOpen(locationId, time.weekdayLabel, time.minutes);

  // --- Day scenario / building-entry time cost ---------------------------
  // Walking up to a door and stepping in costs a short 20 minutes. The old
  // 90-minute charge double-counted the time already spent on each venue
  // action, so three errands swallowed an entire day.
  static const int minutesPerBuildingEntry = 20;

  int get buildingEntryCount => flags['building_entries'] ?? 0;

  void registerBuildingEntry() {
    flags['building_entries'] = buildingEntryCount + 1;
    advanceMinutes(minutesPerBuildingEntry);
  }

  /// Night scenario: no building may be entered except home, where the
  /// player sleeps until morning (07:00 next day via [sleep]).
  bool get isNightTime => time.isNight;

  bool canEnterBuilding(String locationId) {
    if (locationId == 'home') return true;
    // Real opening hours, not a blanket night lock: 24 h venues (hospital,
    // police, hotel, beach, fishing) stay usable after dark.
    return isLocationOpen(locationId);
  }

  String buildingBlockedMessage(String locationId) {
    final title = LocationHours.name(locationId);
    if (LocationHours.isAlwaysOpen(locationId)) {
      return '$title is closed right now (${time.clockLabel}).';
    }
    return '$title is closed. Hours: ${LocationHours.label(locationId)}. '
        'It is ${time.clockLabel} ${time.periodLabel.toLowerCase()} — '
        'come back when it opens.';
  }

  void eatMeal() => applyActivity('eat');

  void study() {
    if (!canDoActivity('study')) return;
    applyActivity('study');
    notifyListeners();
  }

  void exercise() {
    if (!canDoActivity('exercise')) return;
    applyActivity('exercise');
    notifyListeners();
  }

  void socialize() {
    if (!canDoActivity('socialize')) return;
    applyActivity('socialize');
    notifyListeners();
  }

  void attendClass({bool present = true}) {
    player = player.copyWith(
      attendanceTaken: player.attendanceTaken + 1,
      attendancePresent: player.attendancePresent + (present ? 1 : 0),
    );
    if (present) {
      // The `class` activity already grants +2 education and +1 intelligence.
      // Adding them again here used to double every lesson's payout.
      applyActivity('class');
    } else {
      advanceMinutes(Activities.of('class').minutes);
      flags['school_warning'] = (flags['school_warning'] ?? 0) + 1;
    }
    notifyListeners();
  }

  /// Grades a finished practice quiz in a single step.
  ///
  /// The old screen called [attendClass] once per answer, so a five-question
  /// quiz cost 7.5 hours and marked five attendances. This charges one short
  /// 15-minute session and scales the reward with the score.
  QuizResult finishQuiz({required int correct, required int total}) {
    final cfg = Activities.of('quiz');
    if (!EnergySystem.canDo(player.energy, cfg.energyDelta)) {
      return QuizResult(
        ok: false,
        correct: correct,
        total: total,
        passed: false,
        message: 'You are too tired to focus on a quiz.',
      );
    }
    advanceMinutes(cfg.minutes);
    final ratio = total <= 0 ? 0.0 : correct / total;
    final passed = ratio >= 0.5;
    final strong = ratio >= 0.8;
    player = player.copyWith(
      energy: player.energy + cfg.energyDelta,
      education: player.education + (strong ? 2 : (passed ? 1 : 0)),
      intelligence: player.intelligence + (strong ? 2 : (passed ? 1 : 0)),
      happiness: player.happiness + (passed ? 1 : 0),
      money: player.money + (strong ? 50 : 0),
    );
    if (strong) {
      completeObjective('study_group', 'ace_quiz');
    }
    _checkQuestUnlocks();
    notifyListeners();
    final reward = strong
        ? 'Excellent! Education +2, Intelligence +2, Happiness +1, ₱50.'
        : passed
        ? 'Passed. Education +1, Intelligence +1, Happiness +1.'
        : 'You scraped through. Study more and try again.';
    return QuizResult(
      ok: true,
      correct: correct,
      total: total,
      passed: passed,
      message: reward,
    );
  }

  void adjustRelationship(String npcId, int delta) {
    final npc = npcs[npcId];
    if (npc == null) return;
    npcs[npcId] = npc.copyWith(relationship: npc.relationship + delta);
    _checkQuestUnlocks();
    notifyListeners();
  }

  void setFlag(String key, [int value = 1]) {
    flags[key] = value;
    _checkQuestUnlocks();
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

  int itemCount(String itemId) {
    for (final stack in inventory) {
      if (stack.itemId == itemId) return stack.count;
    }
    return 0;
  }

  bool hasItems(Map<String, int> needs) {
    for (final entry in needs.entries) {
      if (itemCount(entry.key) < entry.value) return false;
    }
    return true;
  }

  /// Adds the starter pantry once per save. Called after loading so saves
  /// created before the kitchen existed still get a usable first stock.
  void ensureStarterPantry() {
    if (hasFlag('pantry_seeded')) return;
    _addStacksSilently(PantryCatalog.starterStock);
    flags['pantry_seeded'] = 1;
    notifyListeners();
  }

  /// Cooks [recipe] atomically: ingredients are checked before anything is
  /// consumed, then the meal is added to the inventory and the cooking
  /// activity advances time / spends energy.
  bool cookMeal(CookingRecipe recipe) {
    if (!canDoActivity(recipe.activityId)) return false;
    if (!hasItems(recipe.ingredients)) return false;
    _removeStacksSilently(recipe.ingredients);
    _addStacksSilently({recipe.mealId: 1});
    notifyListeners();
    applyActivity(recipe.activityId);
    return true;
  }

  /// Cooks a player-designed plate. The ingredient check and stock removal
  /// happen atomically, then the variable stove time and energy cost are
  /// applied. Returns null when the pantry or the player is short.
  CustomCookPlan? cookCustomMeal(CustomCookPlan plan) {
    if (!canCookCustom(plan)) return null;
    _removeStacksSilently(plan.ingredients);
    _addStacksSilently({plan.mealId: 1});
    GameDataService().items[plan.mealId] = plan.toItem();
    player = player.copyWith(
      energy: player.energy - plan.cookEnergyCost,
      happiness: player.happiness + 1,
    );
    advanceMinutes(plan.cookMinutes);
    _checkQuestUnlocks();
    notifyListeners();
    return plan;
  }

  bool canCookCustom(CustomCookPlan plan) {
    if (plan.isEmpty) return false;
    if (player.energy < plan.cookEnergyCost) return false;
    return hasItems(plan.ingredients);
  }

  /// Eats a plated meal at the dining table. Returns false if the meal is
  /// not in the kitchen/table inventory.
  bool eatCookedMeal(String mealId) {
    final meal = CookingCatalog.servingFor(mealId);
    if (meal == null) return false;
    if (!removeItem(mealId, 1)) return false;
    advanceMinutes(meal.minutes);
    player = player.copyWith(
      energy: player.energy + meal.energy,
      happiness: player.happiness + meal.happiness,
    );
    _checkQuestUnlocks();
    notifyListeners();
    return true;
  }

  List<CookedMeal> get cookedMeals {
    final meals = <CookedMeal>[
      for (final recipe in CookingCatalog.recipes)
        if (itemCount(recipe.mealId) > 0) recipe.toMeal(),
    ];
    for (final stack in inventory) {
      if (!CookingCatalog.isCustomMealId(stack.itemId)) continue;
      final meal = CookingCatalog.servingFor(stack.itemId);
      if (meal != null) meals.add(meal);
    }
    return meals;
  }

  void _registerCustomMealItems() {
    for (final stack in inventory) {
      if (!CookingCatalog.isCustomMealId(stack.itemId)) continue;
      final plan = CookingCatalog.customMealFromId(stack.itemId);
      if (plan == null) continue;
      GameDataService().items[plan.mealId] = plan.toItem();
    }
  }

  void _addStacksSilently(Map<String, int> stacks) {
    stacks.forEach((itemId, count) {
      final idx = inventory.indexWhere((e) => e.itemId == itemId);
      if (idx >= 0) {
        inventory[idx] = inventory[idx].copyWith(
          count: inventory[idx].count + count,
        );
      } else {
        inventory.add(InventoryStack(itemId, count));
      }
    });
  }

  void _removeStacksSilently(Map<String, int> stacks) {
    stacks.forEach((itemId, count) {
      final idx = inventory.indexWhere((e) => e.itemId == itemId);
      if (idx < 0) return;
      final left = inventory[idx].count - count;
      if (left <= 0) {
        inventory.removeAt(idx);
      } else {
        inventory[idx] = inventory[idx].copyWith(count: left);
      }
    });
  }

  void sleep() {
    final nextDay = time.day + 1;
    final wake = GameTime(day: nextDay, minutes: 7 * 60);
    time = wake;
    // Sleeping with the rent unpaid is rough: the landlord is knocking and
    // the worry follows you to bed.
    final overdue = isDebtOverdue;
    player = player.copyWith(
      energy: PlayerModel.energyMax,
      health: player.health + (overdue ? -2 : 5),
      happiness: player.happiness + (overdue ? -3 : 2),
    );
    weather = WeatherKind.sunny;
    // Summertime Saga: chapter increments, attendance resets weekly
    if (wake.weekday == Weekday.monday) {
      flags['weekly_attendance_checked'] = 0;
    }
    _checkQuestUnlocks();
    notifyListeners();
  }

  void restSit() {
    advanceMinutes(10);
    player = player.copyWith(
      energy: player.energy + 8,
      happiness: player.happiness + 1,
    );
    notifyListeners();
  }

  String get pesoBalance => '₱${player.money}';

  // --- ATM ---------------------------------------------------------------
  // Bank balance + PIN live in flags so they persist through the existing
  // save format with zero migration. Default PIN is 000000.

  static const String defaultAtmPin = '000000';
  static const int atmPinLength = 6;

  int get bankBalance => flags['bank_balance'] ?? 2000;

  /// Pocket money the bank hands out. Once per in-game day so it cannot be
  /// farmed by reopening the bank menu.
  static const int allowanceAmount = 200;

  MoneyResult withdrawAllowance() {
    if ((flags['allowance_day'] ?? -1) == time.day) {
      return const MoneyResult(
        false,
        'You already collected today\'s allowance. Come back tomorrow.',
      );
    }
    flags['allowance_day'] = time.day;
    addMoney(allowanceAmount);
    advanceMinutes(5);
    return const MoneyResult(
      true,
      'Allowance collected: +₱$allowanceAmount.',
    );
  }

  String get bankPesoBalance => '₱$bankBalance';

  String get atmPin =>
      (flags['atm_pin'] ?? 0).toString().padLeft(atmPinLength, '0');

  bool verifyAtmPin(String pin) => pin == atmPin;

  MoneyResult atmWithdraw(int amount) {
    if (amount <= 0) return const MoneyResult(false, 'Enter an amount.');
    if (amount > bankBalance) {
      return const MoneyResult(false, 'Insufficient bank balance.');
    }
    flags['bank_balance'] = bankBalance - amount;
    addMoney(amount);
    advanceMinutes(5);
    return const MoneyResult(true);
  }

  MoneyResult atmDeposit(int amount) {
    if (amount <= 0) return const MoneyResult(false, 'Enter an amount.');
    final check = MoneySystem.canAfford(player.money, amount);
    if (!check.ok) return const MoneyResult(false, 'Not enough cash.');
    player = player.copyWith(money: player.money - amount);
    flags['bank_balance'] = bankBalance + amount;
    advanceMinutes(5);
    notifyListeners();
    return const MoneyResult(true);
  }

  MoneyResult atmChangePin(String currentPin, String newPin) {
    if (!verifyAtmPin(currentPin)) {
      return const MoneyResult(false, 'Current PIN is wrong.');
    }
    if (newPin.length != atmPinLength || int.tryParse(newPin) == null) {
      return const MoneyResult(false, 'New PIN must be 6 digits.');
    }
    if (newPin == currentPin) {
      return const MoneyResult(false, 'New PIN matches the old one.');
    }
    flags['atm_pin'] = int.parse(newPin);
    notifyListeners();
    return const MoneyResult(true);
  }
}

/// Outcome of grading a practice quiz in one step.
class QuizResult {
  const QuizResult({
    required this.ok,
    required this.correct,
    required this.total,
    required this.passed,
    required this.message,
  });

  final bool ok;
  final int correct;
  final int total;
  final bool passed;
  final String message;
}
