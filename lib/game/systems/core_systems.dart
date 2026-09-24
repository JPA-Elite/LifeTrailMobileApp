class ActivityConfig {
  final String id;
  final int minutes;
  final int energyDelta;
  final int happinessDelta;
  final int healthDelta;
  final int intelligenceDelta;
  final int strengthDelta;
  final int charmDelta;
  final int educationDelta;

  const ActivityConfig({
    required this.id,
    required this.minutes,
    this.energyDelta = 0,
    this.happinessDelta = 0,
    this.healthDelta = 0,
    this.intelligenceDelta = 0,
    this.strengthDelta = 0,
    this.charmDelta = 0,
    this.educationDelta = 0,
  });
}

class Activities {
  // Summertime Saga: actions cost time+energy and train stats via
  // location-specific methods (school=int, gym=str, plaza/church=charm)
  static const configs = <String, ActivityConfig>{
    'walk': ActivityConfig(id: 'walk', minutes: 20, energyDelta: -2),
    'eat': ActivityConfig(
      id: 'eat',
      minutes: 30,
      energyDelta: 10,
      happinessDelta: 1,
    ),
    'study': ActivityConfig(
      id: 'study',
      minutes: 60,
      energyDelta: -10,
      intelligenceDelta: 1,
      educationDelta: 1,
    ),
    'talk': ActivityConfig(
      id: 'talk',
      minutes: 30,
      energyDelta: -5,
      charmDelta: 1,
      happinessDelta: 1,
    ),
    'work': ActivityConfig(
      id: 'work',
      minutes: 180,
      energyDelta: -25,
      charmDelta: 1,
    ),
    'church': ActivityConfig(
      id: 'church',
      minutes: 90,
      energyDelta: -5,
      charmDelta: 1,
      happinessDelta: 1,
    ),
    'exercise': ActivityConfig(
      id: 'exercise',
      minutes: 60,
      energyDelta: -15,
      strengthDelta: 2,
      healthDelta: 1,
    ),
    'rest': ActivityConfig(
      id: 'rest',
      minutes: 30,
      energyDelta: 20,
      healthDelta: 1,
    ),
    'class': ActivityConfig(
      id: 'class',
      minutes: 90,
      energyDelta: -8,
      intelligenceDelta: 1,
      educationDelta: 2,
    ),
    'gym': ActivityConfig(
      id: 'gym',
      minutes: 60,
      energyDelta: -15,
      strengthDelta: 2,
    ),
    'socialize': ActivityConfig(
      id: 'socialize',
      minutes: 45,
      energyDelta: -5,
      charmDelta: 2,
      happinessDelta: 1,
    ),
  };

  static ActivityConfig of(String id) => configs[id] ?? configs['walk']!;
}

/// Summertime Saga–style opening hours per location (inclusive start, exclusive end)
class LocationHours {
  static const Map<String, List<Map<String, dynamic>>> hours = {
    'home': [], // always open
    'school': [
      {
        'weekdays': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
        'start': 8 * 60,
        'end': 15 * 60 + 30,
      },
    ],
    'plaza': [
      {
        'weekdays': ['any'],
        'start': 7 * 60,
        'end': 20 * 60,
      },
    ],
    'church': [
      {
        'weekdays': ['sunday'],
        'start': 9 * 60,
        'end': 13 * 60,
      },
      {
        'weekdays': ['saturday'],
        'start': 15 * 60,
        'end': 18 * 60,
      },
    ],
    'park': [
      {
        'weekdays': ['any'],
        'start': 6 * 60,
        'end': 21 * 60,
      },
    ],
    'workplace': [
      {
        'weekdays': [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
        ],
        'start': 17 * 60,
        'end': 20 * 60 + 30,
      },
    ],
  };

  static bool isOpen(String locationId, String weekdayLabel, int minutes) {
    final rules = hours[locationId];
    if (rules == null || rules.isEmpty) return true;
    final day = weekdayLabel.toLowerCase();
    for (final r in rules) {
      final days = (r['weekdays'] as List).cast<String>();
      if (!days.contains('any') && !days.contains(day)) continue;
      final s = r['start'] as int;
      final e = r['end'] as int;
      if (minutes >= s && minutes < e) return true;
    }
    return false;
  }
}

class MoneyResult {
  final bool ok;
  final String? reason;
  const MoneyResult(this.ok, [this.reason]);
}

class MoneySystem {
  static MoneyResult canAfford(int balance, int cost) {
    if (cost < 0) return const MoneyResult(false, 'Invalid cost');
    if (balance < cost) return const MoneyResult(false, 'Insufficient funds');
    return const MoneyResult(true);
  }
}

class EnergySystem {
  static bool get isExhausted => false;

  static bool canDo(int energy, int cost) => energy + cost >= 0;

  static bool get isLow => false;
}

class RelationshipSystem {
  static const strangerMax = 19;
  static const acquaintanceMax = 39;
  static const friendMax = 59;
  static const closeFriendMax = 79;

  static String tierName(int value) {
    if (value <= strangerMax) return 'Stranger';
    if (value <= acquaintanceMax) return 'Acquaintance';
    if (value <= friendMax) return 'Friend';
    if (value <= closeFriendMax) return 'Close Friend';
    return 'Best Friend';
  }

  static int add(int current, int delta) => (current + delta).clamp(0, 100);
}

class WeatherKind {
  static const sunny = 'sunny';
  static const cloudy = 'cloudy';
  static const rainy = 'rainy';
  static const storm = 'storm';
}
