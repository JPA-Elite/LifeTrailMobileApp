import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/state/game_state.dart';
import '../../game/state/phone_state.dart';
import 'phone_ui.dart';

/// The phone's Messages app: an inbox of live conversations with the
/// townsfolk, each backed by a real thread in [PhoneState].
class MessagesApp extends ConsumerWidget {
  const MessagesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(gameStateProvider);
    final phone = ref.watch(phoneStateProvider);
    final inbox = phone.inbox;

    return PhoneAppScaffold(
      title: 'Messages',
      subtitle:
          '${gs.time.weekdayLabel} · ${gs.time.clockLabel} · ${phone.totalUnread} unread',
      icon: Icons.chat_bubble_rounded,
      accent: kPhoneBlue,
      actions: [
        IconButton(
          tooltip: 'New message',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.06),
          ),
          onPressed: () => _startNewMessage(context, ref),
          icon: const Icon(Icons.edit_square, color: kPhoneInk),
        ),
      ],
      child: inbox.isEmpty
          ? const PhoneEmptyState(
              icon: Icons.forum_outlined,
              title: 'No conversations yet',
              message:
                  'Your friends will show up here once you meet them around town.',
              accent: kPhoneBlue,
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: inbox.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) return _InboxHeader(phone: phone);
                final contact = inbox[index - 1];
                return _InboxTile(
                  contact: contact,
                  last: phone.lastMessageOf(contact.id),
                  unread: phone.unreadOf(contact.id),
                  typing: phone.isTyping(contact.id),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(contactId: contact.id),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _startNewMessage(BuildContext context, WidgetRef ref) async {
    final phone = ref.read(phoneStateProvider);
    final contacts = phone.contacts;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: kPhonePanel,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 2, 18, 10),
                child: Text(
                  'Start a conversation',
                  style: TextStyle(
                    color: kPhoneInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (ctx, index) {
                    final contact = contacts[index];
                    return ListTile(
                      leading: PhoneAvatar(name: contact.name, size: 38),
                      title: Text(
                        contact.name,
                        style: const TextStyle(
                          color: kPhoneInk,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: Text(
                        phone.hasThread(contact.id)
                            ? 'Open conversation'
                            : 'Say hello',
                        style: const TextStyle(
                          color: kPhoneMuted,
                          fontSize: 11,
                        ),
                      ),
                      onTap: () => Navigator.of(ctx).pop(contact.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(contactId: picked)),
    );
  }
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader({required this.phone});

  final PhoneState phone;

  @override
  Widget build(BuildContext context) {
    final unread = phone.totalUnread;
    return Row(
      children: [
        PhonePill(
          label: unread == 0 ? 'All caught up' : '$unread waiting',
          color: unread == 0 ? kPhoneGreen : kPhoneAmber,
          icon: unread == 0
              ? Icons.check_circle_outline_rounded
              : Icons.mark_chat_unread_outlined,
        ),
        const Spacer(),
        const PhonePill(
          label: 'Live',
          color: kPhoneBlue,
          icon: Icons.wifi_tethering_rounded,
          dense: true,
        ),
      ],
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({
    required this.contact,
    required this.last,
    required this.unread,
    required this.typing,
    required this.onTap,
  });

  final PhoneContact contact;
  final ChatMessage? last;
  final int unread;
  final bool typing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = typing
        ? 'typing…'
        : last == null
        ? 'Say hello 👋'
        : '${last!.fromMe ? 'You: ' : ''}${last!.text}';
    return PhoneCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      onTap: onTap,
      borderColor: unread > 0
          ? kPhoneBlue.withValues(alpha: 0.3)
          : null,
      child: Row(
        children: [
          PhoneAvatar(name: contact.name, size: 46, ring: unread > 0),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: kPhoneInk,
                          fontSize: 14,
                          fontWeight: unread > 0
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (contact.favorite) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.star_rounded,
                        color: kPhoneAmber,
                        size: 14,
                      ),
                    ],
                    const Spacer(),
                    if (last != null)
                      Text(
                        last!.clock,
                        style: const TextStyle(
                          color: kPhoneMuted,
                          fontSize: 10.5,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: typing
                              ? kPhoneGreen
                              : unread > 0
                              ? kPhoneInk.withValues(alpha: 0.92)
                              : kPhoneMuted,
                          fontSize: 12,
                          fontStyle: typing
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kPhoneBlue,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Color(0xFF071019),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One conversation. Sending a message stores it in [PhoneState]; the
/// contact answers a moment later with a typing bubble in between.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.contactId});

  final String contactId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  /// Captured in [initState] so [dispose] can let go of the active-thread flag
  /// without touching `ref`, which is already invalid while the widget is
  /// being unmounted.
  late final PhoneState _phone;

  @override
  void initState() {
    super.initState();
    _phone = ref.read(phoneStateProvider);
    // Post-frame: reading/clearing unread notifies listeners, and a
    // notification during initState would rebuild the inbox mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _phone
        ..markRead(widget.contactId)
        ..setActiveContact(widget.contactId);
    });
  }

  @override
  void dispose() {
    _phone.clearActiveContact(widget.contactId);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final gs = ref.read(gameStateProvider);
    ref
        .read(phoneStateProvider)
        .sendMessage(
          widget.contactId,
          _text.text,
          clockLabel: gs.time.clockLabel,
          day: gs.time.day,
        );
    _text.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameStateProvider);
    final phone = ref.watch(phoneStateProvider);
    final contact = phone.contact(widget.contactId);
    if (contact == null) {
      return const PhoneAppScaffold(
        title: 'Messages',
        icon: Icons.chat_bubble_rounded,
        accent: kPhoneBlue,
        body: PhoneEmptyState(
          icon: Icons.person_off_outlined,
          title: 'Contact unavailable',
          message: 'This conversation is no longer in your phone.',
        ),
      );
    }
    final npc = gs.npcs[contact.id];
    final where = npc?.locationFor(gs.time.weekdayLabel, gs.time.minutes);
    final typing = phone.isTyping(contact.id);
    final messages = phone.messagesOf(contact.id);

    return PhoneAppScaffold(
      title: contact.name,
      subtitle: typing
          ? 'typing…'
          : where == null
          ? 'Available'
          : 'At ${friendlyLocation(where)} · ${gs.time.clockLabel}',
      icon: Icons.chat_bubble_rounded,
      accent: kPhoneBlue,
      actions: [
        IconButton(
          tooltip: contact.favorite ? 'Remove favourite' : 'Add favourite',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.06),
          ),
          onPressed: () => phone.toggleFavorite(contact.id),
          icon: Icon(
            contact.favorite ? Icons.star_rounded : Icons.star_border_rounded,
            color: contact.favorite ? kPhoneAmber : kPhoneInk,
          ),
        ),
      ],
      body: Column(
        children: [
          _ContactStrip(contact: contact, where: where),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.018),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                itemCount: messages.length + (typing ? 1 : 0),
                itemBuilder: (context, index) {
                  if (typing && index == 0) {
                    return const _TypingBubble();
                  }
                  final message = messages[messages.length - 1 - (typing ? index - 1 : index)];
                  return _ChatBubble(message: message);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  focusNode: _focus,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(color: kPhoneInk, fontSize: 13.5),
                  maxLines: 3,
                  minLines: 1,
                  decoration: phoneFieldDecoration(
                    hint: 'Message ${contact.name.split(' ').first}…',
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _send,
                tooltip: 'Send',
                style: IconButton.styleFrom(
                  backgroundColor: kPhoneBlue,
                  foregroundColor: const Color(0xFF071019),
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactStrip extends StatelessWidget {
  const _ContactStrip({required this.contact, required this.where});

  final PhoneContact contact;
  final String? where;

  @override
  Widget build(BuildContext context) {
    return PhoneCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      radius: 16,
      child: Row(
        children: [
          PhoneAvatar(name: contact.name, size: 34),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${contact.name} · ${contact.age}',
                  style: const TextStyle(
                    color: kPhoneInk,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  where == null
                      ? 'Out and about'
                      : 'Today: ${friendlyLocation(where!)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kPhoneMuted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          PhonePill(
            label: contact.personality,
            color: kPhonePurple,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
        decoration: BoxDecoration(
          color: mine ? kPhoneBlue : kPhonePanelSoft,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(mine ? 17 : 5),
            bottomRight: Radius.circular(mine ? 5 : 17),
          ),
          border: mine
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: mine ? const Color(0xFF06101C) : kPhoneInk,
                fontSize: 13,
                height: 1.32,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.clock,
              style: TextStyle(
                color: (mine ? const Color(0xFF06101C) : kPhoneMuted)
                    .withValues(alpha: 0.65),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kPhonePanelSoft,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: kPhoneMuted.withValues(alpha: 0.5 + i * 0.2),
                  shape: BoxShape.circle,
                ),
              ),
              if (i < 2) const SizedBox(width: 4),
            ],
            const SizedBox(width: 8),
            const Text(
              'typing…',
              style: TextStyle(
                color: kPhoneMuted,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
