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
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(245),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: Colors.brown.shade300),
        ),
        child: SafeArea(
          // Bottom inset only: the panel itself stays edge-to-edge so the
          // left/right gutters match (system insets on one side alone made
          // the panel's content look shifted / too spacious).
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    node.speaker,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              Text(node.text, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              if (node.choices.isEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: onNext,
                    child: const Text('Next'),
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
                    child: OutlinedButton(
                      onPressed: avail ? () => onChoice(c) : null,
                      child: Text(label),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
