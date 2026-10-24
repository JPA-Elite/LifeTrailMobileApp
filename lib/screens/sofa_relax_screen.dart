import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/state/game_state.dart';
import '../models/player_model.dart';

/// Returned when the player stands up from the sofa.
class SofaRelaxResult {
  const SofaRelaxResult({required this.gained, required this.reachedFull});

  /// Happiness points earned during this sitting.
  final int gained;

  /// True when the sitting ended because happiness reached the maximum.
  final bool reachedFull;
}

/// Full-screen "relax on the sofa" scene.
///
/// The player sinks into the home sofa while a cozy, animated living room
/// plays behind a happiness meter. Every five seconds the meter ticks up by
/// one point. When happiness fills, the scene celebrates and stands the
/// player up automatically; the Leave button does the same at any time.
class SofaRelaxScreen extends ConsumerStatefulWidget {
  const SofaRelaxScreen({super.key});

  @override
  ConsumerState<SofaRelaxScreen> createState() => _SofaRelaxScreenState();
}

class _SofaRelaxScreenState extends ConsumerState<SofaRelaxScreen>
    with TickerProviderStateMixin {
  static const int _secondsPerPoint = 5;
  static const int _maxHappiness = PlayerModel.happinessMax;
  static const Duration _celebrationTime = Duration(milliseconds: 1900);

  static const List<String> _thoughts = [
    'The cushions hug you back.',
    'The TV murmurs something warm.',
    'Dust motes drift through the sunset.',
    'Your shoulders finally let go.',
    'Somewhere, a kettle hums.',
    'This is exactly where you need to be.',
    'The room breathes with you.',
  ];

  late final AnimationController _ambient;
  late final AnimationController _breath;
  late final AnimationController _cycle;
  late final AnimationController _plus;

  Timer? _timer;
  Timer? _autoClose;
  bool _popped = false;
  bool _celebrating = false;
  int _gained = 0;
  int _thought = 0;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _cycle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _secondsPerPoint),
    )..repeat();
    _plus = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Defensive: GameScreen refuses to open the scene at full happiness,
    // but if it ever is full, celebrate briefly and stand up without
    // trying to add anything.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(gameStateProvider).player.happiness >= _maxHappiness) {
        _autoStandUp();
      }
    });

    _timer = Timer.periodic(const Duration(seconds: _secondsPerPoint), (_) {
      if (!mounted || _popped) return;
      final gs = ref.read(gameStateProvider);
      if (gs.player.happiness >= _maxHappiness) {
        _autoStandUp();
        return;
      }
      final next = gs.addHappiness(1);
      if (!mounted) return;
      setState(() {
        _gained++;
        _thought = (_thought + 1) % _thoughts.length;
      });
      _cycle.forward(from: 0);
      _plus.forward(from: 0);
      if (next >= _maxHappiness) _autoStandUp();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoClose?.cancel();
    _ambient.dispose();
    _breath.dispose();
    _cycle.dispose();
    _plus.dispose();
    super.dispose();
  }

  /// Stand up now (Leave button).
  void _standUp() {
    if (_popped) return;
    _timer?.cancel();
    _autoClose?.cancel();
    _popped = true;
    Navigator.of(
      context,
    ).pop(SofaRelaxResult(gained: _gained, reachedFull: _celebrating));
  }

  /// Happiness is full: show the celebration, then stand up automatically.
  void _autoStandUp() {
    if (_popped || _celebrating) return;
    _timer?.cancel();
    _cycle.stop();
    setState(() => _celebrating = true);
    _autoClose = Timer(_celebrationTime, () {
      if (!mounted || _popped) return;
      _popped = true;
      Navigator.of(
        context,
      ).pop(SofaRelaxResult(gained: _gained, reachedFull: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final happiness = state.player.happiness;

    return Scaffold(
      backgroundColor: const Color(0xFF150F1C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_ambient, _breath]),
            builder: (context, _) => CustomPaint(
              painter: _CozyRoomPainter(
                ambient: _ambient.value,
                breath: _breath.value,
                celebrating: _celebrating,
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 700;
                if (wide) {
                  return Stack(
                    children: [
                      const Align(
                        alignment: Alignment.topLeft,
                        child: _QuietPill(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(width: 336, child: _panel(happiness)),
                      ),
                      Align(
                        alignment: const Alignment(-0.24, -0.04),
                        child: _PlusOne(controller: _plus),
                      ),
                    ],
                  );
                }
                return Stack(
                  children: [
                    const Align(
                      alignment: Alignment.topLeft,
                      child: _QuietPill(),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: _panel(happiness),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, -0.25),
                      child: _PlusOne(controller: _plus),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_celebrating) const _CelebrationOverlay(),
        ],
      ),
    );
  }

  Widget _panel(int happiness) {
    final fraction = (happiness / _maxHappiness).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF150F1C).withAlpha(224),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withAlpha(26)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF4B7AAE), Color(0xFF2E4C74)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.weekend,
                    color: Color(0xFFFFE3B0),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home · living room',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Take a breath. You earned it.',
                        style: TextStyle(
                          color: Color(0xFFB9A9C6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Happiness',
                  style: TextStyle(
                    color: Color(0xFFEADFF2),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Text(
                  '$happiness',
                  style: TextStyle(
                    color: _celebrating
                        ? const Color(0xFFFFD27A)
                        : Colors.white,
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  ' / $_maxHappiness',
                  style: const TextStyle(
                    color: Color(0xFFB9A9C6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            _HappinessBar(fraction: fraction, celebrating: _celebrating),
            const SizedBox(height: 5),
            Text(
              _gained == 0
                  ? 'Settle in and let the room slow down…'
                  : '+$_gained happiness this sitting',
              style: const TextStyle(color: Color(0xFF9F8DAE), fontSize: 11),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                AnimatedBuilder(
                  animation: _cycle,
                  builder: (context, _) => SizedBox(
                    width: 48,
                    height: 48,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: _celebrating ? 1 : _cycle.value,
                        celebrating: _celebrating,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _cycle,
                    builder: (context, _) {
                      if (_celebrating) {
                        return const Text(
                          'Happiness is full!',
                          style: TextStyle(
                            color: Color(0xFFFFD27A),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }
                      final seconds = (_secondsPerPoint * (1 - _cycle.value))
                          .ceil()
                          .clamp(1, _secondsPerPoint);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next +1 happiness in ${seconds}s',
                            style: const TextStyle(
                              color: Color(0xFFEADFF2),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Every 5 seconds, while you unwind.',
                            style: TextStyle(
                              color: Color(0xFF9F8DAE),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                _thoughts[_thought],
                key: ValueKey(_thought),
                style: const TextStyle(
                  color: Color(0xFFCDBDD8),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _standUp,
                icon: const Icon(Icons.directions_walk, size: 19),
                label: Text(_celebrating ? 'Stand up' : 'Leave the sofa'),
                style: FilledButton.styleFrom(
                  backgroundColor: _celebrating
                      ? const Color(0xFFFFD27A)
                      : const Color(0xFFE8A06A),
                  foregroundColor: const Color(0xFF2A1720),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Happiness stops at $_maxHappiness · you stand up automatically',
                style: TextStyle(color: Color(0xFF7E6D8D), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small floating label in the corner of the scene.
class _QuietPill extends StatelessWidget {
  const _QuietPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF150F1C).withAlpha(170),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(24)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.spa, color: Color(0xFFFFD27A), size: 15),
          SizedBox(width: 6),
          Text(
            'A quiet moment',
            style: TextStyle(
              color: Color(0xFFEADFF2),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// The animated happiness bar. Each gain tweens from the previous fill to
/// the new one, with a soft shine sweeping across the filled part.
class _HappinessBar extends StatelessWidget {
  const _HappinessBar({required this.fraction, required this.celebrating});

  final double fraction;
  final bool celebrating;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 14,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.white.withAlpha(24)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7A8A), Color(0xFFFFC46B)],
                        ),
                        boxShadow: celebrating
                            ? const [
                                BoxShadow(
                                  color: Color(0xAAFFD27A),
                                  blurRadius: 14,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withAlpha(0),
                              Colors.white.withAlpha(70),
                              Colors.white.withAlpha(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The five-second countdown ring around a little heart.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.celebrating});

  final double progress;
  final bool celebrating;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 3;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..color = Colors.white.withAlpha(28),
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: celebrating
            ? const [Color(0xFFFFD27A), Color(0xFFFFF0C2)]
            : const [Color(0xFFFF7A8A), Color(0xFFFFC46B)],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );

    canvas.drawPath(
      _heartPath(center, size.shortestSide * 0.15),
      Paint()
        ..color = celebrating
            ? const Color(0xFFFFE3A3)
            : const Color(0xFFFF9BAA),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.celebrating != celebrating;
}

/// A "+1" heart that floats up and fades after every gain.
class _PlusOne extends StatelessWidget {
  const _PlusOne({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          if (t == 0 || t >= 1) return const SizedBox.shrink();
          final eased = Curves.easeOutCubic.transform(t);
          final scale = t < 0.18
              ? 0.55 + (t / 0.18) * 0.75
              : 1.3 - ((t - 0.18) / 0.82) * 0.2;
          return Opacity(
            opacity: (1 - eased).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -70 * eased),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1720).withAlpha(210),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFFF9BAA).withAlpha(120),
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66FF7A8A), blurRadius: 18),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, color: Color(0xFFFF8FA0), size: 18),
                      SizedBox(width: 5),
                      Text(
                        '+1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Warm overlay shown for a moment when happiness hits 100.
class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [const Color(0xFFFFD27A).withAlpha(70), Colors.transparent],
          ),
        ),
        child: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Align(
            alignment: const Alignment(-0.24, -0.55),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.7, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1720).withAlpha(230),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD27A).withAlpha(140),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x88FFD27A), blurRadius: 30),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFFD27A),
                      size: 30,
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pure bliss!',
                          style: TextStyle(
                            color: Color(0xFFFFE3A3),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Happiness full — standing up…',
                          style: TextStyle(
                            color: Color(0xFFCDBDD8),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The scene painter
// ---------------------------------------------------------------------------

class _Mote {
  const _Mote({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.heart,
  });

  final double x;
  final double phase;
  final double speed;
  final double size;
  final bool heart;
}

class _CozyRoomPainter extends CustomPainter {
  _CozyRoomPainter({
    required this.ambient,
    required this.breath,
    required this.celebrating,
  });

  /// 0..1, looping slowly: drifts motes and the lamp's shimmer.
  final double ambient;

  /// 0..1, looping back and forth: breathing and the TV glow.
  final double breath;

  final bool celebrating;

  static const double _designW = 1000;
  static const double _designH = 600;

  static final List<_Mote> _motes = () {
    final r = math.Random(7);
    return List.generate(30, (_) {
      return _Mote(
        x: r.nextDouble() * 1000,
        phase: r.nextDouble(),
        speed: 0.35 + r.nextDouble() * 0.8,
        size: 1.8 + r.nextDouble() * 3.4,
        heart: r.nextDouble() < 0.35,
      );
    });
  }();

  @override
  void paint(Canvas canvas, Size size) {
    // Fill the area outside the room first. The room itself is fitted with
    // `contain` (not `cover`) and pinned to the left: the right side of the
    // screen is covered by the controls panel, and an ultra-wide phone would
    // otherwise crop the sofa's feet, rug and cat off the bottom.
    _paintBackdrop(canvas, size);

    final scale = math.min(size.width / _designW, size.height / _designH);
    final dx = 0.0;
    final dy = (size.height - _designH * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    _paintWall(canvas);
    _paintWindow(canvas);
    _paintStringLights(canvas);
    _paintFloor(canvas);
    _paintRug(canvas);
    _paintFloorLamp(canvas);
    _paintSofa(canvas);
    _paintSideTable(canvas);
    _paintCat(canvas);
    _paintFigure(canvas);
    _paintGlows(canvas);
    _paintMotes(canvas);
    _paintVignette(canvas);

    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas, Size size) {
    final wall = Rect.fromLTWH(0, 0, size.width, size.height * 0.76);
    canvas.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B1B33), Color(0xFF5B3147), Color(0xFFA15A56)],
          stops: [0, 0.55, 1],
        ).createShader(wall),
    );
    final floor = Rect.fromLTWH(
      0,
      size.height * 0.76,
      size.width,
      size.height * 0.24,
    );
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3D241D), Color(0xFF1E110F)],
        ).createShader(floor),
    );
  }

  void _paintWall(Canvas canvas) {
    final wall = Rect.fromLTWH(0, 0, _designW, 456);
    canvas.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B1B33), Color(0xFF5B3147), Color(0xFFA15A56)],
          stops: [0, 0.55, 1],
        ).createShader(wall),
    );

    // A faint diamond-pattern wallpaper, just enough to read as a home.
    final pattern = Paint()
      ..color = Colors.white.withAlpha(6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var y = 90.0; y < 430; y += 54) {
      for (var x = 20.0; x < 980; x += 54) {
        canvas.drawPath(
          Path()
            ..moveTo(x, y - 12)
            ..lineTo(x + 12, y)
            ..lineTo(x, y + 12)
            ..lineTo(x - 12, y),
          pattern,
        );
      }
    }

    // Sunlight spilling in from the window.
    canvas.save();
    canvas.clipRect(wall);
    canvas.drawPath(
      Path()
        ..moveTo(120, 120)
        ..lineTo(560, 456)
        ..lineTo(330, 456)
        ..lineTo(20, 210)
        ..close(),
      Paint()..color = const Color(0x14FFD9A0),
    );
    canvas.drawPath(
      Path()
        ..moveTo(210, 100)
        ..lineTo(720, 456)
        ..lineTo(640, 456)
        ..lineTo(130, 160)
        ..close(),
      Paint()..color = const Color(0x0FFFF2CC),
    );
    canvas.restore();

    // Baseboard.
    canvas.drawRect(
      const Rect.fromLTWH(0, 438, _designW, 18),
      Paint()..color = const Color(0xFF241318),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 438, _designW, 2.5),
      Paint()..color = const Color(0xFF7E4A4A),
    );
  }

  void _paintWindow(Canvas canvas) {
    // Casing.
    final casing = RRect.fromRectAndRadius(
      const Rect.fromLTWH(22, 28, 292, 336),
      const Radius.circular(22),
    );
    canvas.drawRRect(casing, Paint()..color = const Color(0xFF3A2226));
    canvas.drawRRect(
      casing.deflate(7),
      Paint()..color = const Color(0xFF24141A),
    );

    // Glass.
    final glass = RRect.fromRectAndRadius(
      const Rect.fromLTWH(36, 42, 264, 308),
      const Radius.circular(15),
    );
    canvas.save();
    canvas.clipRRect(glass);
    final glassRect = glass.outerRect;
    canvas.drawRect(
      glassRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5D4578),
            Color(0xFFB65E70),
            Color(0xFFFF9A6B),
            Color(0xFFFFD49A),
          ],
          stops: [0, 0.42, 0.72, 1],
        ).createShader(glassRect),
    );

    // Sun and its halo.
    final sun = Offset(214, 292);
    canvas.drawCircle(
      sun,
      74,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE3A3).withAlpha(150),
            const Color(0xFFFFE3A3).withAlpha(0),
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: 74)),
    );
    canvas.drawCircle(sun, 25, Paint()..color = const Color(0xFFFFF0C2));

    // Clouds.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(110, 120), width: 120, height: 26),
      Paint()..color = const Color(0x33FFE3D0),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(175, 145), width: 90, height: 18),
      Paint()..color = const Color(0x26FFE3D0),
    );

    // Rolling hills.
    canvas.drawPath(
      Path()
        ..moveTo(30, 314)
        ..quadraticBezierTo(96, 282, 160, 314)
        ..quadraticBezierTo(224, 288, 308, 326)
        ..lineTo(308, 354)
        ..lineTo(30, 354)
        ..close(),
      Paint()..color = const Color(0xFF6B3F5B),
    );
    canvas.drawPath(
      Path()
        ..moveTo(30, 334)
        ..quadraticBezierTo(120, 312, 196, 338)
        ..quadraticBezierTo(252, 322, 308, 344)
        ..lineTo(308, 354)
        ..lineTo(30, 354)
        ..close(),
      Paint()..color = const Color(0xFF43283D),
    );

    // Birds.
    final bird = Paint()
      ..color = const Color(0xAA2C1A28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final b in const [Offset(100, 82), Offset(132, 96)]) {
      canvas.drawPath(
        Path()
          ..moveTo(b.dx - 7, b.dy)
          ..quadraticBezierTo(b.dx - 2, b.dy - 5, b.dx, b.dy)
          ..quadraticBezierTo(b.dx + 2, b.dy - 5, b.dx + 7, b.dy),
        bird,
      );
    }

    // Glass reflection.
    canvas.drawPath(
      Path()
        ..moveTo(48, 42)
        ..lineTo(112, 42)
        ..lineTo(36, 200)
        ..lineTo(36, 120)
        ..close(),
      Paint()..color = Colors.white.withAlpha(22),
    );

    // Mullions.
    final bar = Paint()..color = const Color(0xFF3A2226);
    canvas.drawRect(const Rect.fromLTWH(164, 42, 7, 308), bar);
    canvas.drawRect(const Rect.fromLTWH(36, 192, 264, 7), bar);
    canvas.restore();

    // Curtains (drawn outside the clip so they overlap the casing).
    final leftCurtain = Path()
      ..moveTo(0, 20)
      ..lineTo(78, 20)
      ..quadraticBezierTo(58, 170, 70, 392)
      ..lineTo(0, 392)
      ..close();
    final rightCurtain = Path()
      ..moveTo(264, 20)
      ..lineTo(338, 20)
      ..lineTo(338, 392)
      ..lineTo(274, 392)
      ..quadraticBezierTo(286, 170, 264, 20)
      ..close();
    canvas.drawPath(leftCurtain, Paint()..color = const Color(0xFFB45D63));
    canvas.drawPath(rightCurtain, Paint()..color = const Color(0xFFB45D63));

    final fold = Paint()
      ..color = const Color(0x558A3E49)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    for (final f in const [0.22, 0.48, 0.74]) {
      final x = 14 + f * 56;
      canvas.drawPath(
        Path()
          ..moveTo(x, 32)
          ..quadraticBezierTo(x - 7, 200, x - 2, 382),
        fold,
      );
    }
    for (final f in const [0.22, 0.48, 0.74]) {
      final x = 322 - f * 56;
      canvas.drawPath(
        Path()
          ..moveTo(x, 32)
          ..quadraticBezierTo(x - 7, 200, x - 2, 382),
        fold,
      );
    }

    // Rod and finials.
    final rod = Paint()
      ..color = const Color(0xFF241420)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-4, 16), const Offset(344, 16), rod);
    canvas.drawCircle(
      const Offset(348, 16),
      7,
      Paint()..color = const Color(0xFF3A2226),
    );
    canvas.drawCircle(
      const Offset(-8, 16),
      7,
      Paint()..color = const Color(0xFF3A2226),
    );
  }

  void _paintStringLights(Canvas canvas) {
    final wire = Path()
      ..moveTo(-10, 34)
      ..quadraticBezierTo(450, 132, 915, 28);
    canvas.drawPath(
      wire,
      Paint()
        ..color = const Color(0x66241420)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final pulse = 0.55 + 0.45 * math.sin(breath * math.pi);
    for (var i = 0; i < 15; i++) {
      final t = (i + 0.5) / 15;
      final x = _quad(-10, 450, 915, t);
      final y = _quad(34, 132, 28, t) + 5;
      canvas.drawCircle(
        Offset(x, y),
        8,
        Paint()
          ..color = const Color(0xFFFFD27A).withAlpha((26 * pulse).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawCircle(
        Offset(x, y),
        3.1,
        Paint()..color = const Color(0xFFFFE8B8).withAlpha(220),
      );
    }
  }

  void _paintFloor(Canvas canvas) {
    final floor = Rect.fromLTWH(0, 456, _designW, 144);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3D241D), Color(0xFF1E110F)],
        ).createShader(floor),
    );

    // Warm window light on the boards.
    canvas.drawPath(
      Path()
        ..moveTo(40, 456)
        ..lineTo(330, 456)
        ..lineTo(420, 600)
        ..lineTo(90, 600)
        ..close(),
      Paint()..color = const Color(0x12FFD49A),
    );

    // Perspective planks.
    final seam = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 2;
    for (final x in const [
      -180.0,
      -20.0,
      140.0,
      300.0,
      460.0,
      620.0,
      780.0,
      940.0,
      1100.0,
      1260.0,
    ]) {
      canvas.drawLine(
        Offset(500 + (x - 500) * 0.08, 456),
        Offset(x, 600),
        seam,
      );
    }
    final cross = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 2;
    for (final y in const [488.0, 524.0, 566.0]) {
      canvas.drawLine(Offset(0, y), Offset(_designW, y), cross);
    }
  }

  void _paintRug(Canvas canvas) {
    final rug = Rect.fromCenter(
      center: const Offset(410, 542),
      width: 620,
      height: 122,
    );
    canvas.drawOval(rug, Paint()..color = const Color(0xFF7B3F3A));
    canvas.drawOval(rug.deflate(11), Paint()..color = const Color(0xFFB96A55));
    canvas.drawOval(
      rug.deflate(30),
      Paint()
        ..color = const Color(0x66FFE3B0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    final motif = Paint()
      ..color = const Color(0x55FFE3B0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final x in const [290.0, 410.0, 530.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 528)
          ..lineTo(x + 15, 542)
          ..lineTo(x, 556)
          ..lineTo(x - 15, 542)
          ..close(),
        motif,
      );
    }
  }

  void _paintFloorLamp(Canvas canvas) {
    // Base.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(112, 546), width: 80, height: 18),
      Paint()..color = const Color(0xFF2A1A22),
    );
    // Pole.
    canvas.drawLine(
      const Offset(112, 538),
      const Offset(112, 396),
      Paint()
        ..color = const Color(0xFF46313A)
        ..strokeWidth = 5,
    );
    // Shade.
    canvas.drawPath(
      Path()
        ..moveTo(76, 330)
        ..lineTo(148, 330)
        ..lineTo(164, 402)
        ..lineTo(60, 402)
        ..close(),
      Paint()..color = const Color(0xFFF2C17D),
    );
    canvas.drawPath(
      Path()
        ..moveTo(76, 330)
        ..lineTo(148, 330)
        ..lineTo(164, 402)
        ..lineTo(60, 402)
        ..close(),
      Paint()
        ..color = const Color(0x66A86A2E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRect(
      const Rect.fromLTWH(88, 396, 48, 7),
      Paint()..color = const Color(0xFFD99A54),
    );
  }

  void _paintSofa(Canvas canvas) {
    const ink = Color(0xFF1B2A40);
    final body = Paint()..color = const Color(0xFF2E4C74);
    final cushion = Paint()..color = const Color(0xFF3E6797);

    // Back.
    final back = RRect.fromRectAndRadius(
      const Rect.fromLTWH(206, 342, 378, 126),
      const Radius.circular(28),
    );
    canvas.drawRRect(back, body);
    canvas.drawRRect(
      back,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Three back cushions.
    for (final r in const [
      Rect.fromLTWH(220, 354, 108, 96),
      Rect.fromLTWH(336, 354, 118, 96),
      Rect.fromLTWH(462, 354, 108, 96),
    ]) {
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(18));
      canvas.drawRRect(rr, cushion);
      canvas.drawRRect(
        rr.deflate(7),
        Paint()
          ..color = const Color(0x22FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(
        Offset(r.center.dx, r.top + 12),
        3,
        Paint()..color = const Color(0x661B2A40),
      );
    }

    // Arms.
    for (final r in const [
      Rect.fromLTWH(186, 388, 58, 120),
      Rect.fromLTWH(546, 388, 58, 120),
    ]) {
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(24));
      canvas.drawRRect(rr, body);
      canvas.drawRRect(
        rr,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left + 8, r.top + 8, r.width - 16, 30),
          const Radius.circular(12),
        ),
        Paint()..color = const Color(0x2AFFFFFF),
      );
    }

    // Seat.
    final seat = RRect.fromRectAndRadius(
      const Rect.fromLTWH(210, 434, 380, 66),
      const Radius.circular(18),
    );
    canvas.drawRRect(seat, Paint()..color = const Color(0xFF4B7AAE));
    canvas.drawRRect(
      seat,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    for (final x in const [336.0, 464.0]) {
      canvas.drawLine(
        Offset(x, 440),
        Offset(x, 494),
        Paint()
          ..color = const Color(0x552A4567)
          ..strokeWidth = 2.5,
      );
    }

    // Base and feet.
    final base = RRect.fromRectAndRadius(
      const Rect.fromLTWH(206, 496, 388, 30),
      const Radius.circular(10),
    );
    canvas.drawRRect(base, Paint()..color = const Color(0xFF28415F));
    canvas.drawRRect(
      base,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    for (final x in const [222.0, 560.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 526, 18, 16),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF2A1A14),
      );
    }

    // Cream throw pillows.
    _pillow(canvas, const Offset(244, 410), -0.18);
    _pillow(canvas, const Offset(540, 412), 0.16);
  }

  void _pillow(Canvas canvas, Offset center, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final r = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-38, -30, 76, 60),
      const Radius.circular(13),
    );
    canvas.drawRRect(r, Paint()..color = const Color(0xFFF0DCB8));
    canvas.drawRRect(
      r,
      Paint()
        ..color = const Color(0xFF6B4A38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawRRect(
      r.deflate(9),
      Paint()
        ..color = const Color(0x33A87B52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  void _paintSideTable(Canvas canvas) {
    // Table top.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(622, 470, 138, 18),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFF5A3428),
    );
    // Legs.
    final leg = Paint()
      ..color = const Color(0xFF3B2119)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(638, 486), const Offset(632, 558), leg);
    canvas.drawLine(const Offset(744, 486), const Offset(752, 558), leg);
    canvas.drawLine(const Offset(660, 520), const Offset(726, 520), leg);

    // Mug.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(668, 438, 30, 32),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFFF0DCB8),
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(700, 452), radius: 10),
      -1.2,
      2.4,
      false,
      Paint()
        ..color = const Color(0xFFF0DCB8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    final steam = Paint()
      ..color = const Color(0x55FFE3C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final sway = math.sin(breath * math.pi * 2) * 3;
    canvas.drawPath(
      Path()
        ..moveTo(676, 432)
        ..quadraticBezierTo(670 + sway, 420, 678, 408),
      steam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(690, 430)
        ..quadraticBezierTo(696 - sway, 416, 688, 404),
      steam,
    );

    // Books.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(712, 458, 40, 9),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF7E5BA6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(716, 450, 36, 8),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF3E8E7E),
    );
  }

  void _paintCat(Canvas canvas) {
    final sway = math.sin(ambient * math.pi * 4) * 5;
    // Tail.
    canvas.drawPath(
      Path()
        ..moveTo(584, 548)
        ..quadraticBezierTo(626, 534 + sway, 646, 552 + sway),
      Paint()
        ..color = const Color(0xFF2B2230)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    // Body.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(542, 548), width: 88, height: 42),
      Paint()..color = const Color(0xFF332736),
    );
    // Head.
    final head = const Offset(512, 534);
    canvas.drawCircle(head, 19, Paint()..color = const Color(0xFF332736));
    // Ears.
    for (final dx in const [-11.0, 11.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(head.dx + dx - 7, head.dy - 12)
          ..lineTo(head.dx + dx, head.dy - 28)
          ..lineTo(head.dx + dx + 7, head.dy - 12)
          ..close(),
        Paint()..color = const Color(0xFF332736),
      );
    }
    // Sleeping face.
    final face = Paint()
      ..color = const Color(0xFFE8C7A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(head.dx - 6, head.dy), radius: 4),
      0.2,
      2.6,
      false,
      face,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(head.dx + 7, head.dy), radius: 4),
      0.2,
      2.6,
      false,
      face,
    );
    canvas.drawCircle(
      Offset(head.dx, head.dy + 5),
      1.8,
      Paint()..color = const Color(0xFFE8A0A8),
    );
    // Stripes.
    final stripe = Paint()
      ..color = const Color(0xFF1F1824)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final dx in const [0.0, 14.0, 28.0]) {
      canvas.drawLine(Offset(542 + dx, 536), Offset(542 + dx, 548), stripe);
    }
  }

  void _paintFigure(Canvas canvas) {
    final bob = (breath - 0.5) * 4;
    const skin = Color(0xFFF2C9A4);
    const ink = Color(0xFF3A2C26);
    const shirt = Color(0xFFE06666);
    const jeans = Color(0xFF27344D);

    // A warm halo behind the player so they read against the blue sofa.
    canvas.drawCircle(
      const Offset(396, 392),
      120,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFFFFD9A0).withAlpha(26),
                const Color(0xFFFFD9A0).withAlpha(0),
              ],
            ).createShader(
              Rect.fromCircle(center: const Offset(396, 392), radius: 120),
            ),
    );

    // Legs hang over the sofa's front. Drawn without the breathing bob so
    // the feet stay planted.
    final legPaint = Paint()
      ..color = jeans
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final spec in const [
      [374.0, 452.0, 350.0, 502.0, 366.0, 558.0],
      [418.0, 452.0, 442.0, 502.0, 426.0, 558.0],
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(spec[0], spec[1])
          ..lineTo(spec[2], spec[3])
          ..lineTo(spec[4], spec[5]),
        legPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(spec[4] + (spec[4] < 396 ? -8 : 8), spec[5] + 4),
            width: 34,
            height: 15,
          ),
          const Radius.circular(7),
        ),
        Paint()..color = const Color(0xFF241A16),
      );
    }

    canvas.save();
    canvas.translate(0, bob);

    // Torso.
    final torso = Path()
      ..moveTo(365, 384)
      ..quadraticBezierTo(396, 366, 427, 384)
      ..lineTo(435, 450)
      ..quadraticBezierTo(396, 462, 357, 450)
      ..close();
    canvas.drawPath(torso, Paint()..color = shirt);
    canvas.drawPath(
      torso,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Collar.
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(396, 381), width: 30, height: 18),
      0.15,
      math.pi - 0.3,
      false,
      Paint()
        ..color = const Color(0xFFB84C4C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Arms resting on the lap, with a mug in the right hand.
    final arm = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(369, 394)
        ..lineTo(348, 430)
        ..lineTo(360, 464),
      arm,
    );
    canvas.drawPath(
      Path()
        ..moveTo(423, 394)
        ..lineTo(444, 432)
        ..lineTo(433, 450),
      arm,
    );
    for (final hand in const [Offset(360, 465), Offset(433, 451)]) {
      canvas.drawCircle(hand, 6.5, Paint()..color = skin);
    }

    // Mug resting in the right hand.
    final mug = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(426, 438), width: 26, height: 26),
      const Radius.circular(6),
    );
    canvas.drawRRect(mug, Paint()..color = const Color(0xFFF0DCB8));
    canvas.drawRRect(
      mug,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(441, 438), radius: 7),
      -1.4,
      2.8,
      false,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(426, 427), width: 20, height: 6),
      Paint()..color = const Color(0xFF6B3A2A),
    );
    final steamSway = math.sin(breath * math.pi * 2) * 2.5;
    final steam = Paint()
      ..color = const Color(0x55FFE3C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(422, 419)
        ..quadraticBezierTo(418 + steamSway, 409, 424, 399),
      steam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(432, 417)
        ..quadraticBezierTo(436 - steamSway, 407, 430, 397),
      steam,
    );

    // Head.
    const head = Offset(396, 346);
    canvas.drawCircle(head, 25, Paint()..color = skin);
    canvas.drawCircle(
      head,
      25,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    // Hair.
    canvas.drawArc(
      Rect.fromCircle(center: head, radius: 25),
      math.pi * 1.05,
      math.pi * 0.9,
      false,
      Paint()
        ..color = const Color(0xFF4A3B32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
    // Closed, happy eyes.
    final eye = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(387, 348), radius: 4.5),
      0.15,
      math.pi - 0.3,
      false,
      eye,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(405, 348), radius: 4.5),
      0.15,
      math.pi - 0.3,
      false,
      eye,
    );
    // Smile.
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(396, 354), radius: 8),
      0.25,
      math.pi - 0.5,
      false,
      Paint()
        ..color = const Color(0xFF8C4A4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    // Blush.
    canvas.drawCircle(
      const Offset(378, 357),
      5,
      Paint()..color = const Color(0x66E88A8A),
    );
    canvas.drawCircle(
      const Offset(414, 357),
      5,
      Paint()..color = const Color(0x66E88A8A),
    );

    canvas.restore();
  }

  void _paintGlows(Canvas canvas) {
    // Lamp bloom.
    _radial(
      canvas,
      const Offset(112, 366),
      145,
      const Color(0xFFFFC978),
      (24 + 8 * math.sin(breath * math.pi)).round(),
    );
    // Window bloom.
    _radial(canvas, const Offset(165, 270), 220, const Color(0xFFFFD9A0), 18);
    // TV light from the right edge (the telly sits opposite the sofa).
    final flicker = 12 + 6 * math.sin(breath * math.pi * 2);
    _radial(
      canvas,
      const Offset(1040, 410),
      430,
      const Color(0xFF8FB6FF),
      flicker.round(),
    );
    if (celebrating) {
      _radial(canvas, const Offset(396, 380), 330, const Color(0xFFFFD27A), 46);
    }
  }

  void _radial(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    int alpha,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withAlpha(alpha), color.withAlpha(0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _paintMotes(Canvas canvas) {
    for (final mote in _motes) {
      final t = (mote.phase + ambient * mote.speed) % 1.0;
      final y = 560 - t * 510;
      final sway = math.sin((ambient * 2 + mote.phase) * math.pi * 2) * 14;
      final alpha = (math.sin(t * math.pi) * (celebrating ? 170 : 80))
          .clamp(0, 255)
          .round();
      if (alpha <= 2) continue;
      final center = Offset(mote.x + sway, y);
      if (mote.heart) {
        canvas.drawPath(
          _heartPath(center, mote.size * 1.7),
          Paint()..color = const Color(0xFFFF9BB0).withAlpha(alpha),
        );
      } else {
        canvas.drawCircle(
          center,
          mote.size * 0.6,
          Paint()..color = const Color(0xFFFFE2B0).withAlpha(alpha),
        );
      }
    }
  }

  void _paintVignette(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, _designW, _designH);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.15, -0.1),
          radius: 1.05,
          colors: [Colors.transparent, Color(0xB30B0710)],
          stops: [0.55, 1],
        ).createShader(rect),
    );
  }

  static double _quad(double a, double b, double c, double t) {
    final u = 1 - t;
    return u * u * a + 2 * u * t * b + t * t * c;
  }

  @override
  bool shouldRepaint(_CozyRoomPainter old) =>
      old.ambient != ambient ||
      old.breath != breath ||
      old.celebrating != celebrating;
}

Path _heartPath(Offset center, double size) {
  final s = size;
  return Path()
    ..moveTo(center.dx, center.dy + s * 0.68)
    ..cubicTo(
      center.dx - s * 1.15,
      center.dy - s * 0.12,
      center.dx - s * 0.55,
      center.dy - s * 0.92,
      center.dx,
      center.dy - s * 0.34,
    )
    ..cubicTo(
      center.dx + s * 0.55,
      center.dy - s * 0.92,
      center.dx + s * 1.15,
      center.dy - s * 0.12,
      center.dx,
      center.dy + s * 0.68,
    )
    ..close();
}
