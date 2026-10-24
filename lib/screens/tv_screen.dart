import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/state/game_state.dart';
import '../game/systems/core_systems.dart';
import '../models/tv_show.dart';

/// Returned when the player turns the television off.
class TvResult {
  const TvResult({
    this.sessions = 0,
    this.energySpent = 0,
    this.minutes = 0,
    this.lastChannel,
  });

  final int sessions;
  final int energySpent;
  final int minutes;
  final TvChannel? lastChannel;

  bool get watched => sessions > 0;
}

/// The living-room television: a full-screen, animated set with four
/// channels. Each channel selection is a real activity, so it spends energy
/// and advances the clock exactly once per visit.
class TvScreen extends ConsumerStatefulWidget {
  const TvScreen({super.key});

  @override
  ConsumerState<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends ConsumerState<TvScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _flicker;

  TvChannel? _watching;
  TvChannel? _lastChannel;
  String? _notice;
  int _sessions = 0;
  int _energySpent = 0;
  int _minutes = 0;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _flicker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambient.dispose();
    _flicker.dispose();
    super.dispose();
  }

  void _watch(TvChannel channel) {
    final gs = ref.read(gameStateProvider);
    if (!gs.canDoActivity(channel.activityId)) {
      HapticFeedback.heavyImpact();
      setState(() {
        _notice = 'Too tired for ${channel.title.toLowerCase()}. Rest first.';
      });
      return;
    }
    final before = gs.player.energy;
    gs.applyActivity(channel.activityId);
    final spent = (before - gs.player.energy).clamp(0, 100);
    final cfg = Activities.of(channel.activityId);
    HapticFeedback.mediumImpact();
    setState(() {
      _watching = channel;
      _lastChannel = channel;
      _sessions += 1;
      _energySpent += spent;
      _minutes += cfg.minutes;
      _notice = null;
    });
  }

  void _stopWatching() {
    HapticFeedback.selectionClick();
    setState(() => _watching = null);
  }

  void _turnOff() {
    Navigator.of(context).pop(
      TvResult(
        sessions: _sessions,
        energySpent: _energySpent,
        minutes: _minutes,
        lastChannel: _lastChannel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final channel = _watching;

    return Scaffold(
      backgroundColor: const Color(0xFF08070D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_ambient, _flicker]),
            builder: (context, _) {
              if (channel != null) {
                return CustomPaint(
                  painter: _TvContentPainter(
                    channel: channel,
                    t: _ambient.value,
                    flicker: _flicker.value,
                  ),
                );
              }
              return CustomPaint(
                painter: _TvRoomPainter(
                  t: _ambient.value,
                  flicker: _flicker.value,
                  accent: _lastChannel?.accent ?? const Color(0xFFFFD166),
                ),
              );
            },
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: channel == null
                ? _buildPicker(state)
                : _buildNowWatching(state, channel),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker(GameState state) {
    return Column(
      children: [
        Row(
          children: [
            _BrandMark(accent: _lastChannel?.accent ?? const Color(0xFFFFD166)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LIFETRAIL TV',
                    style: TextStyle(
                      color: Color(0xFFFFF6E3),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                    ),
                  ),
                  Text(
                    'Pick a channel. Every visit costs energy.',
                    style: TextStyle(color: Color(0xFFBDB4C8), fontSize: 10.5),
                  ),
                ],
              ),
            ),
            _StatPill(
              icon: Icons.bolt_rounded,
              label: '${state.player.energy}',
              tint: const Color(0xFFFFD166),
            ),
            const SizedBox(width: 6),
            _StatPill(
              icon: Icons.schedule_rounded,
              label: state.time.clockLabel,
              tint: const Color(0xFF8FD3FF),
            ),
            const SizedBox(width: 6),
            _StatPill(
              icon: Icons.wb_twilight_rounded,
              label: state.time.periodLabel,
              tint: const Color(0xFFFFB4A2),
            ),
            const SizedBox(width: 6),
            _RoundAction(
              icon: Icons.power_settings_new_rounded,
              label: 'Turn off',
              onTap: _turnOff,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _Notice(text: _notice!),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 640;
              final grid = _channelGrid(wide);
              if (!wide) return grid;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: _TvSetHint(
                      last: _lastChannel,
                      onTap: _lastChannel == null
                          ? null
                          : () => _watch(_lastChannel!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 6, child: grid),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _channelGrid(bool wide) {
    final columns = wide ? 2 : 1;
    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: wide ? 1.72 : 2.1,
      padding: EdgeInsets.zero,
      children: [
        for (final channel in TvCatalog.channels)
          _ChannelCard(
            channel: channel,
            onTap: () => _watch(channel),
            enabled: ref
                .read(gameStateProvider)
                .canDoActivity(channel.activityId),
          ),
      ],
    );
  }

  Widget _buildNowWatching(GameState state, TvChannel channel) {
    final cfg = Activities.of(channel.activityId);
    return Column(
      children: [
        Row(
          children: [
            _LiveDot(accent: channel.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    channel.title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    channel.program,
                    style: TextStyle(
                      color: channel.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _StatPill(
              icon: Icons.bolt_rounded,
              label: '-${cfg.energyDelta.abs()} energy',
              tint: const Color(0xFFFFD166),
            ),
            const SizedBox(width: 6),
            _StatPill(
              icon: Icons.schedule_rounded,
              label: '+${cfg.minutes}m',
              tint: const Color(0xFF8FD3FF),
            ),
            const SizedBox(width: 6),
            _RoundAction(
              icon: Icons.stop_circle_outlined,
              label: 'Stop watching',
              onTap: _stopWatching,
            ),
          ],
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    channel.program,
                    style: const TextStyle(
                      color: Color(0xFFFFF6E3),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: Text(
                      channel.description,
                      style: const TextStyle(
                        color: Color(0xFFD6CEDD),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Watched ${_sessions == 1 ? '1 visit' : '$_sessions visits'} · '
                    '${state.player.energy}/100 energy · ${state.time.clockLabel}',
                    style: TextStyle(
                      color: channel.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _RoundAction(
              icon: Icons.power_settings_new_rounded,
              label: 'Turn off TV',
              onTap: _turnOff,
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2440), Color(0xFF0B0912)],
        ),
        border: Border.all(color: accent.withAlpha(150), width: 1.4),
        boxShadow: [BoxShadow(color: accent.withAlpha(40), blurRadius: 18)],
      ),
      child: const Icon(Icons.tv_rounded, color: Color(0xFFFFF6E3), size: 23),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withAlpha(160),
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF4D5E),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D5E).withAlpha(160),
                blurRadius: 8,
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(120),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tint, size: 13),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF3EDE4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.black.withAlpha(130),
        shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: const Color(0xFFFFF6E3)),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF5B1F2A).withAlpha(220),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFF8FA3).withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.battery_alert_rounded,
            color: Color(0xFFFFD166),
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.onTap,
    required this.enabled,
  });

  final TvChannel channel;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF201B2C).withAlpha(235),
                const Color(0xFF0D0A14).withAlpha(240),
              ],
            ),
            border: Border.all(
              color: enabled ? channel.accent.withAlpha(120) : Colors.white12,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: channel.secondary.withAlpha(enabled ? 50 : 12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [channel.accent, channel.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: channel.accent.withAlpha(70),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      channel.emoji,
                      style: const TextStyle(fontSize: 19),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        channel.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFF6E3),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        channel.program,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: channel.accent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Expanded(
                        child: Text(
                          channel.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFC9C2D1),
                            fontSize: 9.2,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 11,
                            color: enabled
                                ? const Color(0xFFFFD166)
                                : const Color(0xFF8E8798),
                          ),
                          Text(
                            ' -${Activities.of(channel.activityId).energyDelta.abs()}',
                            style: TextStyle(
                              color: enabled
                                  ? const Color(0xFFFFE4A3)
                                  : const Color(0xFF8E8798),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: Colors.white.withAlpha(110),
                          ),
                          Text(
                            ' ${Activities.of(channel.activityId).minutes}m',
                            style: const TextStyle(
                              color: Color(0xFFAFA7BA),
                              fontSize: 9.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            enabled ? 'WATCH' : 'REST',
                            style: TextStyle(
                              color: enabled
                                  ? channel.accent
                                  : const Color(0xFF8E8798),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
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
        ),
      ),
    );
  }
}

class _TvSetHint extends StatelessWidget {
  const _TvSetHint({required this.last, required this.onTap});

  final TvChannel? last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (last != null)
              Positioned(
                bottom: 2,
                child: Material(
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.replay_rounded,
                            size: 13,
                            color: Color(0xFFFFD166),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Replay ${last!.program}',
                            style: const TextStyle(
                              color: Color(0xFFFFF6E3),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Positioned(
                bottom: 6,
                child: Text(
                  'The antenna is warm.\nPick something to watch.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TvRoomPainter extends CustomPainter {
  _TvRoomPainter({
    required this.t,
    required this.flicker,
    required this.accent,
  });

  final double t;
  final double flicker;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wall = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF171020), Color(0xFF241728), Color(0xFF0E0A13)],
          stops: [0, 0.56, 1],
        ).createShader(wall),
    );

    // Floor and rug.
    final floorTop = h * 0.63;
    canvas.drawRect(
      Rect.fromLTWH(0, floorTop, w, h - floorTop),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A251D), Color(0xFF1A100D)],
        ).createShader(Rect.fromLTWH(0, floorTop, w, h - floorTop)),
    );
    for (var i = 0; i < 9; i++) {
      final y = floorTop + (h - floorTop) * (i / 9);
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y),
        Paint()..color = Colors.white.withAlpha(8),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.33, h * 0.78),
        width: w * 0.42,
        height: h * 0.2,
      ),
      Paint()..color = const Color(0xFF5E2F35).withAlpha(180),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.33, h * 0.78),
        width: w * 0.32,
        height: h * 0.14,
      ),
      Paint()..color = const Color(0xFF7A3C45).withAlpha(130),
    );

    // Couch silhouette on the right edge, just behind the cards.
    final couch = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.82, h * 0.52, w * 0.23, h * 0.34),
      Radius.circular(h * 0.06),
    );
    canvas.drawRRect(couch, Paint()..color = const Color(0xFF2B2031));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.84, h * 0.55, w * 0.18, h * 0.14),
        Radius.circular(h * 0.04),
      ),
      Paint()..color = const Color(0xFF3A2B42),
    );

    // TV stand.
    final stand = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.58, w * 0.38, h * 0.2),
      const Radius.circular(10),
    );
    canvas.drawRRect(stand, Paint()..color = const Color(0xFF2A1B16));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.6, w * 0.34, h * 0.15),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFF423028),
    );

    // CRT television.
    final tvRect = Rect.fromLTWH(w * 0.07, h * 0.2, w * 0.36, h * 0.45);
    final glowRect = tvRect.inflate(w * 0.035);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [accent.withAlpha(38), Colors.transparent],
        ).createShader(glowRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tvRect, const Radius.circular(13)),
      Paint()..color = const Color(0xFF18151A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tvRect.deflate(5), const Radius.circular(10)),
      Paint()..color = const Color(0xFF08070B),
    );
    final screen = tvRect.deflate(12);
    final screenRect = RRect.fromRectAndRadius(
      screen,
      const Radius.circular(16),
    );
    canvas.drawRRect(
      screenRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B2340).withAlpha(230),
            const Color(0xFF0E1530).withAlpha(245),
          ],
        ).createShader(screen),
    );

    // Attract mode: drifting scanlines and a warm centre glow.
    canvas.save();
    canvas.clipRRect(screenRect);
    final glow = Rect.fromCenter(
      center: screen.center,
      width: screen.width * 0.8,
      height: screen.height * 0.65,
    );
    canvas.drawOval(
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [accent.withAlpha(28), Colors.transparent],
        ).createShader(glow),
    );
    for (var i = 0; i < 34; i++) {
      final y = screen.top + ((i * 11 + t * 18) % screen.height);
      canvas.drawLine(
        Offset(screen.left, y),
        Offset(screen.right, y),
        Paint()..color = Colors.white.withAlpha(i.isEven ? 8 : 3),
      );
    }
    final staticPaint = Paint()..color = Colors.white.withAlpha(10);
    for (var i = 0; i < 12; i++) {
      final x = screen.left + (i * 41 + t * 70 + flicker * 10) % screen.width;
      final y = screen.top + (i * 29 + t * 43) % screen.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 2 + (i % 3) * 2, 1.5), staticPaint);
    }
    _drawCenteredText(
      canvas,
      'LIFETRAIL',
      screen.center - Offset(0, 10),
      18,
      const Color(0xFFFFF6E3),
      weight: FontWeight.w900,
      letterSpacing: 3,
    );
    _drawCenteredText(
      canvas,
      'choose a channel',
      screen.center + Offset(0, 12),
      9,
      Colors.white.withAlpha(110),
      letterSpacing: 1.3,
    );
    canvas.restore();

    // TV legs and a small power LED.
    canvas.drawRect(
      Rect.fromLTWH(
        tvRect.left + tvRect.width * 0.16,
        tvRect.bottom - 2,
        8,
        16,
      ),
      Paint()..color = const Color(0xFF0D0A0F),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        tvRect.right - tvRect.width * 0.18,
        tvRect.bottom - 2,
        8,
        16,
      ),
      Paint()..color = const Color(0xFF0D0A0F),
    );
    canvas.drawCircle(
      Offset(tvRect.right - 8, tvRect.bottom - 8),
      2.2,
      Paint()..color = accent.withAlpha(210),
    );

    // Warm lamp glow, top right.
    final lampCenter = Offset(w * 0.93, h * 0.16);
    canvas.drawCircle(
      lampCenter,
      h * 0.16,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFD9A0).withAlpha(32), Colors.transparent],
        ).createShader(Rect.fromCircle(center: lampCenter, radius: h * 0.16)),
    );
    canvas.drawRect(
      Rect.fromLTWH(lampCenter.dx - 2, lampCenter.dy, 4, h * 0.14),
      Paint()..color = const Color(0xFF2A1B16),
    );
    canvas.drawPath(
      Path()
        ..moveTo(lampCenter.dx - 18, lampCenter.dy)
        ..lineTo(lampCenter.dx + 18, lampCenter.dy)
        ..lineTo(lampCenter.dx + 11, lampCenter.dy - 18)
        ..lineTo(lampCenter.dx - 11, lampCenter.dy - 18)
        ..close(),
      Paint()..color = const Color(0xFFE7B66A),
    );
  }

  static void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 0,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _TvRoomPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.flicker != flicker ||
      oldDelegate.accent != accent;
}

