import 'dart:math' as math;

import 'package:flutter/material.dart' hide DayPeriod;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/state/game_state.dart';
import '../models/cooking.dart';
import '../models/game_time.dart';

/// Returned when the player leaves the dining table.
class DiningResult {
  const DiningResult({
    this.openKitchen = false,
    this.ateTitle,
    this.energyGained = 0,
  });

  final bool openKitchen;
  final String? ateTitle;
  final int energyGained;
}

/// The dining table. Meals cooked in the kitchen appear here as plated
/// dishes; sitting down runs a timed eating scene, then restores energy and
/// clears the plate.
class DiningTableScreen extends ConsumerStatefulWidget {
  const DiningTableScreen({super.key});

  @override
  ConsumerState<DiningTableScreen> createState() => _DiningTableScreenState();
}

class _DiningTableScreenState extends ConsumerState<DiningTableScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _eat;

  String? _selectedMealId;
  CookedMeal? _lastAte;
  CookedMeal? _eatingMeal;
  String? _notice;
  bool _eating = false;
  int _gained = 0;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _eat = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _ambient.dispose();
    _eat.dispose();
    super.dispose();
  }

  int _eatDurationMs(int minutes) =>
      (1000 + minutes * 42).clamp(1800, 5000).toInt();

  Future<void> _startEating(CookedMeal meal) async {
    if (_eating) return;
    final state = ref.read(gameStateProvider);
    if (state.itemCount(meal.mealId) <= 0) {
      HapticFeedback.heavyImpact();
      setState(() {
        _notice = 'That plate has already been cleared.';
        _selectedMealId = null;
      });
      return;
    }

    _eat.duration = Duration(milliseconds: _eatDurationMs(meal.minutes));
    HapticFeedback.mediumImpact();
    setState(() {
      _eating = true;
      _eatingMeal = meal;
      _notice = null;
      _selectedMealId = null;
      _gained = 0;
    });

    await _eat.forward(from: 0);
    if (!mounted) return;

    final before = state.player.energy;
    final success = state.eatCookedMeal(meal.mealId);
    if (!mounted) return;
    final gained = success ? state.player.energy - before : 0;
    setState(() {
      _eating = false;
      _eatingMeal = null;
      if (success) {
        _lastAte = meal;
        _gained = gained;
        _notice = null;
      } else {
        _notice = 'The plate disappeared before the last bite.';
      }
    });
    _eat.reset();
    HapticFeedback.lightImpact();
  }

  void _close() {
    if (_eating) return;
    Navigator.of(
      context,
    ).pop(DiningResult(ateTitle: _lastAte?.name, energyGained: _gained));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final period = state.time.period;
    final meals = state.cookedMeals;
    final selected = _selectedMeal(meals);
    final shownMeal = _eatingMeal ?? selected;

    return PopScope(
      canPop: !_eating,
      child: Scaffold(
        backgroundColor: const Color(0xFF140F0B),
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) => CustomPaint(
                painter: _DiningRoomPainter(
                  t: _ambient.value,
                  period: period,
                  meal: shownMeal,
                  eating: _eating,
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFB7793E), Color(0xFF5A2E16)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.table_restaurant_rounded,
                          color: Color(0xFFFFF4DF),
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'THE DINING TABLE',
                              style: TextStyle(
                                color: Color(0xFFFFF4DF),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                            Text(
                              _periodFlavor(period),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFD8C8B5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Pill(
                        icon: Icons.bolt_rounded,
                        label: '${state.player.energy} energy',
                        tint: const Color(0xFFFFD166),
                      ),
                      const SizedBox(width: 6),
                      _Pill(
                        icon: Icons.schedule_rounded,
                        label: state.time.clockLabel,
                        tint: const Color(0xFF9BD8FF),
                      ),
                      const SizedBox(width: 6),
                      _Pill(
                        icon: Icons.wb_twilight_rounded,
                        label: state.time.periodLabel,
                        tint: const Color(0xFFFFB4A2),
                      ),
                      const SizedBox(width: 6),
                      _RoundButton(
                        icon: Icons.close_rounded,
                        label: 'Leave the table',
                        onTap: _close,
                      ),
                    ],
                  ),
                  if (_notice != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _Notice(text: _notice!),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 348,
                        child: _tablePanel(meals, selected),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_eating && _eatingMeal != null)
              Positioned.fill(
                child: _EatingOverlay(
                  meal: _eatingMeal!,
                  progress: _eat,
                  ambient: _ambient,
                ),
              ),
          ],
        ),
      ),
    );
  }

  CookedMeal? _selectedMeal(List<CookedMeal> meals) {
    if (meals.isEmpty) return null;
    if (_selectedMealId != null) {
      for (final meal in meals) {
        if (meal.mealId == _selectedMealId) return meal;
      }
    }
    return meals.first;
  }

  Widget _tablePanel(List<CookedMeal> meals, CookedMeal? selected) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF211811).withAlpha(232),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8B5E3C).withAlpha(130)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_rounded,
                size: 15,
                color: Color(0xFFFFC857),
              ),
              const SizedBox(width: 5),
              const Text(
                'ON THE TABLE',
                style: TextStyle(
                  color: Color(0xFFFFF4DF),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Text(
                meals.isEmpty
                    ? 'empty'
                    : '${meals.length} ${meals.length == 1 ? 'plate' : 'plates'}',
                style: const TextStyle(color: Color(0xFFC4B39F), fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_lastAte != null && !_eating)
            _AteBanner(
              meal: _lastAte!,
              gained: _gained,
              onKitchen: () => Navigator.of(
                context,
              ).pop(const DiningResult(openKitchen: true)),
            ),
          if (meals.isEmpty)
            Expanded(
              child: _EmptyTable(
                onKitchen: () => Navigator.of(
                  context,
                ).pop(const DiningResult(openKitchen: true)),
              ),
            )
          else ...[
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                itemCount: meals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final meal = meals[index];
                  return _MealOption(
                    meal: meal,
                    selected: selected?.mealId == meal.mealId,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMealId = meal.mealId);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 36,
              child: FilledButton.icon(
                onPressed: selected == null || _eating
                    ? null
                    : () => _startEating(selected),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      selected?.accentDeep ?? const Color(0xFF6B4A2A),
                  foregroundColor: const Color(0xFFFFF4DF),
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.chair_alt_rounded, size: 15),
                label: Text(
                  selected == null
                      ? 'Nothing selected'
                      : 'Sit down & eat  ·  +${selected.energy} energy',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Eating takes ${selected?.minutes ?? 30} in-game minutes. '
              'The remaining plates stay on the table.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFAE9C85), fontSize: 8),
            ),
          ],
        ],
      ),
    );
  }

  String _periodFlavor(DayPeriod period) {
    switch (period) {
      case DayPeriod.morning:
        return 'Morning light, warm toast, and the kettle ticking.';
      case DayPeriod.afternoon:
        return 'The table is bright with midday sun.';
      case DayPeriod.evening:
        return 'The candle is lit. Dinner smells like home.';
      case DayPeriod.night:
        return 'A quiet late meal under the pendant light.';
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
        color: Colors.black.withAlpha(110),
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
              color: Color(0xFFFFF4DF),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
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
        color: Colors.black.withAlpha(120),
        shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: const Color(0xFFFFF4DF)),
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
        color: const Color(0xFF52231E).withAlpha(225),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFF9A8A).withAlpha(100)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}

