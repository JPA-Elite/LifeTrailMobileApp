import 'dart:math' as math;

import 'package:flutter/material.dart' hide DayPeriod;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/state/game_state.dart';
import '../game/systems/core_systems.dart';
import '../models/game_time.dart';

/// A quiet look through the home's centre window.
///
/// The view is a layered neighbourhood skyline painted from scratch and
/// keyed to [GameTime.period]: peach morning light, bright noon, amber
/// evening, and a blue-black night with lit apartment windows.
class WindowViewScreen extends ConsumerStatefulWidget {
  const WindowViewScreen({super.key});

  @override
  ConsumerState<WindowViewScreen> createState() => _WindowViewScreenState();
}

class _WindowViewScreenState extends ConsumerState<WindowViewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final period = state.time.period;
    final weather = state.weather;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A08),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _ambient,
            builder: (context, _) => CustomPaint(
              painter: _WindowViewPainter(
                t: _ambient.value,
                period: period,
                weather: weather,
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                _topBar(state),
                const Spacer(),
                _bottomCard(state, period, weather),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(GameState state) {
    return Row(
      children: [
        Material(
          color: Colors.black.withAlpha(145),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(9, 6, 12, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: Color(0xFFFFF6E3),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Step back',
                    style: TextStyle(
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
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'OUT THE WINDOW',
                style: TextStyle(
                  color: Color(0xFFFFF6E3),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.7,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              Text(
                'Maple Street, from the second floor',
                style: TextStyle(
                  color: Color(0xFFD7C9B8),
                  fontSize: 10,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
        _Pill(
          icon: Icons.schedule_rounded,
          label: state.time.clockLabel,
          tint: const Color(0xFF9BD8FF),
        ),
        const SizedBox(width: 6),
        _Pill(
          icon: Icons.wb_twilight_rounded,
          label: state.time.periodLabel,
          tint: _periodTint(state.time.period),
        ),
        const SizedBox(width: 6),
        _Pill(
          icon: _weatherIcon(state.weather),
          label: _weatherLabel(state.weather),
          tint: const Color(0xFFB8E6CF),
        ),
      ],
    );
  }

  Widget _bottomCard(GameState state, DayPeriod period, String weather) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF17110D).withAlpha(225),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFF6E3).withAlpha(28)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _periodGradient(period),
                    ),
                  ),
                  child: Icon(
                    _periodIcon(period),
                    color: const Color(0xFFFFF6E3),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _lightLabel(state.time),
                        style: const TextStyle(
                          color: Color(0xFFFFF6E3),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _flavor(period),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCFC0AF),
                          fontSize: 9.3,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 5,
              runSpacing: 4,
              children: const [
                _PlaceChip(label: 'Maple Apartments'),
                _PlaceChip(label: 'Corner Bakery'),
                _PlaceChip(label: 'Night Owl Laundromat'),
                _PlaceChip(label: 'Rooftop garden'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _lightLabel(GameTime time) {
    if (time.period == DayPeriod.afternoon && time.hour < 15) {
      return 'Noon light';
    }
    switch (time.period) {
      case DayPeriod.morning:
        return 'Morning light';
      case DayPeriod.afternoon:
        return 'Afternoon light';
      case DayPeriod.evening:
        return 'Evening light';
      case DayPeriod.night:
        return 'Night light';
    }
  }

  static String _flavor(DayPeriod period) {
    switch (period) {
      case DayPeriod.morning:
        return 'The baker is rolling up the shutters. A bus sighs past, and '
            'someone is watering the rooftop plants.';
      case DayPeriod.afternoon:
        return 'Laundry flaps on the line. Sunlight slides across the '
            'rooftops and the whole street looks freshly painted.';
      case DayPeriod.evening:
        return 'Windows blink on one by one. A bicycle clicks home, and '
            'something wonderful is cooking two floors down.';
      case DayPeriod.night:
        return 'The city hums low. A single light burns in the laundromat, '
            'and the moon rests on the water tank.';
    }
  }

  static List<Color> _periodGradient(DayPeriod period) {
    switch (period) {
      case DayPeriod.morning:
        return const [Color(0xFFFFB56B), Color(0xFF8ED8C4)];
      case DayPeriod.afternoon:
        return const [Color(0xFF5DB7E8), Color(0xFF8FD3F4)];
      case DayPeriod.evening:
        return const [Color(0xFFB54B6B), Color(0xFFFF9E5E)];
      case DayPeriod.night:
        return const [Color(0xFF25305A), Color(0xFF6A5AA8)];
    }
  }

  static Color _periodTint(DayPeriod period) {
    switch (period) {
      case DayPeriod.morning:
        return const Color(0xFFFFCF8A);
      case DayPeriod.afternoon:
        return const Color(0xFF9BD8FF);
      case DayPeriod.evening:
        return const Color(0xFFFFB4A2);
      case DayPeriod.night:
        return const Color(0xFFB6A8FF);
    }
  }

  static IconData _periodIcon(DayPeriod period) {
    switch (period) {
      case DayPeriod.morning:
        return Icons.wb_sunny_rounded;
      case DayPeriod.afternoon:
        return Icons.light_mode_rounded;
      case DayPeriod.evening:
        return Icons.wb_twilight_rounded;
      case DayPeriod.night:
        return Icons.nightlight_round;
    }
  }

  static IconData _weatherIcon(String weather) {
    switch (weather) {
      case WeatherKind.rainy:
      case WeatherKind.storm:
        return Icons.water_drop_rounded;
      case WeatherKind.cloudy:
        return Icons.cloud_rounded;
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  static String _weatherLabel(String weather) {
    switch (weather) {
      case WeatherKind.rainy:
        return 'Rainy';
      case WeatherKind.storm:
        return 'Stormy';
      case WeatherKind.cloudy:
        return 'Cloudy';
      default:
        return 'Clear';
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.tint});

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(130),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tint, size: 13),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFFF6E3),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFD7C9B8),
          fontSize: 8.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WindowViewPainter extends CustomPainter {
  _WindowViewPainter({
    required this.t,
    required this.period,
    required this.weather,
  });

  final double t;
  final DayPeriod period;
  final String weather;

  bool get _night => period == DayPeriod.night;
  bool get _evening => period == DayPeriod.evening;
  bool get _storm => weather == WeatherKind.storm;
  bool get _rainy => weather == WeatherKind.rainy || _storm;
  bool get _cloudy => weather == WeatherKind.cloudy || _rainy;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _room(canvas, size);

    final window = Rect.fromLTWH(w * 0.075, h * 0.095, w * 0.85, h * 0.78);
    final glass = window.deflate(24);

    // Casing shadow.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        window.shift(const Offset(8, 10)).inflate(8),
        const Radius.circular(22),
      ),
      Paint()..color = Colors.black.withAlpha(100),
    );
    // Wooden frame.
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(18)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7A4B2D), Color(0xFF3A2114)],
        ).createShader(window),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(window.deflate(5), const Radius.circular(14)),
      Paint()..color = const Color(0xFF25160E),
    );

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(glass, const Radius.circular(8)));
    _outside(canvas, glass, size);
    _glass(canvas, glass);
    canvas.restore();

    // Mullions.
    final bar = Paint()..color = const Color(0xFF6A4529);
    final barHi = Paint()
      ..color = const Color(0xFFB78352)
      ..strokeWidth = 1.5;
    canvas.drawRect(
      Rect.fromLTWH(glass.center.dx - 4, glass.top, 8, glass.height),
      bar,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        glass.left,
        glass.top + glass.height * 0.56,
        glass.width,
        7,
      ),
      bar,
    );
    canvas.drawLine(
      Offset(glass.center.dx - 1, glass.top),
      Offset(glass.center.dx - 1, glass.bottom),
      barHi,
    );
    canvas.drawLine(
      Offset(glass.left, glass.top + glass.height * 0.56 + 2),
      Offset(glass.right, glass.top + glass.height * 0.56 + 2),
      barHi,
    );
    // Brass latch.
    canvas.drawCircle(
      Offset(glass.center.dx, glass.top + glass.height * 0.56 + 4),
      4,
      Paint()..color = const Color(0xFFD9B75C),
    );
    canvas.drawCircle(
      Offset(glass.center.dx, glass.top + glass.height * 0.56 + 4),
      1.5,
      Paint()..color = const Color(0xFF7A5A1E),
    );

    _curtains(canvas, window);
    _sill(canvas, size, window);
  }

  void _room(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bg = Offset.zero & size;
    canvas.drawRect(
      bg,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _night
              ? const [Color(0xFF120E14), Color(0xFF1B1419), Color(0xFF0A0708)]
              : _evening
              ? const [Color(0xFF2A1B20), Color(0xFF3E241D), Color(0xFF150D09)]
              : const [Color(0xFF3A2A23), Color(0xFF4D392D), Color(0xFF1A110D)],
          stops: const [0, 0.7, 1],
        ).createShader(bg),
    );
    // Wallpaper lines.
    for (var x = 0.0; x < w; x += 46) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, h),
        Paint()..color = Colors.white.withAlpha(4),
      );
    }
    // Soft light pooling on the wall.
    final glow = Offset(w * 0.5, h * 0.36);
    canvas.drawCircle(
      glow,
      h * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            (_night ? const Color(0xFF7F8FC9) : const Color(0xFFFFD9A0))
                .withAlpha(_night ? 12 : 18),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: glow, radius: h * 0.55)),
    );
  }

  void _outside(Canvas canvas, Rect r, Size size) {
    final skyColors = _storm
        ? (_night
              ? const [Color(0xFF05070F), Color(0xFF111827), Color(0xFF1D2637)]
              : const [Color(0xFF3B4A5A), Color(0xFF53657A), Color(0xFF76879A)])
        : _night
        ? const [Color(0xFF050A20), Color(0xFF101C42), Color(0xFF26345C)]
        : _evening
        ? const [Color(0xFF3B2352), Color(0xFFB4536B), Color(0xFFFFB56B)]
        : period == DayPeriod.afternoon
        ? const [Color(0xFF3E9ED0), Color(0xFF8FD3F4), Color(0xFFE8F6FB)]
        : const [Color(0xFF7EC8E3), Color(0xFFBDE6F5), Color(0xFFFFEBC7)];

    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: skyColors,
          stops: const [0, 0.58, 1],
        ).createShader(r),
    );

    _sunAndMoon(canvas, r);
    if (_night) _stars(canvas, r);
    _clouds(canvas, r);
    _skyline(canvas, r);
    _street(canvas, r);
    if (_rainy) _rain(canvas, r);
    if (!_night && !_rainy) _birds(canvas, r);
  }

  void _sunAndMoon(Canvas canvas, Rect r) {
    if (_night) {
      final moon = Offset(r.left + r.width * 0.72, r.top + r.height * 0.2);
      final mr = r.height * 0.075;
      canvas.drawCircle(
        moon,
        mr * 1.9,
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0xFFDCE6FF).withAlpha(30), Colors.transparent],
          ).createShader(Rect.fromCircle(center: moon, radius: mr * 1.9)),
      );
      canvas.drawCircle(moon, mr, Paint()..color = const Color(0xFFF2F1DD));
      canvas.drawCircle(
        moon + Offset(mr * 0.38, -mr * 0.18),
        mr * 0.92,
        Paint()..color = const Color(0xFF0B1230),
      );
      return;
    }
    final sun = _evening
        ? Offset(r.left + r.width * 0.78, r.top + r.height * 0.62)
        : Offset(
            r.left + r.width * (period == DayPeriod.morning ? 0.22 : 0.76),
            r.top + r.height * (period == DayPeriod.morning ? 0.44 : 0.19),
          );
    final sr = r.height * (_evening ? 0.11 : 0.075);
    canvas.drawCircle(
      sun,
      sr * 2.4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE7A3).withAlpha(_evening ? 65 : 45),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: sr * 2.4)),
    );
    canvas.drawCircle(
      sun,
      sr,
      Paint()
        ..color = _evening ? const Color(0xFFFFB347) : const Color(0xFFFFE08A),
    );
    // A few soft rays.
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + t * 0.06;
      canvas.drawLine(
        sun + Offset(math.cos(a), math.sin(a)) * (sr * 1.25),
        sun + Offset(math.cos(a), math.sin(a)) * (sr * 1.7),
        Paint()
          ..color = const Color(0xFFFFF3C4).withAlpha(45)
          ..strokeWidth = 2,
      );
    }
  }

  void _stars(Canvas canvas, Rect r) {
    for (var i = 0; i < 44; i++) {
      final x = r.left + ((i * 97) % 1000) / 1000 * r.width;
      final y = r.top + ((i * 53) % 1000) / 1000 * r.height * 0.6;
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * math.pi * 2 + i));
      canvas.drawCircle(
        Offset(x, y),
        i % 5 == 0 ? 1.5 : 0.9,
        Paint()..color = Colors.white.withAlpha((180 * twinkle).round()),
      );
    }
  }

  void _clouds(Canvas canvas, Rect r) {
    final count = _cloudy ? 8 : 4;
    for (var i = 0; i < count; i++) {
      final drift = (t * (8 + i * 1.3) + i * 173) % (r.width + 260) - 130;
      final cx = r.left + drift;
      final cy = r.top + r.height * (0.1 + (i % 4) * 0.1);
      final s = 0.8 + (i % 3) * 0.25;
      final color = _storm
          ? const Color(0xFF9AA7B5)
          : _night
          ? const Color(0xFF59658F)
          : Colors.white;
      final paint = Paint()..color = color.withAlpha(_night ? 45 : 195);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 80 * s, height: 24 * s),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - 24 * s, cy - 9 * s),
          width: 44 * s,
          height: 30 * s,
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + 22 * s, cy - 11 * s),
          width: 42 * s,
          height: 28 * s,
        ),
        paint,
      );
    }
  }

  void _skyline(Canvas canvas, Rect r) {
    final ground = r.top + r.height * 0.75;
    // Far haze layer.
    final far = Paint()
      ..color = _night
          ? const Color(0xFF1B2547).withAlpha(220)
          : _evening
          ? const Color(0xFF6B3B5A).withAlpha(190)
          : const Color(0xFF6B8FA5).withAlpha(170);
    for (var i = 0; i < 12; i++) {
      final bw = r.width * (0.05 + (i % 4) * 0.018);
      final bh = r.height * (0.12 + (i % 5) * 0.05);
      final x = r.left + i * r.width * 0.085;
      canvas.drawRect(Rect.fromLTWH(x, ground - bh, bw, bh), far);
    }

    // Mid buildings.
    final midColors = _night
        ? const [Color(0xFF141B31), Color(0xFF1C253D), Color(0xFF202A44)]
        : _evening
        ? const [Color(0xFF4A2C3A), Color(0xFF5C3440), Color(0xFF3C2732)]
        : const [Color(0xFF8A6B5B), Color(0xFFA17C63), Color(0xFF78695D)];
    final buildings = [
      _BuildingSpec(x: 0.02, w: 0.19, h: 0.38, color: 0, roof: 0),
      _BuildingSpec(x: 0.22, w: 0.15, h: 0.29, color: 1, roof: 1),
      _BuildingSpec(x: 0.39, w: 0.2, h: 0.45, color: 2, roof: 0),
      _BuildingSpec(x: 0.6, w: 0.17, h: 0.33, color: 1, roof: 2),
      _BuildingSpec(x: 0.78, w: 0.2, h: 0.41, color: 0, roof: 0),
    ];
    for (var b = 0; b < buildings.length; b++) {
      final spec = buildings[b];
      final rect = Rect.fromLTWH(
        r.left + r.width * spec.x,
        ground - r.height * spec.h,
        r.width * spec.w,
        r.height * spec.h,
      );
      canvas.drawRect(rect, Paint()..color = midColors[spec.color]);
      // Roof line.
      canvas.drawRect(
        Rect.fromLTWH(rect.left - 2, rect.top, rect.width + 4, 5),
        Paint()..color = Colors.black.withAlpha(45),
      );
      switch (spec.roof) {
        case 1:
          // Water tank.
          final tank = Rect.fromLTWH(
            rect.center.dx - 14,
            rect.top - 26,
            28,
            20,
          );
          canvas.drawRect(tank, Paint()..color = const Color(0xFF4A3B31));
          canvas.drawRect(
            Rect.fromLTWH(tank.left, tank.bottom, 3, 8),
            Paint()..color = const Color(0xFF2A1C15),
          );
          canvas.drawRect(
            Rect.fromLTWH(tank.right - 3, tank.bottom, 3, 8),
            Paint()..color = const Color(0xFF2A1C15),
          );
          break;
        case 2:
          // Antenna.
          canvas.drawLine(
            Offset(rect.center.dx, rect.top),
            Offset(rect.center.dx, rect.top - 30),
            Paint()
              ..color = const Color(0xFF2A1C15)
              ..strokeWidth = 2,
          );
          canvas.drawLine(
            Offset(rect.center.dx - 9, rect.top - 22),
            Offset(rect.center.dx + 9, rect.top - 22),
            Paint()
              ..color = const Color(0xFF2A1C15)
              ..strokeWidth = 1.5,
          );
          break;
      }
      // Windows.
      final cols = 3 + b % 2;
      final rows = 4;
      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < cols; col++) {
          final wx = rect.left + rect.width * (0.14 + col * (0.72 / cols));
          final wy = rect.top + rect.height * (0.12 + row * 0.2);
          final ww = rect.width * 0.12;
          final wh = rect.height * 0.1;
          final lit = _night || _evening
              ? ((b * 7 + row * 3 + col) % 5 != 0)
              : false;
          canvas.drawRect(
            Rect.fromLTWH(wx, wy, ww, wh),
            Paint()
              ..color = lit
                  ? const Color(0xFFFFD166).withAlpha(
                      150 +
                          (20 *
                                  (0.5 +
                                      0.5 *
                                          math.sin(
                                            t * math.pi * 2 + b + row + col,
                                          )))
                              .round(),
                    )
                  : const Color(0xFF18202E).withAlpha(120),
          );
        }
      }
    }

    // Fire escape on the tallest building.
    final fire = Rect.fromLTWH(
      r.left + r.width * 0.46,
      ground - r.height * 0.34,
      r.width * 0.05,
      r.height * 0.28,
    );
    final rail = Paint()
      ..color = const Color(0xFF1D242C).withAlpha(180)
      ..strokeWidth = 1.4;
    for (var i = 0; i < 4; i++) {
      final y = fire.top + i * fire.height / 3;
      canvas.drawLine(Offset(fire.left, y), Offset(fire.right, y), rail);
    }
    canvas.drawLine(fire.topLeft, fire.bottomLeft, rail);
    canvas.drawLine(fire.topRight, fire.bottomRight, rail);

    // Building signs.
    _sign(
      canvas,
      r,
      Rect.fromLTWH(
        r.left + r.width * 0.045,
        ground - r.height * 0.25,
        r.width * 0.13,
        r.height * 0.06,
      ),
      'MAPLE',
    );
    _sign(
      canvas,
      r,
      Rect.fromLTWH(
        r.left + r.width * 0.63,
        ground - r.height * 0.19,
        r.width * 0.12,
        r.height * 0.055,
      ),
      'BAKERY',
    );
    _sign(
      canvas,
      r,
      Rect.fromLTWH(
        r.left + r.width * 0.81,
        ground - r.height * 0.27,
        r.width * 0.14,
        r.height * 0.055,
      ),
      'LAUNDRY',
    );

    // Trees between buildings.
    for (var i = 0; i < 3; i++) {
      final tx = r.left + r.width * (0.34 + i * 0.22);
      final ty = ground + 2;
      _tree(canvas, Offset(tx, ty), 0.7 + i * 0.15);
    }
  }

  void _sign(Canvas canvas, Rect r, Rect rect, String text) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF1B1714).withAlpha(210),
    );
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: _night
              ? const Color(0xFFFFD166)
              : const Color(0xFFFFF3D6).withAlpha(210),
          fontSize: rect.height * 0.42,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 6);
    painter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - painter.width) / 2,
        rect.top + (rect.height - painter.height) / 2,
      ),
    );
  }

  void _tree(Canvas canvas, Offset base, double s) {
    final trunk = Paint()
      ..color = const Color(0xFF3A2A1D)
      ..strokeWidth = 3 * s;
    canvas.drawLine(base, base - Offset(0, 34 * s), trunk);
    final leaf = Paint()
      ..color = _night ? const Color(0xFF1F3A2A) : const Color(0xFF4E7D51);
    canvas.drawCircle(base - Offset(0, 40 * s), 15 * s, leaf);
    canvas.drawCircle(base - Offset(10 * s, 33 * s), 11 * s, leaf);
    canvas.drawCircle(base + Offset(11 * s, 34 * s), 12 * s, leaf);
  }

  void _street(Canvas canvas, Rect r) {
    final ground = r.top + r.height * 0.75;
    canvas.drawRect(
      Rect.fromLTWH(r.left, ground, r.width, r.height * 0.25),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _night
              ? const [Color(0xFF121622), Color(0xFF080A10)]
              : const [Color(0xFF5B5D5C), Color(0xFF353633)],
        ).createShader(Rect.fromLTWH(r.left, ground, r.width, r.height * 0.25)),
    );
    // Sidewalk.
    canvas.drawRect(
      Rect.fromLTWH(r.left, ground, r.width, r.height * 0.055),
      Paint()
        ..color = _night
            ? const Color(0xFF242A38)
            : const Color(0xFFB0A896).withAlpha(190),
    );
    // Crosswalk.
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          r.left + r.width * (0.08 + i * 0.09),
          ground + r.height * 0.1,
          r.width * 0.045,
          r.height * 0.08,
        ),
        Paint()..color = Colors.white.withAlpha(_night ? 35 : 80),
      );
    }
    // Street lamps.
    for (final x in [0.16, 0.48, 0.78]) {
      final base = Offset(r.left + r.width * x, ground + r.height * 0.04);
      canvas.drawLine(
        base,
        base - Offset(0, r.height * 0.2),
        Paint()
          ..color = const Color(0xFF2B2B2B)
          ..strokeWidth = 3,
      );
      final lamp = base - Offset(0, r.height * 0.2);
      final glow = _night || _evening;
      if (glow) {
        canvas.drawCircle(
          lamp,
          r.height * 0.055,
          Paint()
            ..shader =
                RadialGradient(
                  colors: [
                    const Color(0xFFFFD166).withAlpha(55),
                    Colors.transparent,
                  ],
                ).createShader(
                  Rect.fromCircle(center: lamp, radius: r.height * 0.055),
                ),
        );
      }
      canvas.drawCircle(
        lamp,
        4,
        Paint()
          ..color = glow ? const Color(0xFFFFE7A3) : const Color(0xFF8C8C8C),
      );
    }
    // A little parked car.
    final carRect = Rect.fromLTWH(
      r.left + r.width * 0.24,
      ground + r.height * 0.1,
      r.width * 0.17,
      r.height * 0.08,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(carRect, Radius.circular(r.height * 0.025)),
      Paint()
        ..color = _night ? const Color(0xFF2C3A4A) : const Color(0xFF3D6E7A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          carRect.left + carRect.width * 0.18,
          carRect.top - carRect.height * 0.38,
          carRect.width * 0.55,
          carRect.height * 0.5,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF26313C),
    );
    canvas.drawCircle(
      Offset(carRect.left + carRect.width * 0.22, carRect.bottom),
      5,
      Paint()..color = const Color(0xFF0A0A0A),
    );
    canvas.drawCircle(
      Offset(carRect.right - carRect.width * 0.22, carRect.bottom),
      5,
      Paint()..color = const Color(0xFF0A0A0A),
    );
    if (_night || _evening) {
      canvas.drawCircle(
        Offset(carRect.right - 2, carRect.top + carRect.height * 0.45),
        3,
        Paint()..color = const Color(0xFFFFE7A3),
      );
    }
  }

  void _rain(Canvas canvas, Rect r) {
    final paint = Paint()
      ..color = const Color(0xFFB7D7FF).withAlpha(_storm ? 90 : 55)
      ..strokeWidth = 1.1;
    for (var i = 0; i < 80; i++) {
      final x = r.left + ((i * 83 + t * 180) % r.width);
      final y = r.top + ((i * 47 + t * 520) % r.height);
      canvas.drawLine(Offset(x, y), Offset(x - 4, y + 15), paint);
    }
  }

  void _birds(Canvas canvas, Rect r) {
    final paint = Paint()
      ..color = const Color(0xFF2A2A2A).withAlpha(130)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      final x = r.left + ((i * 137 + t * 60) % r.width);
      final y = r.top + r.height * (0.14 + (i % 3) * 0.06);
      final flap = math.sin(t * math.pi * 8 + i) * 3;
      canvas.drawLine(Offset(x - 5, y), Offset(x, y - 3 - flap), paint);
      canvas.drawLine(Offset(x, y - 3 - flap), Offset(x + 5, y), paint);
    }
  }

  void _glass(Canvas canvas, Rect r) {
    // Diagonal reflection bands.
    final refl = Paint()..color = Colors.white.withAlpha(12);
    canvas.drawPath(
      Path()
        ..moveTo(r.left + r.width * 0.08, r.top)
        ..lineTo(r.left + r.width * 0.24, r.top)
        ..lineTo(r.left + r.width * 0.06, r.bottom)
        ..lineTo(r.left - r.width * 0.1, r.bottom)
        ..close(),
      refl,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r.left + r.width * 0.36, r.top)
        ..lineTo(r.left + r.width * 0.43, r.top)
        ..lineTo(r.left + r.width * 0.25, r.bottom)
        ..lineTo(r.left + r.width * 0.18, r.bottom)
        ..close(),
      Paint()..color = Colors.white.withAlpha(7),
    );
    // Slight blue tint at the bottom of the glass.
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            (_night ? const Color(0xFF7F8FC9) : const Color(0xFFD6EEFB))
                .withAlpha(18),
          ],
          stops: const [0.55, 1],
        ).createShader(r),
    );
  }

  void _curtains(Canvas canvas, Rect window) {
    final fabric = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _night
            ? const [Color(0xFF3A1F2E), Color(0xFF251322)]
            : _evening
            ? const [Color(0xFF7A3B45), Color(0xFF4A2028)]
            : const [Color(0xFFB66A5E), Color(0xFF7A3B35)],
      ).createShader(window);
    final left = Path()
      ..moveTo(window.left - 8, window.top - 10)
      ..lineTo(window.left + window.width * 0.14, window.top - 10)
      ..quadraticBezierTo(
        window.left + window.width * 0.08,
        window.top + window.height * 0.45,
        window.left + window.width * 0.13,
        window.bottom + 12,
      )
      ..lineTo(window.left - 18, window.bottom + 12)
      ..close();
    canvas.drawPath(left, fabric);
    final right = Path()
      ..moveTo(window.right + 8, window.top - 10)
      ..lineTo(window.right - window.width * 0.14, window.top - 10)
      ..quadraticBezierTo(
        window.right - window.width * 0.08,
        window.top + window.height * 0.45,
        window.right - window.width * 0.13,
        window.bottom + 12,
      )
      ..lineTo(window.right + 18, window.bottom + 12)
      ..close();
    canvas.drawPath(right, fabric);
    // Curtain folds.
    final fold = Paint()
      ..color = Colors.black.withAlpha(35)
      ..strokeWidth = 2;
    for (var i = 0; i < 3; i++) {
      final lx = window.left + window.width * (0.03 + i * 0.035);
      canvas.drawLine(
        Offset(lx, window.top),
        Offset(lx - 5, window.bottom),
        fold,
      );
      final rx = window.right - window.width * (0.03 + i * 0.035);
      canvas.drawLine(
        Offset(rx, window.top),
        Offset(rx + 5, window.bottom),
        fold,
      );
    }
    // Rod.
    canvas.drawRect(
      Rect.fromLTWH(window.left - 22, window.top - 18, window.width + 44, 7),
      Paint()..color = const Color(0xFF4A2E1A),
    );
    canvas.drawCircle(
      Offset(window.left - 24, window.top - 14),
      5,
      Paint()..color = const Color(0xFFD9B75C),
    );
    canvas.drawCircle(
      Offset(window.right + 24, window.top - 14),
      5,
      Paint()..color = const Color(0xFFD9B75C),
    );
  }

  void _sill(Canvas canvas, Size size, Rect window) {
    final sill = Rect.fromLTWH(
      window.left - 18,
      window.bottom - 4,
      window.width + 36,
      20,
    );
    canvas.drawRect(
      sill.shift(const Offset(0, 8)),
      Paint()..color = Colors.black.withAlpha(80),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sill, const Radius.circular(5)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB78352), Color(0xFF6A4529)],
        ).createShader(sill),
    );
    // Small mug on the sill.
    final mug = Offset(window.left + window.width * 0.12, window.bottom - 7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: mug, width: 16, height: 14),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFE8D1AE),
    );
    canvas.drawCircle(
      mug + const Offset(9, 0),
      4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFE8D1AE),
    );
    // Tiny plant.
    final pot = Offset(window.right - window.width * 0.12, window.bottom - 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pot, width: 16, height: 13),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFB7793E),
    );
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + (i - 1.5) * 0.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: pot + Offset(math.cos(a) * 8, -8 + math.sin(a) * 7),
          width: 10,
          height: 5,
        ),
        Paint()..color = const Color(0xFF4E7D51),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WindowViewPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.period != period ||
      oldDelegate.weather != weather;
}

class _BuildingSpec {
  const _BuildingSpec({
    required this.x,
    required this.w,
    required this.h,
    required this.color,
    required this.roof,
  });

  final double x;
  final double w;
  final double h;
  final int color;
  final int roof;
}
