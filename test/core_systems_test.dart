import 'package:flutter_test/flutter_test.dart';
import 'package:lifetrail/models/game_time.dart';
import 'package:lifetrail/models/player_model.dart';
import 'package:lifetrail/models/npc_model.dart';
import 'package:lifetrail/models/quest_model.dart';
import 'package:lifetrail/game/systems/core_systems.dart';

void main() {
  group('GameTime', () {
    test('adds minutes within hour', () {
      const t = GameTime(day: 1, minutes: 7 * 60);
      expect(t.addMinutes(30).clockLabel, '07:30');
    });
    test('crosses hour and midnight', () {
      const t = GameTime(day: 1, minutes: 23 * 60 + 45);
      final next = t.addMinutes(30);
      expect(next.day, 2);
      expect(next.clockLabel, '00:15');
    });
    test('weekday cycles', () {
      expect(GameTime(day: 1, minutes: 0).weekday, Weekday.monday);
      expect(GameTime(day: 8, minutes: 0).weekday, Weekday.monday);
      expect(GameTime(day: 6, minutes: 0).weekday, Weekday.saturday);
    });
    test('school day flag', () {
      expect(GameTime(day: 1, minutes: 0).isSchoolDay, isTrue);
      expect(GameTime(day: 6, minutes: 0).isSchoolDay, isFalse);
    });
  });

  group('Money', () {
    test('canAfford blocks overspend', () {
      expect(MoneySystem.canAfford(100, 200).ok, isFalse);
      expect(MoneySystem.canAfford(300, 200).ok, isTrue);
    });
    test('player money clamps', () {
      const p = PlayerModel(money: 10);
      expect(p.copyWith(money: p.money - 50).money, 0);
    });
  });

  group('Energy', () {
    test('consumption and clamp', () {
      const p = PlayerModel(energy: 5);
      expect(p.copyWith(energy: p.energy - 10).energy, 0);
      expect(
        const PlayerModel(energy: 95).copyWith(energy: 95 + 20).energy,
        100,
      );
    });
    test('canDo gate', () {
      expect(EnergySystem.canDo(5, -10), isFalse);
      expect(EnergySystem.canDo(50, -10), isTrue);
    });
  });

  group('Quest', () {
    test('objective completion flips quest', () {
      var q = const QuestModel(
        id: 'q',
        title: 'T',
        description: 'D',
        npcId: 'maria',
        objectives: [
          QuestObjective(id: 'a', description: 'A'),
          QuestObjective(id: 'b', description: 'B'),
        ],
        status: QuestStatus.active,
      );
      q = q.copyWith(
        objectives: q.objectives.map((o) => o.copyWith(done: true)).toList(),
      );
      expect(q.isComplete, isTrue);
    });
  });

  group('Relationship', () {
    test('tiers and bounds', () {
      expect(RelationshipSystem.tierName(0), 'Stranger');
      expect(RelationshipSystem.tierName(35), 'Acquaintance');
      expect(RelationshipSystem.tierName(50), 'Friend');
      expect(RelationshipSystem.tierName(70), 'Close Friend');
      expect(RelationshipSystem.tierName(95), 'Best Friend');
      expect(RelationshipSystem.add(99, 5), 100);
      expect(RelationshipSystem.add(1, -5), 0);
    });
  });

  group('NPC schedule', () {
    test('resolves location by weekday/time', () {
      final npc = NpcModel(
        id: 'alex',
        name: 'Alex',
        schedule: const [
          ScheduleEntry(
            weekday: 'monday',
            start: '08:00',
            end: '15:30',
            location: 'school',
          ),
          ScheduleEntry(
            weekday: 'monday',
            start: '15:30',
            end: '18:00',
            location: 'plaza',
          ),
        ],
      );
      expect(npc.locationFor('monday', 9 * 60), 'school');
      expect(npc.locationFor('monday', 16 * 60), 'plaza');
    });
  });

  group('Save codec', () {
    test('player/time round-trip', () {
      const p = PlayerModel(money: 1250, education: 38);
      final json = p.toJson();
      expect(PlayerModel.fromJson(json).money, 1250);
      const t = GameTime(day: 17, minutes: 23 * 60);
      expect(GameTime.fromJson(t.toJson()).day, 17);
    });
  });
}
