import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/state/game_state.dart';
import '../../models/game_time.dart';
import '../../models/quest_model.dart';
import 'phone_ui.dart';

/// The in-game phone's Week Planner: a realistic weekly calendar that lays out
/// the player's typical commitments — school periods, meals, sleep, free time
/// and any active quests — day by day, with the current day highlighted.
class CalendarApp extends ConsumerWidget {
  const CalendarApp({super.key});

  static const Color _sleep = Color(0xFF1F2430);
  static const Color _school = kPhoneGreen;
  static const Color _class = kPhoneBlue;
  static const Color _meal = kPhoneRose;
  static const Color _free = kPhonePanelSoft;
  static const Color _quest = kPhoneAmber;

  /// Subject rotation mirrored from the school portal so the planner stays
  /// consistent with what the player actually experiences in-game.
  static final Map<Weekday, List<String>> _subjects = {
    Weekday.monday: ['Mathematics', 'Science', 'English', 'Filipino'],
    Weekday.tuesday: ['Science', 'English', 'Mathematics', 'PE'],
    Weekday.wednesday: ['English', 'Filipino', 'Science', 'Computer Lab'],
    Weekday.thursday: ['Mathematics', 'History', 'English', 'Science'],
    Weekday.friday: ['Filipino', 'Mathematics', 'Computer Lab', 'PE'],
  };

  static final Map<Weekday, List<int>> _slotStarts = {
    Weekday.monday: [8 * 60, 10 * 60, 12 * 60 + 30, 14 * 60],
    Weekday.tuesday: [8 * 60, 10 * 60, 12 * 60 + 30, 14 * 60],
    Weekday.wednesday: [8 * 60, 10 * 60, 12 * 60 + 30, 14 * 60],
    Weekday.thursday: [8 * 60, 10 * 60, 12 * 60 + 30, 14 * 60],
    Weekday.friday: [8 * 60, 10 * 60, 12 * 60 + 30, 14 * 60],
  };

