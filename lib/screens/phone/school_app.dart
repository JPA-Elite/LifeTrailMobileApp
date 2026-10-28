import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/state/game_state.dart';
import '../../models/game_time.dart';
import '../../models/player_model.dart';
import 'phone_ui.dart';

/// A realistic little student portal: today's timetable, subject grades,
/// attendance and campus notices, all built from the live player stats and
/// game clock.
class SchoolApp extends ConsumerStatefulWidget {
  const SchoolApp({super.key});

  @override
  ConsumerState<SchoolApp> createState() => _SchoolAppState();
}

class _SchoolAppState extends ConsumerState<SchoolApp> {
  int _tab = 0;

  static const _tabs = [
    (Icons.today_rounded, 'Today'),
    (Icons.grading_rounded, 'Grades'),
    (Icons.fact_check_outlined, 'Attendance'),
    (Icons.campaign_outlined, 'Notices'),
  ];

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameStateProvider);
    final day = gs.time.weekday;
    final schoolDay = gs.time.isSchoolDay;
    final periods = _periodsFor(day);
    final status = _campusStatus(gs);

    return PhoneAppScaffold(
      title: 'Riverside High',
      subtitle:
          'Student portal · ${gs.time.weekdayLabel} ${gs.time.clockLabel}',
      icon: Icons.school_rounded,
      accent: kPhoneGreen,
      child: Column(
        children: [
          _StudentHero(gs: gs, status: status),
          const SizedBox(height: 9),
          Row(
            children: [
              for (var i = 0; i < _tabs.length; i++) ...[
                Expanded(
                  child: _TabChip(
                    icon: _tabs[i].$1,
                    label: _tabs[i].$2,
                    selected: _tab == i,
                    onTap: () => setState(() => _tab = i),
                  ),
                ),
                if (i < _tabs.length - 1) const SizedBox(width: 5),
              ],
            ],
          ),
          const SizedBox(height: 9),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              child: switch (_tab) {
                0 => _TodayTab(
                  key: const ValueKey('today'),
                  gs: gs,
                  periods: periods,
                  schoolDay: schoolDay,
                ),
                1 => _GradesTab(key: const ValueKey('grades'), player: gs.player),
                2 => _AttendanceTab(
                  key: const ValueKey('attendance'),
                  gs: gs,
                ),
                _ => _NoticesTab(key: const ValueKey('notices'), gs: gs),
              },
            ),
          ),
        ],
      ),
    );
  }

  String _campusStatus(GameState gs) {
    if (!gs.time.isSchoolDay) return 'Weekend · campus closed';
    if (gs.isLocationOpen('school')) return 'Campus open · classes running';
    return 'Campus closed · after hours';
  }
}

class _StudentHero extends StatelessWidget {
  const _StudentHero({required this.gs, required this.status});