class _TvContentPainter extends CustomPainter {
  _TvContentPainter({
    required this.channel,
    required this.t,
    required this.flicker,
  });

  final TvChannel channel;
  final double t;
  final double flicker;

  @override
  void paint(Canvas canvas, Size size) {
    switch (channel.visual) {
      case TvVisual.movie:
        _movie(canvas, size);
        break;
      case TvVisual.internet:
        _internet(canvas, size);
        break;
      case TvVisual.news:
        _news(canvas, size);
        break;
      case TvVisual.cartoon:
        _cartoon(canvas, size);
        break;
    }
    _screenTexture(canvas, size);
  }

  void _movie(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bg = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      bg,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF09071A), Color(0xFF25143B), Color(0xFF5B2342)],
          stops: [0, 0.58, 1],
        ).createShader(bg),
    );
    // Distant skyline.
    final skyline = Paint()..color = const Color(0xFF120E2B);
    for (var i = 0; i < 14; i++) {
      final bw = w * (0.06 + (i % 4) * 0.015);
      final bh = h * (0.18 + (i % 5) * 0.055);
      final x = w * 0.02 + i * w * 0.072;
      canvas.drawRect(Rect.fromLTWH(x, h * 0.58 - bh, bw, bh), skyline);
      for (var wy = 0; wy < 5; wy++) {
        for (var wx = 0; wx < 3; wx++) {
          if ((i + wy + wx) % 3 == 0) {
            canvas.drawRect(
              Rect.fromLTWH(
                x + 4 + wx * (bw / 3.4),
                h * 0.58 - bh + 6 + wy * 12,
                3,
                3,
              ),
              Paint()..color = const Color(0xFFFFD166).withAlpha(150),
            );
          }
        }
      }
    }
    // Wet street.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.72, w, h * 0.28),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C1838), Color(0xFF09070F)],
        ).createShader(Rect.fromLTWH(0, h * 0.72, w, h * 0.28)),
    );
    // Neon signs.
    _neon(
      canvas,
      Rect.fromLTWH(w * 0.08, h * 0.26, w * 0.18, h * 0.09),
      'HOTEL',
    );
    _neon(canvas, Rect.fromLTWH(w * 0.7, h * 0.34, w * 0.2, h * 0.1), 'JAZZ');
    _neon(canvas, Rect.fromLTWH(w * 0.4, h * 0.48, w * 0.15, h * 0.075), '24H');
    // Rain.
    final rain = Paint()
      ..color = const Color(0xFFB7D7FF).withAlpha(70)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 90; i++) {
      final x = (i * 91 + t * 140 + flicker * 12) % w;
      final y = (i * 47 + t * 320) % h;
      canvas.drawLine(Offset(x, y), Offset(x - 5, y + 18), rain);
    }
    // Car and headlights.
    final carY = h * 0.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.56, carY, w * 0.22, h * 0.085),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFF1B1220),
    );
    canvas.drawCircle(
      Offset(w * 0.61, carY + h * 0.09),
      10,
      Paint()..color = const Color(0xFF08060A),
    );
    canvas.drawCircle(
      Offset(w * 0.73, carY + h * 0.09),
      10,
      Paint()..color = const Color(0xFF08060A),
    );
    final beam = Path()
      ..moveTo(w * 0.78, carY + 8)
      ..lineTo(w * 0.98, carY - 10)
      ..lineTo(w * 0.98, carY + 30)
      ..close();
    canvas.drawPath(
      beam,
      Paint()..color = const Color(0xFFFFE7A3).withAlpha(40),
    );
    // Film title.
    _text(
      canvas,
      'NEON HARBOR',
      Offset(w * 0.06, h * 0.08),
      30,
      const Color(0xFFFFD1E8),
      weight: FontWeight.w900,
      letterSpacing: 4,
      shadow: true,
    );
    _text(
      canvas,
      'a rainy-night mystery',
      Offset(w * 0.065, h * 0.145),
      11,
      const Color(0xFFAEB6D9),
      letterSpacing: 1.2,
    );
  }

  void _neon(Canvas canvas, Rect rect, String text) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = const Color(0xFF0A0814).withAlpha(200),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFF5EA8).withAlpha(190),
    );
    _text(
      canvas,
      text,
      Offset(rect.left + 10, rect.top + rect.height * 0.28),
      15,
      const Color(0xFFFF9CC6),
      weight: FontWeight.w900,
      letterSpacing: 2,
      shadow: true,
    );
  }

  void _internet(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bg = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      bg,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF061A2B), Color(0xFF0A2C43), Color(0xFF061019)],
        ).createShader(bg),
    );
    final browser = Rect.fromLTWH(w * 0.08, h * 0.12, w * 0.84, h * 0.74);
    canvas.drawRRect(
      RRect.fromRectAndRadius(browser, const Radius.circular(16)),
      Paint()..color = const Color(0xFFF2EFE7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(browser.left, browser.top, browser.width, 38),
        const Radius.circular(16),
      ),
      Paint()..color = const Color(0xFFE3DED3),
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(browser.left + 16 + i * 14, browser.top + 16),
        4,
        Paint()
          ..color = [
            const Color(0xFFFF6B6B),
            const Color(0xFFFFD166),
            const Color(0xFF6BCB77),
          ][i],
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          browser.left + 80,
          browser.top + 9,
          browser.width - 100,
          20,
        ),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFFF7F4ED),
    );
    _text(
      canvas,
      'retroweb.home',
      Offset(browser.left + 92, browser.top + 14),
      9,
      const Color(0xFF6E6A61),
    );
    // Sidebar.
    canvas.drawRect(
      Rect.fromLTWH(
        browser.left,
        browser.top + 38,
        browser.width * 0.22,
        browser.height - 38,
      ),
      Paint()..color = const Color(0xFFE9E3D7),
    );
    _text(
      canvas,
      'HOME',
      Offset(browser.left + 16, browser.top + 56),
      10,
      const Color(0xFF2B5B7A),
      weight: FontWeight.w900,
      letterSpacing: 1,
    );
    for (var i = 0; i < 5; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            browser.left + 14,
            browser.top + 82 + i * 24,
            browser.width * 0.13,
            8,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFCEC6B8),
      );
    }
    // Main content.
    final mainLeft = browser.left + browser.width * 0.26;
    _text(
      canvas,
      'RetroWeb',
      Offset(mainLeft, browser.top + 58),
      28,
      const Color(0xFF143D5C),
      weight: FontWeight.w900,
    );
    _text(
      canvas,
      'the internet, one slow page at a time',
      Offset(mainLeft, browser.top + 94),
      10,
      const Color(0xFF6E6A61),
    );
    final search = Rect.fromLTWH(
      mainLeft,
      browser.top + 116,
      browser.width * 0.52,
      28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(search, const Radius.circular(14)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(search, const Radius.circular(14)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF2B5B7A).withAlpha(120),
    );
    _text(
      canvas,
      'search the web...',
      Offset(search.left + 12, search.top + 8),
      10,
      const Color(0xFF99928A),
    );
    // Blinking text cursor and cards.
    if ((t * 8).floor().isEven) {
      canvas.drawRect(
        Rect.fromLTWH(search.right - 20, search.top + 7, 2, 14),
        Paint()..color = const Color(0xFF143D5C),
      );
    }
    final cardColors = [
      const Color(0xFF7FC8A9),
      const Color(0xFFFFD166),
      const Color(0xFF8ECAE6),
      const Color(0xFFE8A0BF),
    ];
    for (var i = 0; i < 4; i++) {
      final card = Rect.fromLTWH(
        mainLeft + (i % 2) * (browser.width * 0.27),
        browser.top + 164 + (i ~/ 2) * 64,
        browser.width * 0.24,
        52,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(card, const Radius.circular(9)),
        Paint()..color = cardColors[i].withAlpha(210),
      );
      _text(
        canvas,
        ['CAT VIDEOS', 'RECIPES', 'FORUM', 'QUIZ'][i],
        Offset(card.left + 8, card.top + 8),
        9,
        const Color(0xFF143D5C),
        weight: FontWeight.w900,
        letterSpacing: 0.8,
      );
    }
    // Loading bar.
    final loadWidth =
        browser.width *
        0.4 *
        (0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * math.pi * 2)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(mainLeft, browser.bottom - 34, browser.width * 0.4, 8),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFD4CEC2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(mainLeft, browser.bottom - 34, loadWidth, 8),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF2B5B7A),
    );
    _text(
      canvas,
      'loading...',
      Offset(mainLeft, browser.bottom - 22),
      8.5,
      const Color(0xFF6E6A61),
    );
  }

  void _news(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bg = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      bg,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071D3A), Color(0xFF0B2C57), Color(0xFF04111F)],
        ).createShader(bg),
    );
    // Studio screen with globe.
    final screen = Rect.fromLTWH(w * 0.08, h * 0.12, w * 0.84, h * 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(screen, const Radius.circular(18)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF153A64), Color(0xFF0A1C33)],
        ).createShader(screen),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(screen, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF3C7FB8).withAlpha(130),
    );
    final globeCenter = Offset(screen.center.dx, screen.center.dy - 6);
    final globeR = screen.height * 0.32;
    canvas.drawCircle(
      globeCenter,
      globeR,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF49A6D8), Color(0xFF1B5D8C), Color(0xFF0A2742)],
        ).createShader(Rect.fromCircle(center: globeCenter, radius: globeR)),
    );
    for (var i = 0; i < 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: globeCenter + Offset(0, -globeR * 0.55 + i * globeR * 0.28),
          width: globeR * 1.8,
          height: globeR * 0.18,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withAlpha(55),
      );
    }
    canvas.drawArc(
      Rect.fromCenter(
        center: globeCenter,
        width: globeR * 1.15,
        height: globeR * 2,
      ),
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withAlpha(65),
    );
    // Anchor silhouette.
    final anchorX = w * 0.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(anchorX, h * 0.5),
        width: w * 0.075,
        height: h * 0.09,
      ),
      Paint()..color = const Color(0xFF1A1216),
    );
    canvas.drawPath(
      Path()
        ..moveTo(anchorX - w * 0.095, h * 0.68)
        ..quadraticBezierTo(
          anchorX - w * 0.075,
          h * 0.56,
          anchorX - w * 0.035,
          h * 0.55,
        )
        ..lineTo(anchorX + w * 0.035, h * 0.55)
        ..quadraticBezierTo(
          anchorX + w * 0.075,
          h * 0.56,
          anchorX + w * 0.095,
          h * 0.68,
        )
        ..close(),
      Paint()..color = const Color(0xFF23171E),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.67, w, h * 0.08),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B241C), Color(0xFF1A0F0B)],
        ).createShader(Rect.fromLTWH(0, h * 0.67, w, h * 0.08)),
    );
    // Lower third.
    final ticker = Rect.fromLTWH(0, h * 0.77, w, h * 0.09);
    canvas.drawRect(ticker, Paint()..color = const Color(0xFFB3261E));
    _text(
      canvas,
      'BREAKING',
      Offset(w * 0.03, h * 0.79),
      13,
      Colors.white,
      weight: FontWeight.w900,
      letterSpacing: 1.2,
    );
    final tickerText =
        'Local bakery wins county pie contest · Bus route 7 back on schedule · Clear skies tonight · ';
    final scroll = (t * w * 0.9) % (tickerText.length * 7.0);
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(w * 0.18, ticker.top, w * 0.82, ticker.height),
    );
    _text(
      canvas,
      tickerText,
      Offset(w * 0.18 - scroll, h * 0.79),
      11,
      Colors.white,
      weight: FontWeight.w600,
    );
    canvas.restore();
    // Channel bug and clock.
    _text(
      canvas,
      'CH 7',
      Offset(w * 0.88, h * 0.17),
      14,
      const Color(0xFFFFD166),
      weight: FontWeight.w900,
      letterSpacing: 1.5,
    );
    _text(
      canvas,
      'LIVE',
      Offset(w * 0.05, h * 0.17),
      10,
      const Color(0xFFFF8FA3),
      weight: FontWeight.w900,
      letterSpacing: 1.4,
    );
    _text(
      canvas,
      'EVENING REPORT',
      Offset(w * 0.05, h * 0.67),
      12,
      Colors.white,
      weight: FontWeight.w800,
      letterSpacing: 1.2,
    );
  }

  void _cartoon(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bg = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      bg,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8ED8F8), Color(0xFFC7F0FF), Color(0xFFFFF3C4)],
          stops: [0, 0.58, 1],
        ).createShader(bg),
    );
    // Sun.
    final sun = Offset(w * 0.82, h * 0.2);
    canvas.drawCircle(sun, h * 0.09, Paint()..color = const Color(0xFFFFD166));
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6 + t * 0.2;
      canvas.drawLine(
        sun + Offset(math.cos(a), math.sin(a)) * h * 0.1,
        sun + Offset(math.cos(a), math.sin(a)) * h * 0.14,
        Paint()
          ..color = const Color(0xFFFFC857)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      sun + Offset(-10, -4),
      3,
      Paint()..color = const Color(0xFF3A2A12),
    );
    canvas.drawCircle(
      sun + Offset(10, -4),
      3,
      Paint()..color = const Color(0xFF3A2A12),
    );
    canvas.drawArc(
      Rect.fromCenter(center: sun + const Offset(0, 6), width: 16, height: 10),
      0.1,
      math.pi - 0.2,
      false,
      Paint()
        ..color = const Color(0xFF3A2A12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Clouds.
    for (var i = 0; i < 4; i++) {
      final cx = ((i * w * 0.31 + t * 40) % (w + 160)) - 80;
      final cy = h * (0.1 + (i % 3) * 0.09);
      _cloud(canvas, Offset(cx, cy), 1.0 + (i % 2) * 0.35);
    }
    // Hills.
    final hill1 = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.22, h * 0.48, w * 0.5, h * 0.7)
      ..quadraticBezierTo(w * 0.78, h * 0.5, w, h * 0.7)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill1, Paint()..color = const Color(0xFF8BCB7A));
    final hill2 = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.28, h * 0.64, w * 0.58, h * 0.82)
      ..quadraticBezierTo(w * 0.82, h * 0.7, w, h * 0.82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill2, Paint()..color = const Color(0xFF4E9E5B));
    // Pancake characters.
    for (var i = 0; i < 3; i++) {
      final bounce = math.sin(t * math.pi * 2 + i * 1.7).abs() * h * 0.04;
      final cx = w * (0.2 + i * 0.3);
      final cy = h * 0.68 - bounce;
      _pancake(canvas, Offset(cx, cy), h * 0.08, i);
    }
    // Title.
    _text(
      canvas,
      'PANCAKE PALS',
      Offset(w * 0.05, h * 0.06),
      32,
      const Color(0xFFFF6B6B),
      weight: FontWeight.w900,
      letterSpacing: 2,
      shadow: true,
    );
    _text(
      canvas,
      'today: the great syrup slide',
      Offset(w * 0.055, h * 0.135),
      11,
      const Color(0xFF1E6A6A),
      weight: FontWeight.w700,
      letterSpacing: 0.8,
    );
  }

  void _cloud(Canvas canvas, Offset c, double s) {
    final paint = Paint()..color = Colors.white.withAlpha(210);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 72 * s, height: 26 * s),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(-22 * s, -10 * s),
        width: 42 * s,
        height: 30 * s,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(18 * s, -12 * s),
        width: 38 * s,
        height: 28 * s,
      ),
      paint,
    );
  }

  void _pancake(Canvas canvas, Offset c, double r, int index) {
    // Little legs.
    final legPaint = Paint()
      ..color = const Color(0xFF5A3418)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      c + Offset(-r * 0.35, r * 0.55),
      c + Offset(-r * 0.5, r * 0.95),
      legPaint,
    );
    canvas.drawLine(
      c + Offset(r * 0.35, r * 0.55),
      c + Offset(r * 0.5, r * 0.95),
      legPaint,
    );
    // Stacked pancakes.
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(0, r * 0.25 - i * r * 0.18),
          width: r * 1.6,
          height: r * 0.7,
        ),
        Paint()..color = const Color(0xFFD99A4E),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(0, r * 0.22 - i * r * 0.18),
          width: r * 1.35,
          height: r * 0.5,
        ),
        Paint()..color = const Color(0xFFF2C078),
      );
    }
    // Butter.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c + Offset(0, -r * 0.36),
          width: r * 0.38,
          height: r * 0.24,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFFF3B0),
    );
    // Face.
    canvas.drawCircle(
      c + Offset(-r * 0.24, -r * 0.02),
      r * 0.075,
      Paint()..color = const Color(0xFF3A2412),
    );
    canvas.drawCircle(
      c + Offset(r * 0.24, -r * 0.02),
      r * 0.075,
      Paint()..color = const Color(0xFF3A2412),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.16),
        width: r * 0.42,
        height: r * 0.24,
      ),
      0.1,
      math.pi - 0.2,
      false,
      Paint()
        ..color = const Color(0xFF3A2412)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _screenTexture(Canvas canvas, Size size) {
    // Scanlines.
    for (var y = 0.0; y < size.height; y += 4) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()..color = Colors.black.withAlpha(12),
      );
    }
    // Curved-glass vignette.
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withAlpha(120)],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
    // Faint moving highlight.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-1, -1),
          end: Alignment(1, 1),
          colors: [Colors.white.withAlpha(8), Colors.transparent],
          stops: [0, 0.45 + 0.15 * math.sin(t * math.pi * 2)],
        ).createShader(rect),
    );
  }

  static void _text(
    Canvas canvas,
    String text,
    Offset at,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 0,
    bool shadow = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          shadows: shadow
              ? const [Shadow(color: Colors.black54, blurRadius: 8)]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _TvContentPainter oldDelegate) =>
      oldDelegate.channel != channel ||
      oldDelegate.t != t ||
      oldDelegate.flicker != flicker;
}