class _EmptyTable extends StatelessWidget {
  const _EmptyTable({required this.onKitchen});

  final VoidCallback onKitchen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3A2B1E).withAlpha(180),
                border: Border.all(
                  color: const Color(0xFF8B5E3C).withAlpha(120),
                ),
              ),
              child: const Center(
                child: Text('🍽️', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nothing plated yet.',
              style: TextStyle(
                color: Color(0xFFFFF4DF),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Cook a family recipe or build a custom plate in the kitchen. '
              'Whatever comes off the stove appears here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFC4B39F),
                fontSize: 9.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onKitchen,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB7793E),
                foregroundColor: const Color(0xFFFFF4DF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.soup_kitchen_rounded, size: 14),
              label: const Text(
                'Go to the kitchen',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealOption extends StatelessWidget {
  const _MealOption({
    required this.meal,
    required this.selected,
    required this.onTap,
  });

  final CookedMeal meal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            color: selected
                ? meal.accentDeep.withAlpha(115)
                : const Color(0xFF2B2118).withAlpha(190),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected
                  ? meal.accent.withAlpha(180)
                  : Colors.white.withAlpha(12),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(meal.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            meal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFFF4DF),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (meal.isCustom) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: meal.accent.withAlpha(32),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: meal.accent.withAlpha(90),
                              ),
                            ),
                            child: Text(
                              'CUSTOM',
                              style: TextStyle(
                                color: meal.accent,
                                fontSize: 6.8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${meal.subtitle}  ·  +${meal.energy} energy  ·  '
                      '${meal.minutes}m',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC8B8A5),
                        fontSize: 8.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 16, color: meal.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _AteBanner extends StatelessWidget {
  const _AteBanner({
    required this.meal,
    required this.gained,
    required this.onKitchen,
  });

  final CookedMeal meal;
  final int gained;
  final VoidCallback onKitchen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.fromLTRB(8, 5, 4, 5),
      decoration: BoxDecoration(
        color: const Color(0xFF315C3B).withAlpha(130),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF7FC8A9).withAlpha(100)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: Color(0xFF9ED9BD),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              '${meal.name} eaten  ·  +$gained energy  ·  ${meal.minutes} min',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFD8F3E5),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onKitchen,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB8E6CF),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              minimumSize: const Size(0, 24),
            ),
            child: const Text('Cook more', style: TextStyle(fontSize: 8.5)),
          ),
        ],
      ),
    );
  }
}

