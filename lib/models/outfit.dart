import 'package:flutter/material.dart';

/// Decorative treatment applied to a garment.
enum OutfitPattern { solid, stripe, pocket, star, heart, trim }

/// One wearable piece in the player's wardrobe.
class OutfitItem {
  /// Display name, e.g. "Coral Classic".
  final String name;

  /// One-word mood used to name a complete look, e.g. "Sunny".
  final String vibe;

  final Color primary;
  final Color accent;
  final OutfitPattern pattern;

  const OutfitItem({
    required this.name,
    required this.vibe,
    required this.primary,
    required this.accent,
    required this.pattern,
  });
}

/// The five default tees and five default shorts the player owns.
///
/// Index 0 in both lists is the look the player starts the game in, so old
/// saves keep their original coral tee and denim shorts.
class OutfitCatalog {
  const OutfitCatalog._();

  static const List<OutfitItem> shirts = [
    OutfitItem(
      name: 'Coral Classic',
      vibe: 'Sunny',
      primary: Color(0xFFE06666),
      accent: Color(0xFFFFE3D6),
      pattern: OutfitPattern.solid,
    ),
    OutfitItem(
      name: 'Mint Fresh',
      vibe: 'Fresh',
      primary: Color(0xFF7FC8A9),
      accent: Color(0xFF1F5A4A),
      pattern: OutfitPattern.pocket,
    ),
    OutfitItem(
      name: 'Midnight Star',
      vibe: 'Bold',
      primary: Color(0xFF3D4C7A),
      accent: Color(0xFFFFD166),
      pattern: OutfitPattern.star,
    ),
    OutfitItem(
      name: 'Lemon Pop',
      vibe: 'Bright',
      primary: Color(0xFFF2C94C),
      accent: Color(0xFF8A5A00),
      pattern: OutfitPattern.stripe,
    ),
    OutfitItem(
      name: 'Lavender Haze',
      vibe: 'Calm',
      primary: Color(0xFFB39DDB),
      accent: Color(0xFF5E4B8B),
      pattern: OutfitPattern.heart,
    ),
  ];

  static const List<OutfitItem> shorts = [
    OutfitItem(
      name: 'Denim Days',
      vibe: 'Everyday',
      primary: Color(0xFF3B5B80),
      accent: Color(0xFFA8C6E8),
      pattern: OutfitPattern.trim,
    ),
    OutfitItem(
      name: 'Sage Stroll',
      vibe: 'Easy',
      primary: Color(0xFF7A9A72),
      accent: Color(0xFFDDE8D5),
      pattern: OutfitPattern.pocket,
    ),
    OutfitItem(
      name: 'Cocoa Comfort',
      vibe: 'Cozy',
      primary: Color(0xFF8B5E4A),
      accent: Color(0xFFF0D6B8),
      pattern: OutfitPattern.solid,
    ),
    OutfitItem(
      name: 'Cherry Sprint',
      vibe: 'Sporty',
      primary: Color(0xFFC0392B),
      accent: Color(0xFFFFE3D6),
      pattern: OutfitPattern.stripe,
    ),
    OutfitItem(
      name: 'Sky Bound',
      vibe: 'Adventure',
      primary: Color(0xFF5DADE2),
      accent: Color(0xFFFFFFFF),
      pattern: OutfitPattern.star,
    ),
  ];

  static int clampShirt(int index) => index.clamp(0, shirts.length - 1).toInt();

  static int clampShorts(int index) =>
      index.clamp(0, shorts.length - 1).toInt();

  static OutfitItem shirtAt(int index) => shirts[clampShirt(index)];

  static OutfitItem shortsAt(int index) => shorts[clampShorts(index)];

  /// A short, readable name for the current combination.
  static String lookName(int shirtIndex, int shortsIndex) =>
      '${shirtAt(shirtIndex).vibe} ${shortsAt(shortsIndex).vibe}';
}
