class LocationModel {
  final String id;
  final String name;
  final double x;
  final double y;
  final double w;
  final double h;
  final int color;
  final String? interiorHint;

  /// Which wall the entrance is on: 'bottom' (default, face south) or 'top'
  /// (face north). Buildings south of the highway have their door on top.
  final String doorSide;

  const LocationModel({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.color,
    this.interiorHint,
    this.doorSide = 'bottom',
  });

  bool get doorOnTop => doorSide == 'top';

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
    id: json['id'] as String,
    name: json['name'] as String? ?? json['id'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    w: (json['w'] as num).toDouble(),
    h: (json['h'] as num).toDouble(),
    color: (json['color'] as num).toInt(),
    interiorHint: json['interiorHint'] as String?,
    doorSide: json['doorSide'] as String? ?? 'bottom',
  );
}

class DialogueChoice {
  final String text;
  final String? next;
  final Map<String, int> effects;
  final String? setFlag;
  // Summertime Saga gates: choice visibility / enable
  final int requiresRelationship;
  final String? requiresFlag;
  final int requiresCharm;
  final int requiresIntelligence;
  final int requiresStrength;

  const DialogueChoice({
    required this.text,
    this.next,
    this.effects = const {},
    this.setFlag,
    this.requiresRelationship = 0,
    this.requiresFlag,
    this.requiresCharm = 0,
    this.requiresIntelligence = 0,
    this.requiresStrength = 0,
  });

  bool isAvailable({
    required int relationship,
    required Map<String, int> flags,
    required int charm,
    required int intelligence,
    required int strength,
  }) {
    if (relationship < requiresRelationship) return false;
    if (requiresFlag != null && (flags[requiresFlag] ?? 0) == 0) return false;
    if (charm < requiresCharm) return false;
    if (intelligence < requiresIntelligence) return false;
    if (strength < requiresStrength) return false;
    return true;
  }

  factory DialogueChoice.fromJson(Map<String, dynamic> json) => DialogueChoice(
    text: json['text'] as String? ?? '',
    next: json['next'] as String?,
    effects: ((json['effects'] as Map?) ?? {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toInt()),
    ),
    setFlag: json['setFlag'] as String?,
    requiresRelationship: (json['requiresRelationship'] as num?)?.toInt() ?? 0,
    requiresFlag: json['requiresFlag'] as String?,
    requiresCharm: (json['requiresCharm'] as num?)?.toInt() ?? 0,
    requiresIntelligence: (json['requiresIntelligence'] as num?)?.toInt() ?? 0,
    requiresStrength: (json['requiresStrength'] as num?)?.toInt() ?? 0,
  );
}

class DialogueNode {
  final String id;
  final String speaker;
  final String text;
  final List<DialogueChoice> choices;
  final String? next;
  // Optional gates per node (like Summertime Saga event conditions)
  final int requiresRelationship;
  final String? requiresFlag;
  final String? requiresQuest; // quest must be active/completed
  final String? questStatus; // e.g. 'active'

  const DialogueNode({
    required this.id,
    required this.speaker,
    required this.text,
    this.choices = const [],
    this.next,
    this.requiresRelationship = 0,
    this.requiresFlag,
    this.requiresQuest,
    this.questStatus,
  });

  bool isAvailable({
    required int relationship,
    required Map<String, int> flags,
    required Map<String, dynamic> quests,
  }) {
    if (relationship < requiresRelationship) return false;
    if (requiresFlag != null && (flags[requiresFlag] ?? 0) == 0) return false;
    if (requiresQuest != null) {
      final q = quests[requiresQuest];
      if (q == null) return false;
      if (questStatus != null) {
        // quests map values may be QuestModel; check via dynamic
        try {
          final status = (q as dynamic).status?.name ?? q['status'];
          if (status != questStatus) return false;
        } catch (_) {
          return false;
        }
      }
    }
    return true;
  }

  factory DialogueNode.fromJson(Map<String, dynamic> json) => DialogueNode(
    id: json['id'] as String,
    speaker: json['speaker'] as String? ?? '',
    text: json['text'] as String? ?? '',
    choices: ((json['choices'] as List?) ?? [])
        .map(
          (e) => DialogueChoice.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    next: json['next'] as String?,
    requiresRelationship: (json['requiresRelationship'] as num?)?.toInt() ?? 0,
    requiresFlag: json['requiresFlag'] as String?,
    requiresQuest: json['requiresQuest'] as String?,
    questStatus: json['questStatus'] as String?,
  );
}
