import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/state/game_state.dart';
import '../../models/quest_model.dart';
import 'phone_ui.dart';

/// The in-game phone's Mission Log: the player's personal quest journal. It
/// tracks every mission — available, active, completed and locked — with
/// objective checklists, rewards and the requirements that gate each one.
const Color _cAvailable = kPhoneAmber;
const Color _cActive = kPhoneBlue;
const Color _cCompleted = kPhoneGreen;
const Color _cFailed = kPhoneRose;
const Color _cLocked = kPhoneMuted;

String _questStatusLabel(QuestStatus s) {
  switch (s) {
    case QuestStatus.available:
      return 'Ready to start';
    case QuestStatus.active:
      return 'In progress';
    case QuestStatus.completed:
      return 'Completed';
    case QuestStatus.failed:
      return 'Failed';
    case QuestStatus.locked:
      return 'Locked';
  }
}

class QuestsApp extends ConsumerStatefulWidget {
  const QuestsApp({super.key});

  @override
  ConsumerState<QuestsApp> createState() => _QuestsAppState();
}

class _QuestsAppState extends ConsumerState<QuestsApp> {
  int _tab = 0;

  static const List<String> _tabs = [
    'Available',
    'Active',
    'Completed',
    'Locked',
  ];

  List<QuestModel> _filtered(GameState gs) {
    final all = gs.quests.values.toList();
    switch (_tab) {
      case 0:
        return all.where((q) => q.status == QuestStatus.available).toList();
      case 1:
        return all.where((q) => q.status == QuestStatus.active).toList();
      case 2:
        return all.where((q) => q.status == QuestStatus.completed).toList();
      default:
        return all.where((q) => q.status == QuestStatus.locked).toList();
    }
  }

