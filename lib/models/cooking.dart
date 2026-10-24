import 'package:flutter/material.dart' hide DayPeriod;

import 'game_time.dart';

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
  });

  final String id;
  final String name;
  final String emoji;
  final Color color;
}

class PantryCatalog {
  const PantryCatalog._();

  static const List<PantryIngredient> ingredients = [
    PantryIngredient(
      id: 'bread',
      name: 'Bread',
      emoji: '🍞',
      color: Color(0xFFD9A066),
    ),
    PantryIngredient(
      id: 'egg',
      name: 'Eggs',
      emoji: '🥚',
      color: Color(0xFFF3E3B5),
    ),
    PantryIngredient(
      id: 'milk',
      name: 'Milk',
      emoji: '🥛',
      color: Color(0xFFBFD7EA),
    ),
    PantryIngredient(
      id: 'rice',
      name: 'Rice',
      emoji: '🍚',
      color: Color(0xFFE8DCC8),
    ),
    PantryIngredient(
      id: 'chicken',
      name: 'Chicken',
      emoji: '🍗',
      color: Color(0xFFD98E73),
    ),
    PantryIngredient(
      id: 'vegetables',
      name: 'Veggies',
      emoji: '🥦',
      color: Color(0xFF74A96B),
    ),
    PantryIngredient(
      id: 'noodles',
      name: 'Noodles',
      emoji: '🍜',
      color: Color(0xFFE4B363),
    ),
    PantryIngredient(
      id: 'tomato',
      name: 'Tomatoes',
      emoji: '🍅',
      color: Color(0xFFD9534F),
    ),
    PantryIngredient(
      id: 'cheese',
      name: 'Cheese',
      emoji: '🧀',
      color: Color(0xFFF2C94C),
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

/// A cookable meal. Ingredients are consumed when cooking; the finished
/// meal is added to the inventory as [mealId] and can then be eaten at the
/// dining table.
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

class CookingCatalog {
  const CookingCatalog._();

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
}
