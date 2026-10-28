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
      happinessDelta: -1,
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
    // Browsing shops / window shopping: gentle, cheap, mostly mood.
    'browse': ActivityConfig(
      id: 'browse',
      minutes: 30,
      energyDelta: -4,
      charmDelta: 1,
      happinessDelta: 1,
    ),
    // Reading a volume or a study guide somewhere quiet.
    'read': ActivityConfig(
      id: 'read',
      minutes: 30,
      energyDelta: -4,
      intelligenceDelta: 1,
    ),
    // A short practice quiz: the score decides the reward.
    'quiz': ActivityConfig(id: 'quiz', minutes: 15, energyDelta: -2),
    // Living-room TV. Every channel is a separate visit: picking one spends
    // energy and advances the clock immediately, so the cost is explicit
    // even if the player turns the TV off a moment later.
    'tv_movie': ActivityConfig(
      id: 'tv_movie',
      minutes: 120,
      energyDelta: -8,
      happinessDelta: 3,
    ),
    'tv_internet': ActivityConfig(
      id: 'tv_internet',
      minutes: 60,
      energyDelta: -4,
      intelligenceDelta: 1,
    ),
    'tv_news': ActivityConfig(
      id: 'tv_news',
      minutes: 45,
      energyDelta: -3,
      intelligenceDelta: 1,
    ),
    'tv_cartoon': ActivityConfig(
      id: 'tv_cartoon',
      minutes: 90,
      energyDelta: -6,
      happinessDelta: 2,
    ),
    // Home cooking. Small energy cost for standing at the stove; the meal
    // itself restores much more when eaten at the dining table.
    'cook_breakfast': ActivityConfig(
      id: 'cook_breakfast',
      minutes: 45,
      energyDelta: -4,
      happinessDelta: 1,
    ),
    'cook_lunch': ActivityConfig(
      id: 'cook_lunch',
      minutes: 60,
      energyDelta: -5,
      happinessDelta: 1,
    ),
    'cook_dinner': ActivityConfig(
      id: 'cook_dinner',
      minutes: 60,
      energyDelta: -5,
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
        'weekdays': ['any'],
        'start': 6 * 60,
        'end': 20 * 60 + 30,
      },
    ],
    'bank': [
      {
        'weekdays': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
        'start': 9 * 60,
        'end': 16 * 60,
      },
    ],
    'mall': [
      {
        'weekdays': ['any'],
        'start': 10 * 60,
        'end': 21 * 60,
      },
    ],
    'repair': [
      {
        'weekdays': ['any'],
        'start': 9 * 60,
        'end': 18 * 60,
      },
    ],
    'bookstore': [
      {
        'weekdays': ['any'],
        'start': 9 * 60,
        'end': 20 * 60,
      },
    ],
    'supermarket': [
      {
        'weekdays': ['any'],
        'start': 8 * 60,
        'end': 22 * 60,
      },
    ],
    'pizzahut': [
      {
        'weekdays': ['any'],
        'start': 11 * 60,
        'end': 22 * 60,
      },
    ],
    'hospital': [], // always open
    'restaurant': [
      {
        'weekdays': ['any'],
        'start': 11 * 60,
        'end': 22 * 60,
      },
    ],
    'laundry': [
      {
        'weekdays': ['any'],
        'start': 8 * 60,
        'end': 20 * 60,
      },
    ],
    'police': [], // always open
    'computer': [
      {
        'weekdays': ['any'],
        'start': 9 * 60,
        'end': 21 * 60,
      },
    ],
    'amusement': [
      {
        'weekdays': ['any'],
        'start': 10 * 60,
        'end': 21 * 60,
      },
    ],
    'beach': [], // always open
    'fishing': [], // always open
    'hotel': [], // always open
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

  /// True when the place never closes (hospital, police, beach, hotel…).
  static bool isAlwaysOpen(String locationId) =>
      (hours[locationId] ?? const []).isEmpty;

  /// Human title used by menus and door messages.
  static String name(String locationId) {
    switch (locationId) {
      case 'home':
        return 'Home';
      case 'school':
        return 'School';
      case 'plaza':
        return 'Plaza';
      case 'church':
        return 'Church';
      case 'park':
        return 'Park';
      case 'workplace':
        return 'Sunbeam Café';
      case 'bank':
        return 'First Bank';
      case 'mall':
        return 'Grand Mall';
      case 'repair':
        return 'Fix-It Repair';
      case 'bookstore':
        return 'Book Store';
      case 'supermarket':
        return 'Super Market';
      case 'pizzahut':
        return 'Pizza Hut';
      case 'hospital':
        return 'Hospital';
      case 'restaurant':
        return 'Restaurant';
      case 'laundry':
        return 'Laundry Shop';
      case 'police':
        return 'Police Station';
      case 'computer':
        return 'Computer Center';
      case 'amusement':
        return 'Amusement Park';
      case 'beach':
        return 'Beach';
      case 'fishing':
        return 'Fishing Area';
      case 'hotel':
        return 'Hotel';
      default:
        return locationId;
    }
  }

  /// Opening hours in the same words the menus use.
  static String label(String locationId) {
    if (isAlwaysOpen(locationId)) return 'Always open';
    switch (locationId) {
      case 'school':
        return 'Mon–Fri 08:00–15:30';
      case 'plaza':
        return 'Daily 07:00–20:00';
      case 'church':
        return 'Sun 09:00–13:00, Sat 15:00–18:00';
      case 'park':
        return 'Daily 06:00–21:00';
      case 'workplace':
        return 'Daily 06:00–20:30';
      case 'bank':
        return 'Mon–Fri 09:00–16:00';
      case 'mall':
        return 'Daily 10:00–21:00';
      case 'repair':
        return 'Daily 09:00–18:00';
      case 'bookstore':
        return 'Daily 09:00–20:00';
      case 'supermarket':
        return 'Daily 08:00–22:00';
      case 'pizzahut':
        return 'Daily 11:00–22:00';
      case 'restaurant':
        return 'Daily 11:00–22:00';
      case 'laundry':
        return 'Daily 08:00–20:00';
      case 'computer':
        return 'Daily 09:00–21:00';
      case 'amusement':
        return 'Daily 10:00–21:00';
      default:
        return '—';
    }
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