class _EatingOverlay extends StatelessWidget {
  const _EatingOverlay({
    required this.meal,
    required this.progress,
    required this.ambient,
  });

  final CookedMeal meal;
  final Animation<double> progress;
  final Animation<double> ambient;

  String _stage(double value) {
    if (value < 0.14) return 'Sitting down and unfolding the napkin…';
    if (value < 0.34) return 'The first warm bite.';
    if (value < 0.64) return 'Savour the middle of the plate…';
    if (value < 0.9) return 'Sopping up the last little bit.';
    return 'Finished. Push the plate back.';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0D0906).withAlpha(244),
      child: SafeArea(
        minimum: const EdgeInsets.all(18),
        child: AnimatedBuilder(
          animation: Listenable.merge([progress, ambient]),
          builder: (context, _) {
            final value = progress.value;
            final minutesLeft = math.max(
              0,
              (meal.minutes * (1 - value)).ceil(),
            );
            final sceneHeight = (MediaQuery.sizeOf(context).height * 0.36)
                .clamp(130.0, 210.0);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: sceneHeight,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _MealPlatePainter(
                            t: ambient.value,
                            progress: value,
                            meal: meal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Eating ${meal.name}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFF4DF),
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _stage(value),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFD8C8B5),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          _OverlayChip(
                            icon: Icons.timer_outlined,
                            label: '$minutesLeft min left',
                            tint: const Color(0xFFFFA36C),
                          ),
                          _OverlayChip(
                            icon: Icons.restaurant_rounded,
                            label: '${meal.minutes}-minute meal',
                            tint: const Color(0xFFFFD166),
                          ),
                          _OverlayChip(
                            icon: Icons.bolt_rounded,
                            label: '+${meal.energy} energy at the end',
                            tint: const Color(0xFF9ED9BD),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meal.ingredientSummary,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFBCA98F),
                          fontSize: 9.5,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation(meal.accent),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Take your time. The house can wait.',
                        style: const TextStyle(
                          color: Color(0xFFAE9C85),
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withAlpha(75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tint),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: tint,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Close-up of the plate while it is being eaten. The food shrinks bite by
/// bite, the fork travels in and out, and steam fades as the plate empties.
class _MealPlatePainter extends CustomPainter {
  _MealPlatePainter({
    required this.t,
    required this.progress,
    required this.meal,
  });

  final double t;
  final double progress;
  final CookedMeal meal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Warm room glow.
    final glow = Offset(w / 2, h * 0.4);
    canvas.drawCircle(
      glow,
      h * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFC857).withAlpha(24), Colors.transparent],
        ).createShader(Rect.fromCircle(center: glow, radius: h * 0.55)),
    );

    // Table and placemat.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.58, w * 0.88, h * 0.36),
        const Radius.circular(16),
      ),
      Paint()..color = const Color(0xFF3A2417),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.77),
          width: w * 0.58,
          height: h * 0.34,
        ),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF6B2E2E).withAlpha(205),
    );

    // Plate.
    final plateCenter = Offset(w * 0.5, h * 0.72);
    canvas.drawOval(
      Rect.fromCenter(
        center: plateCenter + Offset(0, 6),
        width: w * 0.42,
        height: h * 0.24,
      ),
      Paint()..color = Colors.black.withAlpha(70),
    );
    canvas.drawOval(
      Rect.fromCenter(center: plateCenter, width: w * 0.42, height: h * 0.24),
      Paint()..color = const Color(0xFFF2E4C9),
    );
    canvas.drawOval(
      Rect.fromCenter(center: plateCenter, width: w * 0.33, height: h * 0.18),
      Paint()..color = const Color(0xFFE3D0AE),
    );

    // Food shrinks with every bite.
    final left = (1 - progress * 0.92).clamp(0.04, 1.0);
    if (left > 0.08) {
      final foodWidth = w * 0.25 * left;
      final foodHeight = h * 0.11 * left;
      final foodCenter = plateCenter + Offset(0, -h * 0.01);
      canvas.drawOval(
        Rect.fromCenter(
          center: foodCenter,
          width: foodWidth,
          height: foodHeight,
        ),
        Paint()..color = meal.accentDeep,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: foodCenter + Offset(0, -h * 0.008),
          width: foodWidth * 0.84,
          height: foodHeight * 0.68,
        ),
        Paint()..color = meal.accent,
      );
      var i = 0;
      for (final entry in meal.ingredients.entries) {
        final ingredient = PantryCatalog.byId(entry.key);
        if (ingredient == null) continue;
        final a = i * math.pi * 0.7 + 0.4;
        canvas.drawCircle(
          foodCenter +
              Offset(
                math.cos(a) * foodWidth * 0.24,
                math.sin(a) * foodHeight * 0.2,
              ),
          2.4 + (i % 2),
          Paint()..color = ingredient.color,
        );
        i++;
      }
    } else {
      // Crumbs left behind.
      final crumb = Paint()..color = const Color(0xFFB08B5A);
      for (var i = 0; i < 5; i++) {
        canvas.drawCircle(
          plateCenter +
              Offset(
                math.cos(i * 1.7) * w * 0.08,
                math.sin(i * 1.3) * h * 0.03,
              ),
          1.5,
          crumb,
        );
      }
    }

    // Steam while there is still food.
    if (progress < 0.82) {
      for (var i = 0; i < 3; i++) {
        final phase = (t + i * 0.22) % 1;
        final x = w * 0.42 + i * w * 0.07;
        final y = h * 0.48 - phase * h * 0.22;
        canvas.drawCircle(
          Offset(x + math.sin((t + i) * math.pi * 3) * 5, y),
          3.5 + i,
          Paint()..color = Colors.white.withAlpha(30),
        );
      }
    }

    // Fork and knife, with the fork dipping toward the plate.
    final travel = math.sin(progress * math.pi * 6).abs();
    final forkX = w * 0.73 - travel * w * 0.09;
    final forkY = h * 0.69 + travel * h * 0.05;
    final cutlery = Paint()
      ..color = const Color(0xFFD7D2C6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(forkX, forkY - h * 0.06),
      Offset(forkX, forkY + h * 0.08),
      cutlery,
    );
    for (var i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(forkX + i * 3, forkY - h * 0.11),
        Offset(forkX + i * 3, forkY - h * 0.055),
        cutlery,
      );
    }
    canvas.drawLine(
      Offset(w * 0.27, forkY - h * 0.09),
      Offset(w * 0.27, forkY + h * 0.07),
      cutlery,
    );

    // Water glass.
    final glass = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.82, h * 0.52, w * 0.055, h * 0.16),
      const Radius.circular(6),
    );
    canvas.drawRRect(glass, Paint()..color = const Color(0xFF9CC7DA));
    canvas.drawRRect(
      glass.deflate(4),
      Paint()..color = const Color(0xFFD7EEF6).withAlpha(170),
    );

    // Side napkin.
    final napkin = Path()
      ..moveTo(w * 0.13, h * 0.59)
      ..lineTo(w * 0.22, h * 0.57)
      ..lineTo(w * 0.24, h * 0.78)
      ..lineTo(w * 0.15, h * 0.8)
      ..close();
    canvas.drawPath(napkin, Paint()..color = const Color(0xFFE8D1AE));
  }

  @override
  bool shouldRepaint(covariant _MealPlatePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.progress != progress ||
      oldDelegate.meal != meal;
}