  static final Map<Weekday, String> _weekdayLabels = {
    Weekday.monday: 'Monday',
    Weekday.tuesday: 'Tuesday',
    Weekday.wednesday: 'Wednesday',
    Weekday.thursday: 'Thursday',
    Weekday.friday: 'Friday',
    Weekday.saturday: 'Saturday',
    Weekday.sunday: 'Sunday',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(gameStateProvider);
    final now = gs.time;
    final today = now.weekday.index;

    return PhoneAppScaffold(
      title: 'Week Planner',
      subtitle:
          '${now.weekdayLabel}, Day ${now.day} · ${now.clockLabel} · ${_activeToday(gs, now.weekday)}',
      icon: Icons.calendar_month_rounded,
      accent: kPhoneAmber,
      child: Column(
        children: [
          const _WeekLegend(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 14),
              itemCount: 7,
              separatorBuilder: (_, __) => const SizedBox(height: 7),
              itemBuilder: (_, i) {
                final wd = Weekday.values[i];
                return _DayPanel(gs: gs, weekday: wd, isToday: i == today);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _activeToday(GameState gs, Weekday wd) {
    final today = gs.quests.values.where(
      (q) => q.status == QuestStatus.active &&
          (q.requiresDay == 0 || q.requiresDay <= gs.time.day),
    );
    if (today.isNotEmpty) return '${today.length} quest active today';
    final avail = gs.quests.values.where(
      (q) => q.status == QuestStatus.available &&
          q.canUnlock(
            flags: gs.flags,
            quests: gs.quests,
            relationship: gs.npcs[q.npcId]?.relationship ?? 0,
            day: gs.time.day,
            intelligence: gs.player.intelligence,
            charm: gs.player.charm,
            strength: gs.player.strength,
          ),
    );
    if (avail.isNotEmpty) return '${avail.length} quest ready to start';
    return 'No quests scheduled today';
  }
}

class _WeekLegend extends StatelessWidget {
  const _WeekLegend();

  @override
  Widget build(BuildContext context) {
    final entries = [
      _LegendItem('Sleep', CalendarApp._sleep),
      _LegendItem('School', CalendarApp._school),
      _LegendItem('Class', CalendarApp._class),
      _LegendItem('Meal', CalendarApp._meal),
      _LegendItem('Free', CalendarApp._free),
      _LegendItem('Quest', CalendarApp._quest),
    ];
    return SizedBox(
      height: 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => entries[i],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: kPhoneMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.gs, required this.weekday, required this.isToday});

  final GameState gs;
  final Weekday weekday;
  final bool isToday;

  List<_Block> _blocks() {
    final out = <_Block>[];
    final schoolDay = weekday != Weekday.saturday && weekday != Weekday.sunday;

    out.add(_Block(21 * 60, 24 * 60, 'Sleep', 'Rest until morning', CalendarApp._sleep, true));
    out.add(_Block(0, 7 * 60, 'Sleep', 'Rest until morning', CalendarApp._sleep, true));

    if (schoolDay) {
      out.add(_Block(7 * 60, 8 * 60, 'Morning routine', 'Breakfast & get ready', CalendarApp._meal, false));
      final subjects = CalendarApp._subjects[weekday] ?? const [];
      final starts = CalendarApp._slotStarts[weekday] ?? const [];
      for (var i = 0; i < subjects.length; i++) {
        final start = starts[i];
        final end = start + 90;
        out.add(_Block(start, end, subjects[i], 'In session', CalendarApp._class, true));
        if (i == 0) {
          out.add(_Block(end, end + 30, 'Break', 'Snack & stretch', CalendarApp._free, false));
        }
        if (i == 1) {
          out.add(_Block(end, end + 60, 'Lunch', 'Canteen', CalendarApp._meal, false));
        }
      }
      out.add(_Block(15 * 60 + 30, 17 * 60, 'After school', 'Free time / clubs', CalendarApp._free, false));
      out.add(_Block(17 * 60, 19 * 60, 'Evening', 'Homework / unwind', CalendarApp._free, false));
    } else {
      out.add(_Block(8 * 60, 10 * 60, 'Sleep in', 'Slow morning', CalendarApp._free, false));
      out.add(_Block(10 * 60, 12 * 60, 'Free time', 'Open schedule', CalendarApp._free, false));
      out.add(_Block(12 * 60, 13 * 60, 'Lunch', 'Midday meal', CalendarApp._meal, false));
      out.add(_Block(13 * 60, 17 * 60, 'Weekend activity', 'Hobbies / errands', CalendarApp._free, false));
      out.add(_Block(17 * 60, 19 * 60, 'Dinner', 'Evening meal', CalendarApp._meal, false));
      out.add(_Block(19 * 60, 21 * 60, 'Evening', 'Relax', CalendarApp._free, false));
    }

    for (final q in gs.quests.values) {
      if (q.status == QuestStatus.active || q.status == QuestStatus.available) {
        final reqDay = q.requiresDay;
        if (reqDay == 0 || reqDay <= gs.time.day) {
          out.add(
            _Block(16 * 60, 17 * 60, 'Quest: ${q.title}', q.description, CalendarApp._quest, false),
          );
        }
      }
    }

    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  String _label(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  bool _isSchoolDay() {
    return weekday != Weekday.saturday && weekday != Weekday.sunday;
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _blocks();
    final now = gs.time;
    final nowMinutes = now.hour * 60 + now.minute;
    final current = isToday
        ? blocks.firstWhereOrNull((b) => nowMinutes >= b.start && nowMinutes < b.end)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: isToday ? kPhonePanel : kPhonePanelSoft,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: kPhoneAmber.withValues(alpha: 0.6), width: 2)
            : Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isToday ? kPhoneAmber : kPhoneMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${CalendarApp._weekdayLabels[weekday]}${isToday ? ' · TODAY' : ''}',
                  style: const TextStyle(
                    color: kPhoneInk,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _isSchoolDay() ? 'School day' : 'Weekend',
                style: TextStyle(
                  color: kPhoneMuted.withValues(alpha: 0.8),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (current != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: current.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: current.color.withValues(alpha: 0.5), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_arrow_rounded, color: kPhoneAmber, size: 13),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Now: ${current.label}${current.sub != null && current.sub!.isNotEmpty ? ' · ${current.sub}' : ''}',
                      style: const TextStyle(
                        color: kPhoneInk,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
          ],
          ...blocks.map((b) => _BlockRow(block: b, isCurrent: current == b)),
        ],
      ),
    );
  }
}

class _Block {
  final int start;
  final int end;
  final String label;
  final String? sub;
  final Color color;
  final bool fixed;
  _Block(this.start, this.end, this.label, [this.sub = '', this.color = CalendarApp._free, this.fixed = false]);
}

String _label(int minutes) {
  final h = (minutes ~/ 60) % 24;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({required this.block, required this.isCurrent});

  final _Block block;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${_label(block.start)} – ${_label(block.end)}',
              style: TextStyle(
                color: kPhoneMuted.withValues(alpha: 0.85),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 7, height: 7, decoration: BoxDecoration(color: block.color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  block.label,
                  style: TextStyle(
                    color: isCurrent ? kPhoneAmber : kPhoneInk,
                    fontSize: 12,
                    fontWeight: isCurrent || block.fixed ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                if (block.sub != null && block.sub!.isNotEmpty)
                  Text(
                    block.sub!,
                    style: TextStyle(
                      color: kPhoneMuted.withValues(alpha: 0.8),
                      fontSize: 9.5,
                    ),
                  ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: kPhoneAmber, borderRadius: BorderRadius.circular(6)),
              child: const Text(
                'NOW',
                style: TextStyle(color: Color(0xFF07110B), fontSize: 8, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}
