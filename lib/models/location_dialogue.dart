class LocationModel {
  final String id;
  final String name;
  final double x;
  final double y;
  final double w;
  final double h;
  final int color;
  final String? interiorHint;

  const LocationModel({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.color,
    this.interiorHint,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
    id: json['id'] as String,
    name: json['name'] as String? ?? json['id'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    w: (json['w'] as num).toDouble(),
    h: (json['h'] as num).toDouble(),
    color: (json['color'] as num).toInt(),
    interiorHint: json['interiorHint'] as String?,
  );
}

class DialogueChoice {
  final String text;
  final String? next;
  final Map<String, int> effects;
  final String? setFlag;

  const DialogueChoice({
    required this.text,
    this.next,
    this.effects = const {},
    this.setFlag,
  });

  factory DialogueChoice.fromJson(Map<String, dynamic> json) => DialogueChoice(
    text: json['text'] as String? ?? '',
    next: json['next'] as String?,
    effects: ((json['effects'] as Map?) ?? {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toInt()),
    ),
    setFlag: json['setFlag'] as String?,
  );
}

class DialogueNode {
  final String id;
  final String speaker;
  final String text;
  final List<DialogueChoice> choices;
  final String? next;

  const DialogueNode({
    required this.id,
    required this.speaker,
    required this.text,
    this.choices = const [],
    this.next,
  });

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
  );
}
