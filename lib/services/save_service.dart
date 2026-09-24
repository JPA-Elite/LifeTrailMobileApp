import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_model.dart';
import '../models/game_time.dart';
import '../models/npc_model.dart';
import '../models/quest_model.dart';
import '../models/item_model.dart';

abstract class SaveService {
  Future<void> saveGame(String slot, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> loadGame(String slot);
  Future<bool> hasSave(String slot);
  Future<void> deleteSave(String slot);
  Future<List<Map<String, dynamic>>> slotSummaries();
}

class PrefsSaveService implements SaveService {
  static const _prefix = 'lifetrail_save_';
  static const slots = ['slot1', 'slot2', 'slot3'];

  @override
  Future<void> saveGame(String slot, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$slot', json.encode(data));
  }

  @override
  Future<Map<String, dynamic>?> loadGame(String slot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$slot');
      if (raw == null) return null;
      return Map<String, dynamic>.from(json.decode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> hasSave(String slot) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_prefix$slot');
  }

  @override
  Future<void> deleteSave(String slot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$slot');
  }

  @override
  Future<List<Map<String, dynamic>>> slotSummaries() async {
    final out = <Map<String, dynamic>>[];
    for (final slot in slots) {
      final data = await loadGame(slot);
      if (data == null) {
        out.add({'slot': slot, 'empty': true});
      } else {
        try {
          final player = PlayerModel.fromJson(
            Map<String, dynamic>.from(data['player'] as Map),
          );
          final time = GameTime.fromJson(
            Map<String, dynamic>.from(data['time'] as Map),
          );
          out.add({
            'slot': slot,
            'empty': false,
            'day': time.day,
            'money': player.money,
            'chapter': data['chapter'] ?? 1,
          });
        } catch (_) {
          out.add({'slot': slot, 'empty': true, 'corrupt': true});
        }
      }
    }
    return out;
  }
}

Map<String, dynamic> buildSaveData({
  required PlayerModel player,
  required GameTime time,
  required Map<String, NpcModel> npcs,
  required Map<String, QuestModel> quests,
  required Map<String, int> flags,
  required List<InventoryStack> inventory,
  required String weather,
  required int chapter,
}) => {
  'player': player.toJson(),
  'time': time.toJson(),
  'npcs': npcs.map((k, v) => MapEntry(k, v.relationship)),
  'quests': quests.map((k, v) => MapEntry(k, v.toJson())),
  'flags': flags,
  'inventory': inventory.map((e) => e.toJson()).toList(),
  'weather': weather,
  'chapter': chapter,
  'savedAt': DateTime.now().toIso8601String(),
};
