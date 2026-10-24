import 'outfit.dart';

class PlayerModel {
  static const int healthMax = 100;
  static const int energyMax = 100;
  static const int happinessMax = 100;

  final int health;
  final int energy;
  final int happiness;
  final int intelligence;
  final int strength;
  final int charm;
  final int education;
  final int money;
  final String locationId;
  final int attendanceTaken;
  final int attendancePresent;

  /// Index into [OutfitCatalog.shirts] for the tee the player is wearing.
  final int shirtIndex;

  /// Index into [OutfitCatalog.shorts] for the shorts the player is wearing.
  final int shortsIndex;

  const PlayerModel({
    this.health = 85,
    this.energy = 80,
    this.happiness = 72,
    this.intelligence = 10,
    this.strength = 10,
    this.charm = 10,
    this.education = 10,
    this.money = 500,
    this.locationId = 'home',
    this.attendanceTaken = 0,
    this.attendancePresent = 0,
    this.shirtIndex = 0,
    this.shortsIndex = 0,
  });

  double get attendanceRate =>
      attendanceTaken == 0 ? 1.0 : attendancePresent / attendanceTaken;

  // Summertime Saga style stat summary for HUD/checks
  String get statSummary => 'Int $intelligence · Str $strength · Chm $charm';

  PlayerModel copyWith({
    int? health,
    int? energy,
    int? happiness,
    int? intelligence,
    int? strength,
    int? charm,
    int? education,
    int? money,
    String? locationId,
    int? attendanceTaken,
    int? attendancePresent,
    int? shirtIndex,
    int? shortsIndex,
  }) {
    return PlayerModel(
      health: (health ?? this.health).clamp(0, healthMax),
      energy: (energy ?? this.energy).clamp(0, energyMax),
      happiness: (happiness ?? this.happiness).clamp(0, happinessMax),
      intelligence: (intelligence ?? this.intelligence).clamp(0, 999),
      strength: (strength ?? this.strength).clamp(0, 999),
      charm: (charm ?? this.charm).clamp(0, 999),
      education: (education ?? this.education).clamp(0, 999),
      money: (money ?? this.money).clamp(0, 9999999),
      locationId: locationId ?? this.locationId,
      attendanceTaken: attendanceTaken ?? this.attendanceTaken,
      attendancePresent: attendancePresent ?? this.attendancePresent,
      shirtIndex: OutfitCatalog.clampShirt(shirtIndex ?? this.shirtIndex),
      shortsIndex: OutfitCatalog.clampShorts(shortsIndex ?? this.shortsIndex),
    );
  }

  Map<String, dynamic> toJson() => {
    'health': health,
    'energy': energy,
    'happiness': happiness,
    'intelligence': intelligence,
    'strength': strength,
    'charm': charm,
    'education': education,
    'money': money,
    'locationId': locationId,
    'attendanceTaken': attendanceTaken,
    'attendancePresent': attendancePresent,
    'shirtIndex': shirtIndex,
    'shortsIndex': shortsIndex,
  };

  factory PlayerModel.fromJson(Map<String, dynamic> json) => PlayerModel(
    health: (json['health'] as num?)?.toInt() ?? 85,
    energy: (json['energy'] as num?)?.toInt() ?? 80,
    happiness: (json['happiness'] as num?)?.toInt() ?? 72,
    intelligence: (json['intelligence'] as num?)?.toInt() ?? 10,
    strength: (json['strength'] as num?)?.toInt() ?? 10,
    charm: (json['charm'] as num?)?.toInt() ?? 10,
    education: (json['education'] as num?)?.toInt() ?? 10,
    money: (json['money'] as num?)?.toInt() ?? 500,
    locationId: json['locationId'] as String? ?? 'home',
    attendanceTaken: (json['attendanceTaken'] as num?)?.toInt() ?? 0,
    attendancePresent: (json['attendancePresent'] as num?)?.toInt() ?? 0,
    shirtIndex: OutfitCatalog.clampShirt(
      (json['shirtIndex'] as num?)?.toInt() ?? 0,
    ),
    shortsIndex: OutfitCatalog.clampShorts(
      (json['shortsIndex'] as num?)?.toInt() ?? 0,
    ),
  );
}