  Color _statusColor(QuestStatus s) {
    switch (s) {
      case QuestStatus.available:
        return _cAvailable;
      case QuestStatus.active:
        return _cActive;
      case QuestStatus.completed:
        return _cCompleted;
      case QuestStatus.failed:
        return _cFailed;
      case QuestStatus.locked:
        return _cLocked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final gs = ref.watch(gameStateProvider);
    final quests = _filtered(gs);
    final activeCount = gs.quests.values.where((q) => q.status == QuestStatus.active).length;

    return PhoneAppScaffold(
      title: 'Mission Log',
      subtitle:
          '${gs.time.weekdayLabel}, Day ${gs.time.day} · $activeCount active',
      icon: Icons.campaign_rounded,
      accent: _cActive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) {
                final icons = [
                  Icons.task_alt_rounded,
                  Icons.play_circle_rounded,
                  Icons.check_circle_rounded,
                  Icons.lock_rounded,
                ];
                return _TabChip(
                  icon: icons[i],
                  label: _tabs[i],
                  selected: _tab == i,
                  onTap: () => setState(() => _tab = i),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: quests.isEmpty
                ? _EmptyState(tab: _tabs[_tab])
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 14),
                    itemCount: quests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (_, i) => _QuestCard(
                      gs: gs,
                      quest: quests[i],
                      statusColor: _statusColor(quests[i].status),
                      onStart: () => gs.startQuest(quests[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped tab used by the mission log's horizontal tab strip.
class _TabChip extends StatelessWidget {
  const _TabChip({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = selected ? kPhoneInk : kPhonePanelSoft;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? kPhoneAmber : kPhoneMuted.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? kPhoneAmber : kPhoneMuted.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state shown when the selected tab has no quests.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tab});
  final String tab;

  @override
  Widget build(BuildContext context) {
    late IconData icon;
    late String title;
    late String message;
    late Color accent;
    switch (tab) {
      case 'Available':
        icon = Icons.task_alt_rounded;
        title = 'No quests ready to start';
        message = 'Keep exploring town and raising your stats — new missions will unlock as you meet people and grow.';
        accent = _cAvailable;
        break;
      case 'Active':
        icon = Icons.play_circle_rounded;
        title = 'No active missions';
        message = 'Pick an available quest from the list to begin your next objective.';
        accent = _cActive;
        break;
      case 'Completed':
        icon = Icons.check_circle_rounded;
        title = 'No completed quests yet';
        message = 'Finish missions to see your story and rewards here.';
        accent = _cCompleted;
        break;
      default:
        icon = Icons.lock_rounded;
        title = 'No locked quests';
        message = 'All currently known missions are open to you.';
        accent = _cLocked;
        break;
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: kPhoneInk,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: kPhoneMuted.withValues(alpha: 0.9), fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

Chip _chip(String label, Color color) {
  return Chip(
    label: Text(label, style: const TextStyle(color: Color(0xFF07110B), fontSize: 9.5, fontWeight: FontWeight.w800)),
    avatar: Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    backgroundColor: color.withValues(alpha: 0.14),
    side: BorderSide.none,
    padding: EdgeInsets.zero,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
  );
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.gs, required this.quest, required this.statusColor, required this.onStart});

  final GameState gs;
  final QuestModel quest;
  final Color statusColor;
  final VoidCallback onStart;

  String get _npcName {
    final npcId = quest.npcId;
    if (npcId == null) return 'Personal mission';
    if (npcId.isEmpty) return 'Personal mission';
    return gs.npcs[quest.npcId]?.name ?? 'Someone in town';
  }

  int get _doneCount => quest.objectives.where((o) => o.done).length;

  List<Widget> _requirementChips() {
    final out = <Widget>[];
    if (quest.requiresDay > 0) out.add(_chip('Day ${quest.requiresDay}+', _cLocked));
    if (quest.requiresRelationship > 0) {
      out.add(_chip('Relationship ${quest.requiresRelationship}+', _cLocked));
    }
    if (quest.requiresIntelligence > 0) {
      out.add(_chip('Int ${quest.requiresIntelligence}+', _cLocked));
    }
    if (quest.requiresCharm > 0) out.add(_chip('Charm ${quest.requiresCharm}+', _cLocked));
    if (quest.requiresStrength > 0) out.add(_chip('Str ${quest.requiresStrength}+', _cLocked));
    if (quest.requiresQuest != null) {
      final req = gs.quests[quest.requiresQuest];
      out.add(_chip('Complete: ${req?.title ?? quest.requiresQuest}', _cLocked));
    }
    return out;
  }

  Widget _objectiveRow(QuestObjective o) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: o.done ? kPhoneGreen : kPhonePanelSoft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: o.done ? kPhoneGreen : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Center(
              child: Text(
                o.done ? '✓' : '○',
                style: TextStyle(
                  color: o.done ? const Color(0xFF07110B) : kPhoneMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              o.description,
              style: TextStyle(
                color: o.done ? kPhoneMuted.withValues(alpha: 0.75) : kPhoneInk,
                fontSize: 12,
                decoration: o.done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context) {
    final label = switch (quest.status) {
      QuestStatus.available => 'Accept Mission',
      QuestStatus.active => 'In Progress',
      QuestStatus.completed => 'Claim Reward',
      QuestStatus.failed => 'Failed',
      QuestStatus.locked => 'Locked',
    };
    final enabled = quest.status == QuestStatus.available;
    return SizedBox(
      width: double.infinity,
      child: PhoneButton(
        label: label,
        onPressed: enabled ? onStart : null,
        color: enabled ? statusColor : kPhonePanelSoft,
        enabled: enabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: kPhonePanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  quest.title,
                  style: const TextStyle(
                    color: kPhoneInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1),
                ),
                child: Text(
                  _questStatusLabel(quest.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 14, color: kPhoneMuted),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Given by ${_npcName}',
                  style: TextStyle(
                    color: kPhoneMuted.withValues(alpha: 0.9),
                    fontSize: 10.5,
                  ),
                ),
              ),
              if (quest.rewardMoney > 0)
                _chip('₱${quest.rewardMoney}', _cAvailable),
              if (quest.rewardRelationship > 0)
                _chip('+${quest.rewardRelationship} ${_npcName}', _cCompleted),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            quest.description,
            style: TextStyle(
              color: kPhoneInk.withValues(alpha: 0.95),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          if (quest.status == QuestStatus.locked && _requirementChips().isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              'Unlocks when:',
              style: TextStyle(color: kPhoneMuted, fontSize: 10, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 7,
              runSpacing: 6,
              children: _requirementChips(),
            ),
          ],
          const SizedBox(height: 11),
          Row(
            children: [
              Text(
                'Objectives',
                style: TextStyle(color: kPhoneMuted, fontSize: 10, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '$_doneCount/${quest.objectives.length}',
                style: TextStyle(color: kPhoneMuted.withValues(alpha: 0.8), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...quest.objectives.map((o) => _objectiveRow(o)),
          const SizedBox(height: 11),
          _actionButton(context),
        ],
      ),
    );
  }
}

// ===== QUESTS DONE =====