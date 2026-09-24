import 'package:flutter/material.dart';
import '../models/location_dialogue.dart';

class DialogueBox extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(245),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade300),
        ),
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
              ...node.choices.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton(
                    onPressed: () => onChoice(c),
                    child: Text(c.text),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
