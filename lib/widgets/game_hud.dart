import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/state/game_state.dart';
import 'stat_bar.dart';

class GameHud extends ConsumerWidget {
  final VoidCallback? onSave;
  const GameHud({super.key, this.onSave});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        // Top inset only: left/right system insets (camera cutout in
        // landscape Android) otherwise pad one side more and look
        // "spacious on the left". Full-bleed sides keep it symmetric.
        top: true,
        bottom: false,
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: IntrinsicHeight(
            // Stretch + intrinsic height so all three cards are exactly
            // as tall as the tallest one. Previously the short left card
            // (date + money) left a big empty gap under it, which read as
            // "the left side is too spacious".
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Width is split by content density instead of equal
                // thirds: the sparse clock/money card needs the least
                // room and the stats card the most.
                Expanded(flex: 3, child: _clockCard(state)),
                const SizedBox(width: 6),
                Expanded(flex: 3, child: _vitalsCard(state)),
                const SizedBox(width: 6),
                Expanded(flex: 4, child: _skillsCard(state)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardShell({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  Widget _clockCard(GameState state) {
    return _cardShell(
      color: Colors.black.withAlpha(140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Day ${state.time.day} · ${state.time.weekdayLabel} · ${state.time.clockLabel}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            state.pesoBalance,
            style: const TextStyle(
              color: Color(0xFFFFD966),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _vitalsCard(GameState state) {
    return _cardShell(
      color: Colors.black.withAlpha(140),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          StatBar(
            label: 'HP',
            value: state.player.health,
            max: 100,
            color: Colors.red,
          ),
          StatBar(
            label: 'Energy',
            value: state.player.energy,
            max: 100,
            color: Colors.green,
          ),
          StatBar(
            label: 'Happy',
            value: state.player.happiness,
            max: 100,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _skillsCard(GameState state) {
    return _cardShell(
      color: Colors.black.withAlpha(140),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edu ${state.player.education} · Int ${state.player.intelligence}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Str ${state.player.strength} · Chm ${state.player.charm}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (state.isDebtOverdue)
                  const Text(
                    'Debt overdue!',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (onSave != null)
            InkWell(
              onTap: onSave,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.save, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}
