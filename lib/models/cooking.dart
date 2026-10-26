import 'package:flutter/material.dart' hide DayPeriod;

import 'game_time.dart';
import 'item_model.dart';

/// A raw ingredient that lives in the kitchen pantry.
///
/// Ingredients are ordinary inventory stacks, so buying more at the Super
/// Market automatically increases what the kitchen can cook.
class PantryIngredient {
  const PantryIngredient({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.energy,
    required this.cookMinutes,
    required this.happiness,
  });

  final String id;
  final String name;
  final String emoji;
  final Color color;

  /// Energy this ingredient contributes to a custom plate.
  final int energy;

  /// Extra stove time this ingredient adds to a custom plate.
  final int cookMinutes;

  /// Happiness this ingredient contributes to a custom plate.
  final int happiness;
}

class PantryCatalog {
  const PantryCatalog._();

  static const List<PantryIngredient> ingredients = [
    PantryIngredient(
      id: 'bread',
      name: 'Bread',
      emoji: '🍞',
      color: Color(0xFFD9A066),
      energy: 5,
      cookMinutes: 4,
      happiness: 1,
    ),
    PantryIngredient(
      id: 'egg',
      name: 'Eggs',
      emoji: '🥚',
      color: Color(0xFFF3E3B5),
      energy: 4,
      cookMinutes: 3,
      happiness: 1,
    ),
    PantryIngredient(
      id: 'milk',
      name: 'Milk',
      emoji: '🥛',
      color: Color(0xFFBFD7EA),
      energy: 3,
      cookMinutes: 2,
      happiness: 0,
    ),
    PantryIngredient(
      id: 'rice',
      name: 'Rice',
      emoji: '🍚',
      color: Color(0xFFE8DCC8),
      energy: 6,
      cookMinutes: 7,
      happiness: 1,
    ),
    PantryIngredient(
      id: 'chicken',
      name: 'Chicken',
      emoji: '🍗',
      color: Color(0xFFD98E73),
      energy: 8,
      cookMinutes: 9,
      happiness: 1,
    ),
    PantryIngredient(
      id: 'vegetables',
      name: 'Veggies',
      emoji: '🥦',
      color: Color(0xFF74A96B),
      energy: 3,
      cookMinutes: 4,
      happiness: 1,
    ),
    PantryIngredient(
      id: 'noodles',
      name: 'Noodles',
      emoji: '🍜',
      color: Color(0xFFE4B363),
      energy: 6,
      cookMinutes: 6,
      happiness: 1,
    ),
    PantryIngredient(
      id: 'tomato',
      name: 'Tomatoes',
      emoji: '🍅',
      color: Color(0xFFD9534F),
      energy: 2,
      cookMinutes: 3,
      happiness: 1,
    ),
    PantryIngredient(
      id: 'cheese',
      name: 'Cheese',
      emoji: '🧀',
      color: Color(0xFFF2C94C),
      energy: 4,
      cookMinutes: 3,
      happiness: 1,
    ),
  ];

  static PantryIngredient? byId(String id) {
    for (final ingredient in ingredients) {
      if (ingredient.id == id) return ingredient;
    }
    return null;
  }

  static List<String> get ids =>
      ingredients.map((ingredient) => ingredient.id).toList();

  /// A modest first pantry so a new (or upgraded) save can cook every meal
  /// at least twice without a shopping trip. The Super Market bundle tops it
  /// back up later.
  static const Map<String, int> starterStock = {
    'bread': 2,
    'egg': 4,
    'milk': 2,
    'rice': 3,
    'chicken': 2,
    'vegetables': 5,
    'noodles': 2,
    'tomato': 3,
    'cheese': 2,
  };

  /// A shopping bundle sold at the Super Market. Kept as data so future
  /// grocery vendors can reuse it.
  static const Map<String, int> groceryBundle = {
    'bread': 2,
    'egg': 2,
    'milk': 1,
    'rice': 2,
    'chicken': 1,
    'vegetables': 2,
    'noodles': 1,
    'tomato': 1,
    'cheese': 1,
  };
}

/// A plated dish as it appears on the dining table.
///
/// Fixed recipes and player-built custom plates share this shape, so the
/// table does not need to know how the meal was made.
class CookedMeal {
  const CookedMeal({
    required this.mealId,
    required this.name,
    required this.subtitle,
    required this.energy,
    required this.happiness,
    required this.minutes,
    required this.emoji,
    required this.accent,
    required this.accentDeep,
    this.ingredients = const {},
    this.isCustom = false,
  });

