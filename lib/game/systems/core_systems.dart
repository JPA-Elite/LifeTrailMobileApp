class ActivityConfig {
  final String id;
  final int minutes;
  final int energyDelta;
  final int happinessDelta;
  final int healthDelta;

  const ActivityConfig({
    required this.id,
    required this.minutes,
    this.energyDelta = 0,
    this.happinessDelta = 0,
    this.healthDelta = 0,
  });
}

class Activities {
  static const configs = <String, ActivityConfig>{
    'walk': ActivityConfig(id: 'walk', minutes: 20, energyDelta: -2),
    'eat': ActivityConfig(id: 'eat', minutes: 30, energyDelta: 10),
    'study': ActivityConfig(id: 'study', minutes: 60, energyDelta: -10),
    'talk': ActivityConfig(id: 'talk', minutes: 30, energyDelta: -5),
    'work': ActivityConfig(id: 'work', minutes: 180, energyDelta: -25),
    'church': ActivityConfig(id: 'church', minutes: 90, energyDelta: -5),
    'exercise': ActivityConfig(id: 'exercise', minutes: 60, energyDelta: -15),
    'rest': ActivityConfig(id: 'rest', minutes: 30, energyDelta: 20),
    'class': ActivityConfig(id: 'class', minutes: 90, energyDelta: -8),
  };

  static ActivityConfig of(String id) => configs[id] ?? configs['walk']!;
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
