import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/npc_model.dart';
import '../models/quest_model.dart';
import '../models/item_model.dart';
import '../models/location_dialogue.dart';

class GameDataService {
  static final GameDataService _instance = GameDataService._();
  factory GameDataService() => _instance;
  GameDataService._();

  Map<String, NpcModel> npcs = {};
  Map<String, QuestModel> quests = {};
  Map<String, ItemModel> items = {};
  Map<String, List<DialogueNode>> dialogues = {};
  Map<String, List<Map<String, dynamic>>> quizBySubject = {};

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> loadAll() async {
    if (_ready) return;
    npcs = await _loadNpcs();
    quests = await _loadQuests();
    items = await _loadItems();
    dialogues = await _loadDialogues();
    quizBySubject = await _loadQuiz();
    _ready = true;
  }

  Future<Map<String, NpcModel>> _loadNpcs() async {
    final raw = await _readJson('assets/data/npcs/npcs.json');
    final list = (raw['npcs'] as List?) ?? [];
    return {
      for (final e in list)
        (e['id'] as String): NpcModel.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
    };
  }

  Future<Map<String, QuestModel>> _loadQuests() async {
    final raw = await _readJson('assets/data/quests/quests.json');
    final list = (raw['quests'] as List?) ?? [];
    return {
      for (final e in list)
        (e['id'] as String): QuestModel.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
    };
  }

  Future<Map<String, ItemModel>> _loadItems() async {
    final raw = await _readJson('assets/data/items/items.json');
    final list = (raw['items'] as List?) ?? [];
    return {
      for (final e in list)
        (e['id'] as String): ItemModel.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
    };
  }

  Future<Map<String, List<DialogueNode>>> _loadDialogues() async {
    final out = <String, List<DialogueNode>>{};
    for (final id in ['alex', 'maria', 'ben']) {
      try {
        final raw = await _readJson('assets/data/dialogue/$id.json');
        final list = (raw['nodes'] as List?) ?? [];
        out[id] = list
            .map(
              (e) => DialogueNode.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      } catch (_) {
        out[id] = [];
      }
    }
    return out;
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadQuiz() async {
    try {
      final raw = await _readJson('assets/data/school/quiz.json');
      final map = Map<String, dynamic>.from(raw['subjects'] as Map? ?? {});
      return map.map(
        (k, v) => MapEntry(
          k,
          (v as List).map((e) => Map<String, dynamic>.from(e)).toList(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _readJson(String path) async {
    final text = await rootBundle.loadString(path);
    return Map<String, dynamic>.from(json.decode(text) as Map);
  }
}
