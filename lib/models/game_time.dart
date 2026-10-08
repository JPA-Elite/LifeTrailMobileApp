enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

enum DayPeriod { morning, afternoon, evening, night }

class GameTime {
  final int day;
  final int minutes;

  const GameTime({required this.day, required this.minutes});

  factory GameTime.morning(int day) => GameTime(day: day, minutes: 7 * 60);

  int get hour => minutes ~/ 60;
  int get minute => minutes % 60;

  Weekday get weekday => Weekday.values[(day - 1) % 7];

  DayPeriod get period {
    if (hour >= 5 && hour < 12) return DayPeriod.morning;
    if (hour >= 12 && hour < 17) return DayPeriod.afternoon;
    if (hour >= 17 && hour < 21) return DayPeriod.evening;
    return DayPeriod.night;
  }

  /// True during night scenario (21:00–04:59): buildings lock except home.
  bool get isNight => period == DayPeriod.night;

  /// Display label for the day scenario: Morning / Afternoon / Evening / Night.
  String get periodLabel {
    switch (period) {
      case DayPeriod.morning:
        return 'Morning';
      case DayPeriod.afternoon:
        return 'Afternoon';
      case DayPeriod.evening:
        return 'Evening';
      case DayPeriod.night:
        return 'Night';
    }
  }

  bool get isSchoolDay =>
      weekday != Weekday.saturday && weekday != Weekday.sunday;

  String get clockLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get weekdayLabel {
    switch (weekday) {
      case Weekday.monday:
        return 'Monday';
      case Weekday.tuesday:
        return 'Tuesday';
      case Weekday.wednesday:
        return 'Wednesday';
      case Weekday.thursday:
        return 'Thursday';
      case Weekday.friday:
        return 'Friday';
      case Weekday.saturday:
        return 'Saturday';
      case Weekday.sunday:
        return 'Sunday';
    }
  }

  GameTime addMinutes(int delta) {
    var total = minutes + delta;
    var d = day;
    while (total >= 24 * 60) {
      total -= 24 * 60;
      d += 1;
    }
    while (total < 0) {
      total += 24 * 60;
      d -= 1;
      if (d < 1) {
        d = 1;
        total = 0;
        break;
      }
    }
    return GameTime(day: d, minutes: total);
  }

  Map<String, dynamic> toJson() => {'day': day, 'minutes': minutes};

  factory GameTime.fromJson(Map<String, dynamic> json) => GameTime(
    day: (json['day'] as num?)?.toInt() ?? 1,
    minutes: (json['minutes'] as num?)?.toInt() ?? 7 * 60,
  );
}
