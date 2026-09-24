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
  });

  bool get isComplete =>
      objectives.isNotEmpty && objectives.every((o) => o.done);

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
  };
}
