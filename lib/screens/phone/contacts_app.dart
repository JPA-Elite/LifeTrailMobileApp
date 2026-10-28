import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/state/game_state.dart';
import '../../game/state/phone_state.dart';
import '../../models/npc_model.dart';
import 'messages_app.dart';
import 'phone_ui.dart';

/// Contact book for the in-game phone. Names, ages, personalities and
/// whereabouts all come from the live NPC roster and their schedules.
class ContactsApp extends ConsumerStatefulWidget {
  const ContactsApp({super.key});

  @override
  ConsumerState<ContactsApp> createState() => _ContactsAppState();
}

class _ContactsAppState extends ConsumerState<ContactsApp> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameStateProvider);
    final phone = ref.watch(phoneStateProvider);
    final all = phone.contacts;
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? all
        : all
              .where(
                (c) =>
                    c.name.toLowerCase().contains(query) ||
                    c.personality.toLowerCase().contains(query),
              )
              .toList();
    final favorites = visible.where((c) => c.favorite).toList();
    final others = visible.where((c) => !c.favorite).toList();

    return PhoneAppScaffold(
      title: 'Contacts',
      subtitle: '${all.length} people · ${favorites.length} favourite',
      icon: Icons.contacts_rounded,
      accent: kPhonePurple,
      child: Column(
        children: [
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: kPhoneInk, fontSize: 13.5),
            decoration: phoneFieldDecoration(
              hint: 'Search people or personalities',
              icon: Icons.search_rounded,
              accent: kPhonePurple,
              suffix: _query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: kPhoneMuted,
                        size: 18,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: all.isEmpty
                ? const PhoneEmptyState(
                    icon: Icons.person_search_outlined,
                    title: 'No contacts yet',
                    message:
                        'Meet people around town and they will appear in your phone.',
                    accent: kPhonePurple,
                  )
                : visible.isEmpty
                ? PhoneEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message: 'Nobody matches "$_query". Try another name.',
                    accent: kPhonePurple,
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      if (favorites.isNotEmpty) ...[
                        const _SectionLabel(
                          label: 'FAVOURITES',
                          color: kPhoneAmber,
                        ),
                        ...favorites.map(
                          (c) => _ContactTile(
                            contact: c,
                            location: _locationOf(gs, c.id),
                            onTap: () => _openContact(c.id),
                            onToggleFavorite: () =>
                                phone.toggleFavorite(c.id),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (others.isNotEmpty) ...[
                        const _SectionLabel(
                          label: 'ALL CONTACTS',
                          color: kPhoneMuted,
                        ),
                        ...others.map(
                          (c) => _ContactTile(
                            contact: c,
                            location: _locationOf(gs, c.id),
                            onTap: () => _openContact(c.id),
                            onToggleFavorite: () =>
                                phone.toggleFavorite(c.id),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String? _locationOf(GameState gs, String id) {
    final npc = gs.npcs[id];
    if (npc == null) return null;
    return npc.locationFor(gs.time.weekdayLabel, gs.time.minutes);
  }

  Future<void> _openContact(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: id)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.location,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final PhoneContact contact;
  final String? location;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PhoneCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: onTap,
        child: Row(
          children: [
            PhoneAvatar(name: contact.name, size: 44),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kPhoneInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location == null
                        ? contact.personality
                        : '${contact.personality} · at ${friendlyLocation(location!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kPhoneMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onToggleFavorite,
              tooltip: contact.favorite
                  ? 'Remove from favourites'
                  : 'Add to favourites',
              icon: Icon(
                contact.favorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: contact.favorite ? kPhoneAmber : kPhoneMuted,
                size: 20,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: kPhoneMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything the phone knows about one person: their details, current
/// whereabouts, today's schedule and a shortcut into the conversation.
class ContactDetailScreen extends ConsumerWidget {
  const ContactDetailScreen({super.key, required this.contactId});

  final String contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(gameStateProvider);
    final phone = ref.watch(phoneStateProvider);
    final contact = phone.contact(contactId);
    if (contact == null) {
      return const PhoneAppScaffold(
        title: 'Contact',
        icon: Icons.person_off_outlined,
        accent: kPhonePurple,
        body: PhoneEmptyState(
          icon: Icons.person_off_outlined,
          title: 'Contact unavailable',
          message: 'This person is no longer in your phone.',
        ),
      );
    }

    final npc = gs.npcs[contactId];
    final today = npc?.locationFor(gs.time.weekdayLabel, gs.time.minutes);
    final relationship = npc?.relationship ?? 0;
    final schedule = _todaySchedule(npc, gs.time.weekdayLabel);

    return PhoneAppScaffold(
      title: contact.name,
      subtitle: today == null
          ? contact.personality
          : 'At ${friendlyLocation(today)}',
      icon: Icons.person_rounded,
      accent: kPhonePurple,
      actions: [
        IconButton(
          tooltip: contact.favorite ? 'Remove favourite' : 'Add favourite',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.06),
          ),
          onPressed: () => phone.toggleFavorite(contactId),
          icon: Icon(
            contact.favorite ? Icons.star_rounded : Icons.star_border_rounded,
            color: contact.favorite ? kPhoneAmber : kPhoneInk,
          ),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          PhoneCard(
            padding: const EdgeInsets.all(18),
            color: kPhonePanelSoft,
            child: Row(
              children: [
                PhoneAvatar(name: contact.name, size: 70, ring: true),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          color: kPhoneInk,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${contact.age} · ${contact.personality}',
                        style: const TextStyle(
                          color: kPhoneMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: kPhoneGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              today == null
                                  ? 'Out and about'
                                  : 'Right now: ${friendlyLocation(today)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: kPhoneGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          PhoneButton(
            label: phone.hasThread(contactId)
                ? 'Open conversation'
                : 'Send a message',
            icon: Icons.chat_bubble_outline_rounded,
            color: kPhoneBlue,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(contactId: contactId),
              ),
            ),
          ),
          const SizedBox(height: 10),
          PhoneCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.phone_rounded,
                  label: 'Mobile',
                  value: contact.phone,
                ),
                const Divider(color: Colors.white12, height: 18),
                _InfoRow(
                  icon: Icons.favorite_border_rounded,
                  label: 'Relationship',
                  value: '$relationship / 100',
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (relationship / 100).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation(kPhoneRose),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          PhoneCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TODAY'S SCHEDULE",
                  style: TextStyle(
                    color: kPhoneMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                if (schedule.isEmpty)
                  const Text(
                    'No plans on the calendar — maybe they are free.',
                    style: TextStyle(color: kPhoneMuted, fontSize: 12),
                  )
                else
                  ...schedule.map(
                    (entry) => _ScheduleRow(
                      start: entry.start,
                      end: entry.end,
                      location: entry.location,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ScheduleEntry> _todaySchedule(NpcModel? npc, String weekday) {
    if (npc == null) return const [];
    final day = weekday.toLowerCase();
    final entries = npc.schedule
        .where((e) => e.weekday == 'any' || e.weekday == day)
        .toList();
    entries.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return entries;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kPhoneMuted, size: 18),
        const SizedBox(width: 9),
        Text(
          label,
          style: const TextStyle(color: kPhoneMuted, fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: kPhoneInk,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.start,
    required this.end,
    required this.location,
  });

  final String start;
  final String end;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 26,
            decoration: BoxDecoration(
              color: kPhonePurple.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            '$start – $end',
            style: const TextStyle(
              color: kPhoneMuted,
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              friendlyLocation(location),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kPhoneInk,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