  final String mealId;
  final String name;
  final String subtitle;
  final int energy;
  final int happiness;

  /// In-game minutes spent eating this plate.
  final int minutes;
  final String emoji;
  final Color accent;
  final Color accentDeep;
  final Map<String, int> ingredients;
  final bool isCustom;

  String get ingredientSummary {
    if (ingredients.isEmpty) return subtitle;
    final parts = <String>[];
    ingredients.forEach((id, count) {
      final ingredient = PantryCatalog.byId(id);
      final label = ingredient?.name ?? id;
      parts.add(count > 1 ? '$label ×$count' : label);
    });
    return parts.join(' · ');
  }
}

/// A cookable fixed recipe. Ingredients are consumed when cooking; the
/// finished meal is added to the inventory as [mealId] and can then be eaten
/// at the dining table.
class CookingRecipe {
  const CookingRecipe({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.mealId,
    required this.mealName,
    required this.activityId,
    required this.ingredients,
    required this.eatEnergy,
    required this.eatHappiness,
    required this.eatMinutes,
    required this.bestPeriod,
    required this.emoji,
    required this.accent,
    required this.accentDeep,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String mealId;
  final String mealName;
  final String activityId;
  final Map<String, int> ingredients;
  final int eatEnergy;
  final int eatHappiness;
  final int eatMinutes;
  final DayPeriod bestPeriod;
  final String emoji;
  final Color accent;
  final Color accentDeep;

  CookedMeal toMeal() => CookedMeal(
    mealId: mealId,
    name: mealName,
    subtitle: subtitle,
    energy: eatEnergy,
    happiness: eatHappiness,
    minutes: eatMinutes,
    emoji: emoji,
    accent: accent,
    accentDeep: accentDeep,
    ingredients: ingredients,
  );

  String get periodHint {
    switch (bestPeriod) {
      case DayPeriod.morning:
        return 'Morning favorite';
      case DayPeriod.afternoon:
        return 'Midday favorite';
      case DayPeriod.evening:
        return 'Evening favorite';
      case DayPeriod.night:
        return 'Late-night favorite';
    }
  }
}

/// A player-designed plate, built from any combination of pantry stock.
///
/// The resulting [mealId] encodes the energy, happiness and eating time so a
/// custom meal can round-trip through the existing inventory/save data
/// without a schema change.
class CustomCookPlan {
  const CustomCookPlan({
    required this.mealId,
    required this.name,
    required this.subtitle,
    required this.ingredients,
    required this.energy,
    required this.happiness,
    required this.cookMinutes,
    required this.eatMinutes,
    required this.cookEnergyCost,
    required this.emoji,
    required this.accent,
    required this.accentDeep,
  });

  final String mealId;
  final String name;
  final String subtitle;
  final Map<String, int> ingredients;
  final int energy;
  final int happiness;
  final int cookMinutes;
  final int eatMinutes;
  final int cookEnergyCost;
  final String emoji;
  final Color accent;
  final Color accentDeep;

  bool get isEmpty => ingredients.isEmpty;

  int get portions =>
      ingredients.values.fold(0, (total, count) => total + count);

  CookedMeal get meal => CookedMeal(
    mealId: mealId,
    name: name,
    subtitle: subtitle,
    energy: energy,
    happiness: happiness,
    minutes: eatMinutes,
    emoji: emoji,
    accent: accent,
    accentDeep: accentDeep,
    ingredients: ingredients,
    isCustom: true,
  );

  ItemModel toItem() => ItemModel(
    id: mealId,
    name: name,
    description: 'A custom-cooked plate. Eat it at the dining table.',
    category: 'meal',
    effects: {'energy': energy, 'happiness': happiness},
  );
}

class CookingCatalog {
  const CookingCatalog._();

  /// The most portions a single custom plate can hold.
  static const int maxCustomPortions = 6;

  static const CookingRecipe breakfast = CookingRecipe(
    id: 'breakfast',
    title: 'Sunrise Breakfast',
    subtitle: 'Toast, eggs, and a cold glass of milk',
    description:
        'A proper morning plate. The kind that makes the whole day look possible.',
    mealId: 'meal_breakfast',
    mealName: 'Sunrise Breakfast',
    activityId: 'cook_breakfast',
    ingredients: {'bread': 1, 'egg': 2, 'milk': 1},
    eatEnergy: 18,
    eatHappiness: 2,
    eatMinutes: 30,
    bestPeriod: DayPeriod.morning,
    emoji: '🍳',
    accent: Color(0xFFFFD166),
    accentDeep: Color(0xFFB7791F),
  );

  static const CookingRecipe lunch = CookingRecipe(
    id: 'lunch',
    title: 'Midday Rice Bowl',
    subtitle: 'Rice, chicken, and bright green vegetables',
    description:
        'A warm, filling bowl with a little crunch. Perfect before an afternoon out.',
    mealId: 'meal_lunch',
    mealName: 'Midday Rice Bowl',
    activityId: 'cook_lunch',
    ingredients: {'rice': 1, 'chicken': 1, 'vegetables': 1},
    eatEnergy: 25,
    eatHappiness: 1,
    eatMinutes: 30,
    bestPeriod: DayPeriod.afternoon,
    emoji: '🍛',
    accent: Color(0xFF74A96B),
    accentDeep: Color(0xFF315C3B),
  );

  static const CookingRecipe dinner = CookingRecipe(
    id: 'dinner',
    title: 'Sunset Noodle Pot',
    subtitle: 'Noodles, tomato, veggies, and melted cheese',
    description:
        'A one-pot dinner that fills the kitchen with steam and the whole house with comfort.',
    mealId: 'meal_dinner',
    mealName: 'Sunset Noodle Pot',
    activityId: 'cook_dinner',
    ingredients: {'noodles': 1, 'vegetables': 1, 'tomato': 1, 'cheese': 1},
    eatEnergy: 30,
    eatHappiness: 2,
    eatMinutes: 30,
    bestPeriod: DayPeriod.evening,
    emoji: '🍲',
    accent: Color(0xFFE76F51),
    accentDeep: Color(0xFF8A3B2A),
  );

  static const List<CookingRecipe> recipes = [breakfast, lunch, dinner];

  static CookingRecipe? byId(String id) {
    for (final recipe in recipes) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  static CookingRecipe? byMealId(String mealId) {
    for (final recipe in recipes) {
      if (recipe.mealId == mealId) return recipe;
    }
    return null;
  }

  static List<String> get mealIds =>
      recipes.map((recipe) => recipe.mealId).toList();

  /// Builds a live custom plan from the player's chosen portions. Any empty
  /// or unknown entries are ignored, and the total is capped so the plate
  /// stays readable (and the encoded item id stays compact).
  static CustomCookPlan planCustom(Map<String, int> requested) {
    final selected = <String, int>{};
    var remaining = maxCustomPortions;
    for (final ingredient in PantryCatalog.ingredients) {
      if (remaining <= 0) break;
      final requestedCount = requested[ingredient.id] ?? 0;
      if (requestedCount <= 0) continue;
      final take = requestedCount > remaining ? remaining : requestedCount;
      selected[ingredient.id] = take;
      remaining -= take;
    }

    var total = 0;
    var energy = 4;
    var cookMinutes = 12;
    var happiness = 1;
    var dominant = PantryCatalog.ingredients.first;
    var dominantCount = 0;
    selected.forEach((id, count) {
      final ingredient = PantryCatalog.byId(id);
      if (ingredient == null) return;
      total += count;
      energy += ingredient.energy * count;
      cookMinutes += ingredient.cookMinutes * count;
      happiness += ingredient.happiness * count;
      if (count > dominantCount) {
        dominant = ingredient;
        dominantCount = count;
      }
    });

    if (total == 0) {
      return CustomCookPlan(
        mealId: '',
        name: 'Empty Plate',
        subtitle: 'Choose something from the pantry.',
        ingredients: const {},
        energy: 0,
        happiness: 0,
        cookMinutes: 0,
        eatMinutes: 0,
        cookEnergyCost: 0,
        emoji: '🍽️',
        accent: const Color(0xFFD8C8B5),
        accentDeep: const Color(0xFF6B4A2A),
      );
    }

    energy = energy.clamp(8, 60);
    cookMinutes = (cookMinutes + total * 3).clamp(20, 180);
    happiness = happiness.clamp(1, 6);
    final eatMinutes = (10 + total * 4 + energy ~/ 6).clamp(15, 60);
    final cookEnergyCost = (2 + total ~/ 2).clamp(2, 6);
    final hasRice = selected.containsKey('rice');
    final hasNoodles = selected.containsKey('noodles');
    final hasBread = selected.containsKey('bread');
    final hasChicken = selected.containsKey('chicken');
    final emoji = hasRice
        ? '🍛'
        : hasNoodles
        ? '🍜'
        : hasBread
        ? '🍳'
        : hasChicken
        ? '🍗'
        : '🥗';
    final accent = dominant.color;
    final accentDeep = Color.lerp(accent, Colors.black, 0.45)!;
    final name = customMealName(selected);
    final subtitle = selected.entries
        .map((entry) {
          final ingredient = PantryCatalog.byId(entry.key);
          final label = ingredient?.name ?? entry.key;
          return entry.value > 1 ? '$label ×${entry.value}' : label;
        })
        .join(' · ');
    final mealId = customMealId(
      ingredients: selected,
      energy: energy,
      happiness: happiness,
      eatMinutes: eatMinutes,
    );

    return CustomCookPlan(
      mealId: mealId,
      name: name,
      subtitle: subtitle,
      ingredients: selected,
      energy: energy,
      happiness: happiness,
      cookMinutes: cookMinutes,
      eatMinutes: eatMinutes,
      cookEnergyCost: cookEnergyCost,
      emoji: emoji,
      accent: accent,
      accentDeep: accentDeep,
    );
  }

  /// Stable, save-safe id for a custom plate. The trailing mask stores the
  /// per-ingredient counts in [PantryCatalog.ingredients] order.
  static String customMealId({
    required Map<String, int> ingredients,
    required int energy,
    required int happiness,
    required int eatMinutes,
  }) {
    final mask = PantryCatalog.ingredients.map((ingredient) {
      final count = ingredients[ingredient.id] ?? 0;
      return count.clamp(0, 9).toString();
    }).join();
    return 'meal_custom_${energy}_${happiness}_${eatMinutes}_$mask';
  }

  static bool isCustomMealId(String mealId) =>
      mealId.startsWith('meal_custom_');

  /// Restores a custom plate from its encoded inventory id.
  static CustomCookPlan? customMealFromId(String mealId) {
    if (!isCustomMealId(mealId)) return null;
    final parts = mealId.split('_');
    if (parts.length != 6) return null;
    final energy = int.tryParse(parts[2]);
    final happiness = int.tryParse(parts[3]);
    final eatMinutes = int.tryParse(parts[4]);
    final mask = parts[5];
    if (energy == null ||
        happiness == null ||
        eatMinutes == null ||
        mask.length != PantryCatalog.ingredients.length) {
      return null;
    }
    final ingredients = <String, int>{};
    for (var i = 0; i < PantryCatalog.ingredients.length; i++) {
      final count = int.tryParse(mask[i]) ?? 0;
      if (count > 0) {
        ingredients[PantryCatalog.ingredients[i].id] = count;
      }
    }
    if (ingredients.isEmpty) return null;
    final rebuilt = planCustom(ingredients);
    final name = customMealName(ingredients);
    final subtitle = ingredients.entries
        .map((entry) {
          final ingredient = PantryCatalog.byId(entry.key);
          final label = ingredient?.name ?? entry.key;
          return entry.value > 1 ? '$label ×${entry.value}' : label;
        })
        .join(' · ');
    return CustomCookPlan(
      mealId: mealId,
      name: name,
      subtitle: subtitle,
      ingredients: ingredients,
      energy: energy,
      happiness: happiness,
      cookMinutes: rebuilt.cookMinutes,
      eatMinutes: eatMinutes,
      cookEnergyCost: rebuilt.cookEnergyCost,
      emoji: rebuilt.emoji,
      accent: rebuilt.accent,
      accentDeep: rebuilt.accentDeep,
    );
  }

  /// Resolves any plated meal id (fixed recipe or custom plate) into the
  /// common table-facing shape.
  static CookedMeal? servingFor(String mealId) {
    final recipe = byMealId(mealId);
    if (recipe != null) return recipe.toMeal();
    return customMealFromId(mealId)?.meal;
  }

  static String customMealName(Map<String, int> ingredients) {
    final total = ingredients.values.fold(0, (sum, count) => sum + count);
    final base = ingredients.containsKey('rice')
        ? 'Rice Bowl'
        : ingredients.containsKey('noodles')
        ? 'Noodle Pot'
        : ingredients.containsKey('bread')
        ? (ingredients.containsKey('egg') ? 'Breakfast Plate' : 'Griddle Plate')
        : ingredients.containsKey('chicken')
        ? 'Chicken Skillet'
        : 'Garden Plate';
    final prefix = total >= 5
        ? 'Hearty'
        : total >= 3
        ? 'Golden'
        : 'Little';
    return '$prefix $base';
  }
}
