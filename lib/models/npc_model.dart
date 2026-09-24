class ScheduleEntry {
  final String weekday;
  final String start;
  final String end;
  final String location;

  const ScheduleEntry({
    required this.weekday,
    required this.start,
    required this.end,
    required this.location,
  });

  int get startMinutes => _parse(start);
  int get endMinutes => _parse(end);

  static int _parse(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) => ScheduleEntry(
    weekday: json['weekday'] as String? ?? 'any',
    start: json['start'] as String? ?? '00:00',
    end: json['end'] as String? ?? '23:59',
    location: json['location'] as String? ?? 'plaza',
  );

  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'start': start,
    'end': end,
    'location': location,
  };
}

class NpcModel {
  final String id;
  final String name;
  final int age;
  final String personality;
  final List<ScheduleEntry> schedule;
  final int relationship;
  final List<String> questIds;
  final String dialogueId;

  const NpcModel({
    required this.id,
    required this.name,
    this.age = 16,
    this.personality = 'friendly',
    this.schedule = const [],
    this.relationship = 0,
    this.questIds = const [],
    this.dialogueId = '',
  });

  String locationFor(String weekdayLabel, int minutes) {
    final day = weekdayLabel.toLowerCase();
    for (final entry in schedule) {
      if (entry.weekday != 'any' && entry.weekday != day) continue;
      if (minutes >= entry.startMinutes && minutes < entry.endMinutes) {
        return entry.location;
      }
    }
    return schedule.isEmpty ? 'plaza' : schedule.first.location;
  }

  NpcModel copyWith({int? relationship}) => NpcModel(
    id: id,
    name: name,
    age: age,
    personality: personality,
    schedule: schedule,
    relationship: (relationship ?? this.relationship).clamp(0, 100),
    questIds: questIds,
    dialogueId: dialogueId.isEmpty ? id : dialogueId,
  );

  factory NpcModel.fromJson(Map<String, dynamic> json) => NpcModel(
    id: json['id'] as String,
    name: json['name'] as String? ?? json['id'] as String,
    age: (json['age'] as num?)?.toInt() ?? 16,
    personality: json['personality'] as String? ?? 'friendly',
    schedule: ((json['schedule'] as List?) ?? [])
        .map((e) => ScheduleEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    relationship: (json['relationship'] as num?)?.toInt() ?? 0,
    questIds: ((json['questIds'] as List?) ?? []).cast<String>(),
    dialogueId:
        json['dialogueId'] as String? ??
        json['dialogue_id'] as String? ??
        (json['id'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'personality': personality,
    'schedule': schedule.map((e) => e.toJson()).toList(),
    'relationship': relationship,
    'questIds': questIds,
    'dialogueId': dialogueId,
  };
}
