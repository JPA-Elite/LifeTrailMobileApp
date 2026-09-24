import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location_dialogue.dart';
import '../game/state/game_state.dart';

class DialogueBox extends ConsumerWidget {
  final DialogueNode node;
  final void Function(DialogueChoice choice) onChoice;
  final VoidCallback onNext;
  final VoidCallback onClose;

  const DialogueBox({
    super.key,
    required this.node,
    required this.onChoice,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(gameStateProvider);
    final sheetW = MediaQuery.of(context).size.width * 0.9;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: sheetW,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFBF7EC), Color(0xFFF3E7C8)],
          ),
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(40),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF2E7D5B),
                      child: Text(
                        node.speaker.isEmpty
                            ? '?'
                            : node.speaker[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.speaker,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Color(0xFF3A2C26),
                            ),
                          ),
                          const Text(
                            'Speaking…',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE06666), Color(0xFFB3261E)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB3261E).withAlpha(90),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onClose,
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22301F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFD966).withAlpha(120),
                    ),
                  ),
                  child: Text(
                    node.text,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              if (node.choices.isEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Next'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D5B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                )
              else
                ...node.choices.map((c) {
                  // Summertime Saga: show requirement-gated choices as disabled with hint
                  final relCandidates = gs.npcs.values
                      .where(
                        (n) =>
                            n.dialogueId.toLowerCase() ==
                                node.speaker.toLowerCase() ||
                            n.name == node.speaker,
                      )
                      .toList();
                  final npcRel = relCandidates.isNotEmpty
                      ? relCandidates.first.relationship
                      : 0;
                  final avail = c.isAvailable(
                    relationship: npcRel,
                    flags: gs.flags,
                    charm: gs.player.charm,
                    intelligence: gs.player.intelligence,
                    strength: gs.player.strength,
                  );
                  String label = c.text;
                  if (!avail) {
                    final reqs = <String>[];
                    if (c.requiresRelationship > 0) {
                      reqs.add('Rel ${c.requiresRelationship}');
                    }
                    if (c.requiresCharm > 0) {
                      reqs.add('Charm ${c.requiresCharm}');
                    }
                    if (c.requiresIntelligence > 0) {
                      reqs.add('Int ${c.requiresIntelligence}');
                    }
                    if (c.requiresStrength > 0) {
                      reqs.add('Str ${c.requiresStrength}');
                    }
                    if (c.requiresFlag != null) {
                      reqs.add('Flag ${c.requiresFlag}');
                    }
                    if (reqs.isNotEmpty) {
                      label += ' (${reqs.join(', ')})';
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: FilledButton.tonalIcon(
                      onPressed: avail ? () => onChoice(c) : null,
                      icon: Icon(
                        avail
                            ? Icons.chat_bubble_outline_rounded
                            : Icons.lock_outline_rounded,
                        size: 18,
                      ),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(label),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: avail
                            ? const Color(0xFF2E7D5B)
                            : Colors.grey.shade300,
                        foregroundColor: avail
                            ? Colors.white
                            : Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