class _DiningRoomPainter extends CustomPainter {
  _DiningRoomPainter({
    required this.t,
    required this.period,
    required this.meal,
    required this.eating,
  });

  final double t;
  final DayPeriod period;
  final CookedMeal? meal;
  final bool eating;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final night = period == DayPeriod.night;
    final evening = period == DayPeriod.evening;
    final bg = Offset.zero & size;
    canvas.drawRect(
      bg,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night
              ? const [Color(0xFF100C14), Color(0xFF1C1419), Color(0xFF0B080A)]
              : evening
              ? const [Color(0xFF2A1B20), Color(0xFF40251F), Color(0xFF170E0A)]
              : const [Color(0xFF3A2A23), Color(0xFF4A352A), Color(0xFF1A110D)],
          stops: const [0, 0.66, 1],
        ).createShader(bg),
    );

    // Window with period sky, tucked behind the table.
    _window(canvas, size, night: night, evening: evening);

    // Pendant light.
    final lamp = Offset(w * 0.37, h * 0.14);
    canvas.drawLine(
      Offset(lamp.dx, 0),
      Offset(lamp.dx, lamp.dy - 16),
      Paint()
        ..color = const Color(0xFF1C130E)
        ..strokeWidth = 2,
    );
    final lampPath = Path()
      ..moveTo(lamp.dx - 40, lamp.dy)
      ..quadraticBezierTo(lamp.dx - 34, lamp.dy - 30, lamp.dx, lamp.dy - 30)
      ..quadraticBezierTo(lamp.dx + 34, lamp.dy - 30, lamp.dx + 40, lamp.dy)
      ..close();
    canvas.drawPath(lampPath, Paint()..color = const Color(0xFFD5A15A));
    canvas.drawCircle(
      lamp,
      h * 0.28,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD9A0).withAlpha(evening || night ? 34 : 22),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: lamp, radius: h * 0.28)),
    );

    // Sideboard and a little plant.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.02, h * 0.63, w * 0.19, h * 0.12),
      Paint()..color = const Color(0xFF2F1F16),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.025, h * 0.64, w * 0.175, h * 0.02),
      Paint()..color = const Color(0xFF5A3B25),
    );
    final plantX = w * 0.1;
    final plantY = h * 0.56;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(plantX, plantY + 28),
          width: 34,
          height: 30,
        ),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFFB7793E),
    );
    for (var i = 0; i < 7; i++) {
      final a = -math.pi / 2 + (i - 3) * 0.4;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(plantX + math.cos(a) * 20, plantY + math.sin(a) * 22),
          width: 20,
          height: 10,
        ),
        Paint()..color = const Color(0xFF4E7D51),
      );
    }

    // Chairs (two rounded backs).
    final chairPaint = Paint()..color = const Color(0xFF2A1A12);
    for (final cx in [w * 0.16, w * 0.62]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, h * 0.58),
            width: w * 0.1,
            height: h * 0.18,
          ),
          const Radius.circular(16),
        ),
        chairPaint,
      );
      for (var i = 0; i < 3; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - w * 0.035, h * 0.52 + i * 16, w * 0.07, 3),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF3F2A1D),
        );
      }
    }

    // Table.
    final table = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.4, h * 0.68),
        width: w * 0.6,
        height: h * 0.34,
      ),
      Radius.circular(h * 0.08),
    );
    canvas.drawRRect(
      table.shift(Offset(0, h * 0.03)),
      Paint()..color = Colors.black.withAlpha(85),
    );
    canvas.drawRRect(
      table,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: evening || night
              ? const [Color(0xFF7A4B2D), Color(0xFF3D2416)]
              : const [Color(0xFFA06A42), Color(0xFF5A3520)],
        ).createShader(table.outerRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.4, h * 0.67),
          width: w * 0.52,
          height: h * 0.1,
        ),
        Radius.circular(h * 0.04),
      ),
      Paint()..color = const Color(0xFFE8D1AE).withAlpha(220),
    );
    // Runner.
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w * 0.4, h * 0.67),
        width: w * 0.48,
        height: h * 0.055,
      ),
      Paint()..color = const Color(0xFFB04A4A).withAlpha(190),
    );

    // Plates and cutlery.
    _setting(canvas, Offset(w * 0.2, h * 0.67), meal == null);
    _setting(canvas, Offset(w * 0.52, h * 0.67), true);
    // Centre plate.
    final plateCenter = Offset(w * 0.37, h * 0.68);
    final plateR = h * 0.1;
    canvas.drawOval(
      Rect.fromCenter(
        center: plateCenter,
        width: plateR * 2.4,
        height: plateR * 1.5,
      ),
      Paint()..color = const Color(0xFFF2E4C9),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: plateCenter,
        width: plateR * 1.9,
        height: plateR * 1.15,
      ),
      Paint()..color = const Color(0xFFE3D0AE),
    );
    if (meal != null && !eating) {
      _food(canvas, plateCenter, plateR, meal!);
      _steam(canvas, plateCenter, plateR);
    }
    // Candle for evening/night.
    if (evening || night) {
      final candle = Offset(w * 0.48, h * 0.61);
      canvas.drawRect(
        Rect.fromCenter(
          center: candle + const Offset(0, 16),
          width: 8,
          height: 30,
        ),
        Paint()..color = const Color(0xFFE8D1AE),
      );
      final flame = 0.8 + 0.2 * math.sin(t * math.pi * 10);
      canvas.drawOval(
        Rect.fromCenter(
          center: candle + Offset(0, -4 * flame),
          width: 6,
          height: 16 * flame,
        ),
        Paint()..color = const Color(0xFFFFB347),
      );
      canvas.drawCircle(
        candle + const Offset(0, -2),
        h * 0.06,
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0xFFFFD166).withAlpha(38), Colors.transparent],
          ).createShader(Rect.fromCircle(center: candle, radius: h * 0.06)),
      );
    }
  }

  void _setting(Canvas canvas, Offset center, bool empty) {
    final plate = Rect.fromCenter(center: center, width: 56, height: 34);
    canvas.drawOval(plate, Paint()..color = const Color(0xFFF2E4C9));
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 40, height: 22),
      Paint()..color = const Color(0xFFE3D0AE),
    );
    if (!empty) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 22, height: 12),
        Paint()..color = const Color(0xFFD98E73),
      );
    }
    final cutlery = Paint()
      ..color = const Color(0xFFC9C4B8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - 42, center.dy - 10),
      Offset(center.dx - 42, center.dy + 12),
      cutlery,
    );
    canvas.drawLine(
      Offset(center.dx + 42, center.dy - 10),
      Offset(center.dx + 42, center.dy + 12),
      cutlery,
    );
  }

  void _food(Canvas canvas, Offset center, double r, CookedMeal meal) {
    if (meal.mealId == 'meal_breakfast') {
      // Two eggs and toast.
      for (final dx in [-r * 0.28, r * 0.22]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center + Offset(dx, -r * 0.08),
            width: r * 0.55,
            height: r * 0.38,
          ),
          Paint()..color = const Color(0xFFFDF6E8),
        );
        canvas.drawCircle(
          center + Offset(dx, -r * 0.08),
          r * 0.09,
          Paint()..color = const Color(0xFFFFC857),
        );
      }
      final toast = Path()
        ..moveTo(center.dx + r * 0.35, center.dy - r * 0.1)
        ..lineTo(center.dx + r * 0.75, center.dy - r * 0.1)
        ..lineTo(center.dx + r * 0.72, center.dy + r * 0.3)
        ..lineTo(center.dx + r * 0.4, center.dy + r * 0.3)
        ..close();
      canvas.drawPath(toast, Paint()..color = const Color(0xFFD9A066));
      canvas.drawRect(
        Rect.fromLTWH(
          center.dx + r * 0.48,
          center.dy + r * 0.53,
          r * 0.12,
          r * 0.2,
        ),
        Paint()..color = const Color(0xFFBFD7EA),
      );
    } else if (meal.mealId == 'meal_lunch') {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: r * 1.4, height: r * 0.8),
        Paint()..color = const Color(0xFFF4E6C8),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(0, r * 0.02),
          width: r * 1.15,
          height: r * 0.6,
        ),
        Paint()..color = const Color(0xFFE8DCC8),
      );
      canvas.drawCircle(
        center + Offset(-r * 0.18, -r * 0.02),
        r * 0.14,
        Paint()..color = const Color(0xFFD98E73),
      );
      canvas.drawCircle(
        center + Offset(r * 0.18, r * 0.04),
        r * 0.12,
        Paint()..color = const Color(0xFF74A96B),
      );
      canvas.drawCircle(
        center + Offset(r * 0.02, -r * 0.12),
        r * 0.08,
        Paint()..color = const Color(0xFFB07A4A),
      );
    } else if (meal.mealId == 'meal_dinner') {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: r * 1.45, height: r * 0.82),
        Paint()..color = const Color(0xFF5A3520),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(0, r * 0.01),
          width: r * 1.25,
          height: r * 0.64,
        ),
        Paint()..color = const Color(0xFFE4B363),
      );
      // Noodles.
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        canvas.drawArc(
          Rect.fromCenter(
            center: center + Offset(0, -r * 0.03),
            width: r * (0.5 + i * 0.05),
            height: r * 0.3,
          ),
          a,
          math.pi * 0.9,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFFFFE7A3),
        );
      }
      canvas.drawCircle(
        center + Offset(-r * 0.2, -r * 0.08),
        r * 0.08,
        Paint()..color = const Color(0xFFD9534F),
      );
      canvas.drawCircle(
        center + Offset(r * 0.16, r * 0.08),
        r * 0.07,
        Paint()..color = const Color(0xFFF2C94C),
      );
    } else {
      // Custom plate: a colourful mound with one dot per ingredient.
      canvas.drawOval(
        Rect.fromCenter(center: center, width: r * 1.3, height: r * 0.78),
        Paint()..color = meal.accentDeep,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(0, r * 0.01),
          width: r * 1.08,
          height: r * 0.58,
        ),
        Paint()..color = meal.accent,
      );
      var i = 0;
      for (final entry in meal.ingredients.entries) {
        final ingredient = PantryCatalog.byId(entry.key);
        if (ingredient == null) continue;
        final a = i * math.pi * 0.73 + 0.3;
        canvas.drawCircle(
          center + Offset(math.cos(a) * r * 0.32, math.sin(a) * r * 0.16),
          r * 0.07,
          Paint()..color = ingredient.color,
        );
        i++;
      }
    }
  }

  void _steam(Canvas canvas, Offset center, double r) {
    for (var i = 0; i < 3; i++) {
      final x = center.dx - r * 0.3 + i * r * 0.3;
      final y = center.dy - r * (0.25 + ((t + i * 0.22) % 1) * 0.45);
      canvas.drawCircle(
        Offset(x + math.sin((t + i) * math.pi * 4) * 4, y),
        3.0 + i,
        Paint()..color = Colors.white.withAlpha(34),
      );
    }
  }

  void _window(
    Canvas canvas,
    Size size, {
    required bool night,
    required bool evening,
  }) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(w * 0.14, h * 0.1, w * 0.2, h * 0.34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF3B2517),
    );
    final glass = rect.deflate(6);
    canvas.drawRect(
      glass,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night
              ? const [Color(0xFF0A1230), Color(0xFF1E2E58), Color(0xFF3A4168)]
              : evening
              ? const [Color(0xFF5A3659), Color(0xFFFF8C5A), Color(0xFFFFD08A)]
              : const [Color(0xFF7EC8E3), Color(0xFFBDE6F5), Color(0xFFF3F0D7)],
        ).createShader(glass),
    );
    // Rooftops.
    for (var i = 0; i < 3; i++) {
      final bw = glass.width * 0.32;
      final bh = glass.height * (0.16 + i * 0.04);
      final x = glass.left + i * glass.width * 0.3;
      canvas.drawRect(
        Rect.fromLTWH(x, glass.bottom - bh, bw, bh),
        Paint()
          ..color = night
              ? const Color(0xFF060A15)
              : const Color(0xFF57505A).withAlpha(190),
      );
      if (night || evening) {
        canvas.drawRect(
          Rect.fromLTWH(x + 5, glass.bottom - bh + 6, 3, 3),
          Paint()..color = const Color(0xFFFFD166).withAlpha(190),
        );
      }
    }
    canvas.drawRect(
      Rect.fromLTWH(rect.center.dx - 3, rect.top, 6, rect.height),
      Paint()..color = const Color(0xFF6A4529),
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.center.dy - 3, rect.width, 6),
      Paint()..color = const Color(0xFF6A4529),
    );
  }

  @override
  bool shouldRepaint(covariant _DiningRoomPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.period != period ||
      oldDelegate.meal != meal ||
      oldDelegate.eating != eating;
}
