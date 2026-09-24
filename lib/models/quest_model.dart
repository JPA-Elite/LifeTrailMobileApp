enum QuestStatus { locked, available, active, completed, failed }

class QuestObjective {
  final String id;
  final String description;
  final bool done;

  const QuestObjective({
    required this.id,
    required this.description,
    this.done = false,
  });

  QuestObjective copyWith({bool? done}) =>
      QuestObjective(id: id, description: description, done: done ?? this.done);

  factory QuestObjective.fromJson(Map<String, dynamic> json) => QuestObjective(
    id: json['id'] as String,
    description: json['description'] as String? ?? '',
    done: json['done'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'done': done,
  };
}

class QuestModel {
  final String id;
  final String title;
  final String description;
  final String npcId;
  final List<QuestObjective> objectives;
  final int rewardMoney;
  final int rewardRelationship;
  final String? rewardFlag;
  final QuestStatus status;
  // Summertime Saga: prerequisites to unlock (AND logic)
  final List<String> requiresFlags;
  final String? requiresQuest; // must be completed
  final int requiresRelationship;
  final int requiresDay;
  final int requiresIntelligence;
  final int requiresCharm;
  final int requiresStrength;

  const QuestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.npcId,
    this.objectives = const [],
    this.rewardMoney = 0,
    this.rewardRelationship = 0,
    this.rewardFlag,
    this.status = QuestStatus.available,
    this.requiresFlags = const [],
    this.requiresQuest,
    this.requiresRelationship = 0,
    this.requiresDay = 0,
    this.requiresIntelligence = 0,
    this.requiresCharm = 0,
    this.requiresStrength = 0,
  });

  bool get isComplete =>
      objectives.isNotEmpty && objectives.every((o) => o.done);

  bool canUnlock({
    required Map<String, int> flags,
    required Map<String, QuestModel> quests,
    required int relationship,
    required int day,
    required int intelligence,
    required int charm,
    required int strength,
  }) {
    if (requiresQuest != null) {
      final q = quests[requiresQuest];
      if (q == null || q.status != QuestStatus.completed) return false;
    }
    for (final f in requiresFlags) {
      if ((flags[f] ?? 0) == 0) return false;
    }
    if (relationship < requiresRelationship) return false;
    if (day < requiresDay) return false;
    if (intelligence < requiresIntelligence) return false;
    if (charm < requiresCharm) return false;
    if (strength < requiresStrength) return false;
    return true;
  }

  QuestModel copyWith({
    List<QuestObjective>? objectives,
    QuestStatus? status,
  }) => QuestModel(
    id: id,
    title: title,
    description: description,
    npcId: npcId,
    objectives: objectives ?? this.objectives,
    rewardMoney: rewardMoney,
    rewardRelationship: rewardRelationship,
    rewardFlag: rewardFlag,
    status: status ?? this.status,
    requiresFlags: requiresFlags,
    requiresQuest: requiresQuest,
    requiresRelationship: requiresRelationship,
    requiresDay: requiresDay,
    requiresIntelligence: requiresIntelligence,
    requiresCharm: requiresCharm,
    requiresStrength: requiresStrength,
  );

  factory QuestModel.fromJson(Map<String, dynamic> json) => QuestModel(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    npcId: json['npcId'] as String? ?? json['npc_id'] as String? ?? '',
    objectives: ((json['objectives'] as List?) ?? [])
        .map(
          (e) => QuestObjective.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    rewardMoney:
        (json['rewardMoney'] as num?)?.toInt() ??
        (json['reward_money'] as num?)?.toInt() ??
        0,
    rewardRelationship: (json['rewardRelationship'] as num?)?.toInt() ?? 0,
    rewardFlag: json['rewardFlag'] as String?,
    status:
        QuestStatus.values.asNameMap()[json['status']] ?? QuestStatus.available,
    requiresFlags: ((json['requiresFlags'] as List?) ?? []).cast<String>(),
    requiresQuest: json['requiresQuest'] as String?,
    requiresRelationship: (json['requiresRelationship'] as num?)?.toInt() ?? 0,
    requiresDay: (json['requiresDay'] as num?)?.toInt() ?? 0,
    requiresIntelligence: (json['requiresIntelligence'] as num?)?.toInt() ?? 0,
    requiresCharm: (json['requiresCharm'] as num?)?.toInt() ?? 0,
    requiresStrength: (json['requiresStrength'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'npcId': npcId,
    'objectives': objectives.map((o) => o.toJson()).toList(),
    'rewardMoney': rewardMoney,
    'rewardRelationship': rewardRelationship,
    'rewardFlag': rewardFlag,
    'status': status.name,
    'requiresFlags': requiresFlags,
    'requiresQuest': requiresQuest,
    'requiresRelationship': requiresRelationship,
    'requiresDay': requiresDay,
    'requiresIntelligence': requiresIntelligence,
    'requiresCharm': requiresCharm,
    'requiresStrength': requiresStrength,
  };
}
