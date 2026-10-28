import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/state/game_state.dart';
import '../game/systems/core_systems.dart';
import '../game/systems/venue_system.dart';
import '../models/venue.dart';
import '../services/audio_service.dart';
import 'venue_scene_painter.dart';

/// Returned when the player closes a venue scene.
class VenueSceneResult {
  const VenueSceneResult({
    this.openMenu = false,
    this.leaveBuilding = false,
    this.lastAction,
    this.actionsTaken = 0,
  });

  /// The player asked for the building's full activity list.
  final bool openMenu;

  /// The player asked to step back out onto the street.
  final bool leaveBuilding;

  /// The last thing they did inside, for the HUD confirmation.
  final String? lastAction;

  final int actionsTaken;
}

/// A full-screen "step inside" scenario for one town building.
///
/// The art and copy come from [widget.venue]; every action is applied through
/// [applyVenueAction] so a tap costs real money, energy and time. The control
/// panel sits on the right in landscape and along the bottom in portrait.
class VenueSceneScreen extends ConsumerStatefulWidget {
  const VenueSceneScreen({super.key, required this.venue});

  final Venue venue;

  @override
  ConsumerState<VenueSceneScreen> createState() => _VenueSceneScreenState();
}

class _VenueSceneScreenState extends ConsumerState<VenueSceneScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _react;

  String? _notice;
  bool _noticeOk = true;
  VenueAction? _lastAction;
  int _actionsTaken = 0;

  Venue get venue => widget.venue;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _react = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _ambient.dispose();
    _react.dispose();
    super.dispose();
  }

  void _perform(VenueAction action) {
    final gs = ref.read(gameStateProvider);
    final outcome = applyVenueAction(gs, action, venue: venue);
    if (outcome.ok) {
      AudioService().interact();
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    _react.forward(from: 0);
    setState(() {
      _notice = outcome.message;
      _noticeOk = outcome.ok;
      _lastAction = action;
      if (outcome.ok) _actionsTaken++;
    });
  }

  void _pop({
    bool openMenu = false,
    bool leaveBuilding = false,
  }) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(
      VenueSceneResult(
        openMenu: openMenu,
        leaveBuilding: leaveBuilding,
        lastAction: _lastAction?.label,
        actionsTaken: _actionsTaken,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    return Scaffold(
      backgroundColor: venue.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            return wide ? _wide(state, constraints) : _compact(state, constraints);
          },
        ),
      ),
    );
  }

  Widget _wide(GameState state, BoxConstraints constraints) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _art(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topLeft,
            child: _badge(state),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: math.min(392, constraints.maxWidth * 0.47),
              height: constraints.maxHeight - 32,
              child: _panel(state, wide: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _compact(GameState state, BoxConstraints constraints) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _art(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _badge(state, compact: true),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 6,
          child: _panel(state, wide: false),
        ),
      ],
    );
  }

  Widget _art() {
    return AnimatedBuilder(
      animation: Listenable.merge([_ambient, _react]),
      builder: (context, _) {
        final reaction =
            1 - Curves.easeOutCubic.transform(_react.value.clamp(0.0, 1.0));
        return RepaintBoundary(
          child: CustomPaint(
            painter: VenueScenePainter(
              venue: venue,
              ambient: _ambient.value,
              reaction: _react.isAnimating ? reaction : 0,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  Widget _badge(GameState state, {bool compact = false}) {
    return Container(
      constraints: BoxConstraints(maxWidth: compact ? 250 : 330),
      padding: const EdgeInsets.fromLTRB(11, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 28 : 32,
            height: compact ? 28 : 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [venue.accent, venue.glow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(venue.icon, size: compact ? 15 : 17, color: venue.accentInk),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  venue.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: venue.ink,
                    fontSize: compact ? 10.5 : 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  venue.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: venue.muted, fontSize: 9.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: venue.accent.withAlpha(34),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              state.time.clockLabel,
              style: TextStyle(
                color: venue.accent,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (compact) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: _pop,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 16, color: venue.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _panel(GameState state, {required bool wide}) {
    final radius = wide
        ? BorderRadius.circular(26)
        : const BorderRadius.vertical(top: Radius.circular(24));
    return Container(
      decoration: BoxDecoration(
        color: venue.panel.withAlpha(244),
        borderRadius: radius,
        border: Border.all(color: Colors.white.withAlpha(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(wide),
              const SizedBox(height: 9),
              Text(
                venue.intro,
                style: TextStyle(
                  color: venue.muted,
                  height: 1.35,
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 11),
              _stats(state),
              if (venueIsClosed(state, venue)) ...[
                const SizedBox(height: 11),
                _closedBanner(state),
              ],
              if (_notice != null) ...[
                const SizedBox(height: 11),
                _noticeBox(),
              ],
              const SizedBox(height: 13),
              Row(
                children: [
                  Text(
                    'THINGS TO DO',
                    style: TextStyle(
                      color: venue.accent,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withAlpha(24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final action in venue.actions) ...[
                _actionTile(state, action),
                const SizedBox(height: 7),
              ],
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pop(openMenu: true),
                      icon: const Icon(Icons.list_alt_rounded, size: 17),
                      label: const Text(
                        'Full menu',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: venue.ink,
                        side: BorderSide(color: Colors.white.withAlpha(50)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pop(leaveBuilding: true),
                      icon: const Icon(Icons.logout_rounded, size: 17),
                      label: const Text(
                        'Leave',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: venue.muted,
                        side: BorderSide(color: Colors.white.withAlpha(34)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Every action spends time — the town clock keeps moving.',
                style: TextStyle(color: venue.muted.withAlpha(190), fontSize: 9.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool wide) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: LinearGradient(
              colors: [venue.accent, venue.glow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(venue.icon, color: venue.accentInk, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                venue.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: venue.ink,
                  fontSize: 18,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                venue.tagline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: venue.muted,
                  fontSize: 10.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        if (wide)
          InkWell(
            onTap: _pop,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 20, color: venue.muted),
            ),
          ),
      ],
    );
  }

  Widget _stats(GameState state) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _StatPill(
          icon: Icons.bolt_rounded,
          label: '${state.player.energy}',
          tint: const Color(0xFFFFD36E),
        ),
        _StatPill(
          icon: Icons.payments_rounded,
          label: '₱${state.player.money}',
          tint: const Color(0xFF9BE38E),
        ),
        _StatPill(
          icon: Icons.favorite_rounded,
          label: '${state.player.happiness}',
          tint: const Color(0xFFFF9EC4),
        ),
        _StatPill(
          icon: Icons.health_and_safety_rounded,
          label: '${state.player.health}',
          tint: const Color(0xFFFF8A8A),
        ),
        _StatPill(
          icon: Icons.schedule_rounded,
          label: 'Day ${state.time.day} · ${state.time.clockLabel}',
          tint: venue.glow,
        ),
      ],
    );
  }

  Widget _closedBanner(GameState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB35C).withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB35C).withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_clock_rounded,
            color: Color(0xFFFFB35C),
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Closed right now (${state.time.clockLabel} '
              '${state.time.periodLabel.toLowerCase()}). '
              'Hours: ${LocationHours.label(venue.id)}. You can look around, '
              'but nothing here will serve you.',
              style: const TextStyle(
                color: Color(0xFFFFC988),
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeBox() {
    final good = _noticeOk;
    final color = good ? const Color(0xFF6FCF97) : const Color(0xFFFF8A8A);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(75)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            good ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              _notice!,
              style: TextStyle(color: color, fontSize: 11.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(GameState state, VenueAction action) {
    final reason = venueUnavailableReason(state, action, venue: venue);
    final available = reason == null;
    return Opacity(
      opacity: available ? 1 : 0.55,
      child: Material(
        color: Colors.white.withAlpha(9),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _perform(action),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: venue.accent.withAlpha(available ? 32 : 18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    action.icon,
                    size: 19,
                    color: available ? venue.accent : venue.muted,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.label,
                        style: TextStyle(
                          color: venue.ink,
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (action.detail != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          action.detail!,
                          style: TextStyle(
                            color: venue.muted,
                            fontSize: 10.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                      if (action.costChips.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 4,
                          runSpacing: 3,
                          children: [
                            for (final chip in action.costChips)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(60),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  chip,
                                  style: TextStyle(
                                    color: venue.muted,
                                    fontSize: 8.8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: available ? venue.accent : venue.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tint),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE8E0D0),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