  final GameState gs;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123227), Color(0xFF0D1B16)],
        ),
        border: Border.all(color: kPhoneGreen.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPhoneGreen, Color(0xFF3E8A5F)],
              ),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFF07130D),
              size: 24,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grade 10 · Section A',
                  style: TextStyle(
                    color: kPhoneInk,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Student ID LT-2026-0142 · ${gs.time.weekdayLabel}',
                  style: const TextStyle(
                    color: kPhoneMuted,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  status,
                  style: const TextStyle(
                    color: kPhoneGreen,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _MiniStat(
            label: 'EDU',
            value: '${gs.player.education}',
            color: kPhoneGreen,
          ),
          const SizedBox(width: 6),
          _MiniStat(
            label: 'INT',
            value: '${gs.player.intelligence}',
            color: kPhoneBlue,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? kPhoneGreen.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? kPhoneGreen.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.045),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? kPhoneGreen : kPhoneMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? kPhoneInk : kPhoneMuted,
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today
// ---------------------------------------------------------------------------

class _Period {
  const _Period({
    required this.start,
    required this.end,
    required this.subject,
    required this.room,
    required this.teacher,
  });

  final int start;
  final int end;
  final String subject;
  final String room;
  final String teacher;

  String get timeLabel => '${_hm(start)} – ${_hm(end)}';

  bool get isBreak => subject == 'Break' || subject == 'Lunch';

  static String _hm(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';
}

class _TodayTab extends StatelessWidget {
  const _TodayTab({
    super.key,
    required this.gs,
    required this.periods,
    required this.schoolDay,
  });

  final GameState gs;
  final List<_Period> periods;
  final bool schoolDay;

  @override
  Widget build(BuildContext context) {
    final now = gs.time.minutes;
    final next = _firstOrNull(periods.where((p) => p.start > now));
    final current = _firstOrNull(
      periods.where((p) => now >= p.start && now < p.end),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        PhoneCard(
          color: kPhonePanelSoft,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kPhoneGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  schoolDay ? Icons.wb_sunny_outlined : Icons.beach_access,
                  color: kPhoneGreen,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schoolDay
                          ? current == null
                                ? 'No class right now'
                                : 'In ${current.subject} now'
                          : 'No classes today',
                      style: const TextStyle(
                        color: kPhoneInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      !schoolDay
                          ? 'Enjoy the weekend — see you Monday at 08:00.'
                          : current != null
                          ? '${current.room} · ${current.teacher}'
                          : next != null
                          ? 'Next: ${next.subject} at ${_Period._hm(next.start)}'
                          : 'Classes are done for today.',
                      style: const TextStyle(
                        color: kPhoneMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        if (!schoolDay)
          const PhoneEmptyState(
            icon: Icons.weekend_outlined,
            title: 'It’s the weekend',
            message:
                'The timetable is empty. Use the study desk at home if you want a head start.',
            accent: kPhoneGreen,
          )
        else ...[
          for (final period in periods)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _PeriodRow(
                period: period,
                state: now >= period.end
                    ? _PeriodState.done
                    : now >= period.start
                    ? _PeriodState.now
                    : _PeriodState.upcoming,
              ),
            ),
        ],
      ],
    );
  }
}

enum _PeriodState { done, now, upcoming }

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.period, required this.state});

  final _Period period;
  final _PeriodState state;

  @override
  Widget build(BuildContext context) {
    final accent = period.isBreak
        ? kPhoneMuted
        : state == _PeriodState.now
        ? kPhoneGreen
        : state == _PeriodState.done
        ? kPhoneMuted.withValues(alpha: 0.6)
        : kPhoneBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: state == _PeriodState.now
            ? kPhoneGreen.withValues(alpha: 0.08)
            : kPhonePanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state == _PeriodState.now
              ? kPhoneGreen.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.045),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              _Period._hm(period.start),
              style: TextStyle(
                color: state == _PeriodState.now ? kPhoneGreen : kPhoneMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 3,
            height: 28,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        period.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: period.isBreak
                              ? kPhoneMuted
                              : kPhoneInk,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (state == _PeriodState.now) ...[
                      const SizedBox(width: 6),
                      const PhonePill(
                        label: 'NOW',
                        color: kPhoneGreen,
                        dense: true,
                      ),
                    ],
                  ],
                ),
                if (!period.isBreak)
                  Text(
                    '${period.room} · ${period.teacher}',
                    style: const TextStyle(
                      color: kPhoneMuted,
                      fontSize: 10.5,
                    ),
                  ),
              ],
            ),
          ),
          if (state == _PeriodState.done)
            const Icon(
              Icons.check_circle_rounded,
              color: kPhoneGreen,
              size: 16,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grades
// ---------------------------------------------------------------------------

class _GradesTab extends StatelessWidget {
  const _GradesTab({super.key, required this.player});

  final PlayerModel player;

  static const _subjects = [
    ('Mathematics', 'Ms. Reyes', Icons.calculate_outlined),
    ('Science', 'Mr. Santos', Icons.science_outlined),
    ('English', 'Ms. Cruz', Icons.menu_book_outlined),
    ('Filipino', 'Mr. Bautista', Icons.auto_stories_outlined),
    ('History', 'Ms. Lim', Icons.account_balance_outlined),
    ('Computer Lab', 'Mr. Tan', Icons.computer_outlined),
    ('PE', 'Coach Dela Cruz', Icons.sports_basketball_outlined),
  ];

  int _score(int index) {
    final base = 66 + player.education * 1.15 + player.intelligence * 0.75;
    return (base + (index * 3) - 8).round().clamp(55, 99);
  }

  String _letter(int score) {
    if (score >= 92) return 'A';
    if (score >= 86) return 'B+';
    if (score >= 80) return 'B';
    if (score >= 75) return 'C';
    return 'D';
  }

  Color _tint(int score) {
    if (score >= 88) return kPhoneGreen;
    if (score >= 78) return kPhoneBlue;
    return kPhoneAmber;
  }

  @override
  Widget build(BuildContext context) {
    final scores = [
      for (var i = 0; i < _subjects.length; i++) _score(i),
    ];
    final average = scores.reduce((a, b) => a + b) / scores.length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        PhoneCard(
          color: kPhonePanelSoft,
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPhoneGreen.withValues(alpha: 0.12),
                  border: Border.all(
                    color: kPhoneGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  average.toStringAsFixed(1),
                  style: const TextStyle(
                    color: kPhoneGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'General average',
                      style: TextStyle(
                        color: kPhoneInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Second quarter · grades update as you study and attend class.',
                      style: TextStyle(
                        color: kPhoneMuted,
                        fontSize: 10.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        for (var i = 0; i < _subjects.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: PhoneCard(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _tint(scores[i]).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _subjects[i].$3,
                      color: _tint(scores[i]),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _subjects[i].$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kPhoneInk,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${scores[i]}',
                              style: TextStyle(
                                color: _tint(scores[i]),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _tint(scores[i]).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _letter(scores[i]),
                                style: TextStyle(
                                  color: _tint(scores[i]),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: scores[i] / 100,
                            minHeight: 4,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation(
                              _tint(scores[i]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _subjects[i].$2,
                          style: const TextStyle(
                            color: kPhoneMuted,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Attendance
// ---------------------------------------------------------------------------

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({super.key, required this.gs});

  final GameState gs;

  @override
  Widget build(BuildContext context) {
    final player = gs.player;
    final rate = player.attendanceRate;
    final warnings = gs.flags['school_warning'] ?? 0;
    final absent = player.attendanceTaken - player.attendancePresent;
    final tint = rate >= 0.9
        ? kPhoneGreen
        : rate >= 0.75
        ? kPhoneAmber
        : kPhoneRose;

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        PhoneCard(
          color: kPhonePanelSoft,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: rate.clamp(0.0, 1.0),
                        strokeWidth: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation(tint),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(rate * 100).round()}%',
                          style: TextStyle(
                            color: tint,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'attendance',
                          style: TextStyle(
                            color: kPhoneMuted,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This quarter',
                      style: TextStyle(
                        color: kPhoneInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${player.attendancePresent} of ${player.attendanceTaken} recorded classes attended.',
                      style: const TextStyle(
                        color: kPhoneMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PhonePill(
                      label: rate >= 0.9
                          ? 'Good standing'
                          : 'Needs attention',
                      color: tint,
                      icon: rate >= 0.9
                          ? Icons.verified_outlined
                          : Icons.warning_amber_rounded,
                      dense: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _CountCard(
                label: 'Present',
                value: '${player.attendancePresent}',
                color: kPhoneGreen,
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _CountCard(
                label: 'Absent',
                value: '$absent',
                color: kPhoneRose,
                icon: Icons.cancel_outlined,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _CountCard(
                label: 'Warnings',
                value: '$warnings',
                color: kPhoneAmber,
                icon: Icons.flag_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        PhoneCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HOW ATTENDANCE WORKS',
                style: TextStyle(
                  color: kPhoneMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Every class you attend at school is recorded. Skipping class '
                'lowers this rate and adds a warning to your record.',
                style: TextStyle(
                  color: kPhoneMuted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPhoneGreen.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      color: kPhoneGreen,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attend class from the School activity menu to keep this above 90%.',
                        style: TextStyle(
                          color: kPhoneGreen,
                          fontSize: 10.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PhoneCard(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      radius: 15,
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: kPhoneMuted, fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notices
// ---------------------------------------------------------------------------

class _NoticesTab extends StatelessWidget {
  const _NoticesTab({super.key, required this.gs});

  final GameState gs;

  @override
  Widget build(BuildContext context) {
    final day = gs.time.day;
    final notices = [
      (
        'EVENT',
        kPhoneGreen,
        'Intramurals moved to Friday',
        'Opening parade at 08:00 on the field. Classes end at noon.',
        'Day $day',
      ),
      (
        'REMINDER',
        kPhoneAmber,
        'Library returns due',
        'Borrowed books are due back before the weekend. Late returns cost ₱10.',
        'Day ${day - 1}',
      ),
      (
        'MEETING',
        kPhoneBlue,
        'Parent-teacher conference',
        'Homeroom advisers will be available from 13:00 to 16:00 in the gym.',
        'Day ${day - 2}',
      ),
      (
        'ACADEMIC',
        kPhonePurple,
        'Science fair sign-ups open',
        'Forms are at the Science lab. Teams of two. Slots close this week.',
        'Day ${day - 3}',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        const PhonePill(
          label: '4 campus notices',
          color: kPhoneGreen,
          icon: Icons.push_pin_outlined,
        ),
        const SizedBox(height: 8),
        for (final notice in notices)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PhoneCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PhonePill(
                        label: notice.$1,
                        color: notice.$2,
                        dense: true,
                      ),
                      const Spacer(),
                      Text(
                        notice.$5,
                        style: const TextStyle(
                          color: kPhoneMuted,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    notice.$3,
                    style: const TextStyle(
                      color: kPhoneInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notice.$4,
                    style: const TextStyle(
                      color: kPhoneMuted,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Timetable data
// ---------------------------------------------------------------------------

const _teachers = {
  'Mathematics': ('Ms. Reyes', 'Room 204'),
  'Science': ('Mr. Santos', 'Lab 2'),
  'English': ('Ms. Cruz', 'Room 118'),
  'Filipino': ('Mr. Bautista', 'Room 121'),
  'History': ('Ms. Lim', 'Room 210'),
  'Computer Lab': ('Mr. Tan', 'Computer Lab'),
  'PE': ('Coach Dela Cruz', 'Gym'),
};

const _subjectRotation = {
  Weekday.monday: ['Mathematics', 'Science', 'English', 'Filipino'],
  Weekday.tuesday: ['Science', 'English', 'Mathematics', 'PE'],
  Weekday.wednesday: ['English', 'Filipino', 'Science', 'Computer Lab'],
  Weekday.thursday: ['Mathematics', 'History', 'English', 'Science'],
  Weekday.friday: ['Filipino', 'Mathematics', 'Computer Lab', 'PE'],
};

const _slots = [
  (480, 570), // 08:00 – 09:30
  (600, 690), // 10:00 – 11:30
  (750, 840), // 12:30 – 14:00
  (840, 930), // 14:00 – 15:30
];

T? _firstOrNull<T>(Iterable<T> values) {
  for (final value in values) {
    return value;
  }
  return null;
}

List<_Period> _periodsFor(Weekday day) {
  if (day == Weekday.saturday || day == Weekday.sunday) return const [];
  final subjects = _subjectRotation[day] ?? const [];
  return [
    for (var i = 0; i < subjects.length; i++)
      _Period(
        start: _slots[i].$1,
        end: _slots[i].$2,
        subject: subjects[i],
        room: _teachers[subjects[i]]!.$2,
        teacher: _teachers[subjects[i]]!.$1,
      ),
    // Breaks are shown between the classes.
    if (subjects.isNotEmpty) ...[
      const _Period(
        start: 570,
        end: 600,
        subject: 'Break',
        room: '',
        teacher: '',
      ),
      const _Period(
        start: 690,
        end: 750,
        subject: 'Lunch',
        room: 'Canteen',
        teacher: '',
      ),
    ],
  ]..sort((a, b) => a.start.compareTo(b.start));
}
