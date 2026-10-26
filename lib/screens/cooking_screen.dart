import 'dart:math' as math;

import 'package:flutter/material.dart' hide DayPeriod;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/state/game_state.dart';
import '../game/systems/core_systems.dart';
import '../models/cooking.dart';
import '../models/game_time.dart';

/// Returned when the player leaves the kitchen.
class CookingResult {
  const CookingResult({
    this.openHomeMenu = false,
    this.openTable = false,
    this.lastCooked,
  });

  final bool openHomeMenu;
  final bool openTable;
  final String? lastCooked;
}

/// A single timed cooking session shown in the full-screen stove scene.
class _CookSession {
  const _CookSession({
    required this.title,
    required this.emoji,
    required this.accent,
    required this.accentDeep,
    required this.minutes,
    required this.plateEnergy,
    required this.energyCost,
    required this.ingredients,
  });

  final String title;
  final String emoji;
  final Color accent;
  final Color accentDeep;

  /// In-game minutes the stove runs for.
  final int minutes;
  final int plateEnergy;
  final int energyCost;
  final Map<String, int> ingredients;

  String get ingredientSummary {
    final parts = <String>[];
    ingredients.forEach((id, count) {
      final ingredient = PantryCatalog.byId(id);
      final label = ingredient?.name ?? id;
      parts.add(count > 1 ? '$label ×$count' : label);
    });
    return parts.join(' · ');
  }

  List<PantryIngredient> get ingredientItems => [
    for (final entry in ingredients.entries)
      if (PantryCatalog.byId(entry.key) != null) PantryCatalog.byId(entry.key)!,
  ];
}

/// Full-screen kitchen and pantry.
///
/// The builder turns the pantry into a live plate: every added portion raises
/// the energy value, the stove time, and the eating time. Fixed family recipes
/// remain one tap away, and every cook runs through a timed stove scene before
/// the ingredients are spent.
class CookingScreen extends ConsumerStatefulWidget {
  const CookingScreen({super.key});

  @override
  ConsumerState<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends ConsumerState<CookingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _cook;

  final Map<String, int> _counts = {};
  _CookSession? _session;
  CookedMeal? _lastCooked;
  String? _notice;
  bool _cooking = false;
  bool _customMode = true;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _cook = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _ambient.dispose();
    _cook.dispose();
    super.dispose();
  }

  CustomCookPlan get _plan => CookingCatalog.planCustom(_counts);

  int get _portions => _counts.values.fold(0, (total, count) => total + count);

  int _durationMs(int minutes) =>
      (900 + minutes * 38).clamp(1800, 5200).toInt();

  void _bump(String ingredientId, int delta, GameState state) {
    if (_cooking) return;
    final current = _counts[ingredientId] ?? 0;
    if (delta > 0) {
      final canAdd =
          _portions < CookingCatalog.maxCustomPortions &&
          current < state.itemCount(ingredientId);
      if (!canAdd) {
        HapticFeedback.selectionClick();
        if (current >= state.itemCount(ingredientId)) {
          setState(
            () => _notice =
                'No more ${PantryCatalog.byId(ingredientId)?.name ?? 'stock'} '
                'in the pantry.',
          );
        } else {
          setState(
            () => _notice =
                'A plate holds at most '
                '${CookingCatalog.maxCustomPortions} portions.',
          );
        }
        return;
      }
      _counts[ingredientId] = current + 1;
    } else {
      if (current <= 0) return;
      final next = current - 1;
      if (next <= 0) {
        _counts.remove(ingredientId);
      } else {
        _counts[ingredientId] = next;
      }
    }
    HapticFeedback.selectionClick();
    setState(() => _notice = null);
  }

  void _chefPick(GameState state) {
    if (_cooking) return;
    final order = switch (state.time.period) {
      DayPeriod.morning => ['egg', 'bread', 'milk', 'tomato', 'cheese'],
      DayPeriod.afternoon => ['rice', 'chicken', 'vegetables', 'tomato'],
      DayPeriod.evening => ['noodles', 'vegetables', 'chicken', 'cheese'],
      DayPeriod.night => ['rice', 'egg', 'vegetables', 'cheese'],
    };
    final picked = <String, int>{};
    var total = 0;
    for (var round = 0; round < 2 && total < 3; round++) {
      for (final id in order) {
        if (total >= 3) break;
        final stock = state.itemCount(id);
        final have = picked[id] ?? 0;
        if (stock > have) {
          picked[id] = have + 1;
          total++;
        }
      }
    }
    if (total == 0) {
      HapticFeedback.heavyImpact();
      setState(() {
        _notice =
            'The pantry is empty. Pick up a grocery bundle at the Super '
            'Market.';
      });
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _counts
        ..clear()
        ..addAll(picked);
      _notice = null;
      _customMode = true;
    });
  }

  Future<void> _startPlan() async {
    if (_cooking) return;
    final plan = _plan;
    if (plan.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() => _notice = 'Add at least one ingredient to the plate.');
      return;
    }
    final state = ref.read(gameStateProvider);
    if (!state.canCookCustom(plan)) {
      HapticFeedback.heavyImpact();
      setState(() {
        _notice = state.player.energy < plan.cookEnergyCost
            ? 'Too tired to cook. Rest on the sofa first.'
            : 'Some of those ingredients just ran out.';
      });
      return;
    }
    await _runCook(plan: plan);
  }

  Future<void> _startRecipe(CookingRecipe recipe) async {
    if (_cooking) return;
    final state = ref.read(gameStateProvider);
    if (!state.canDoActivity(recipe.activityId)) {
      HapticFeedback.heavyImpact();
      setState(() {
        _notice = 'Too tired to cook. Sit down for a moment first.';
      });
      return;
    }
    if (!state.hasItems(recipe.ingredients)) {
      HapticFeedback.heavyImpact();
      setState(() {
        final missing = recipe.ingredients.entries
            .where((e) => state.itemCount(e.key) < e.value)
            .map((e) => PantryCatalog.byId(e.key)?.name ?? e.key)
            .join(', ');
        _notice = 'Missing $missing. The Super Market can restock the pantry.';
      });
      return;
    }
    await _runCook(recipe: recipe);
  }

  Future<void> _runCook({CookingRecipe? recipe, CustomCookPlan? plan}) async {
    final cfg = recipe == null ? null : Activities.of(recipe.activityId);
    final minutes = plan?.cookMinutes ?? cfg?.minutes ?? 30;
    final session = _CookSession(
      title: plan?.name ?? recipe!.title,
      emoji: plan?.emoji ?? recipe!.emoji,
      accent: plan?.accent ?? recipe!.accent,
      accentDeep: plan?.accentDeep ?? recipe!.accentDeep,
      minutes: minutes,
      plateEnergy: plan?.energy ?? recipe!.eatEnergy,
      energyCost: plan?.cookEnergyCost ?? cfg!.energyDelta.abs(),
      ingredients: plan?.ingredients ?? recipe!.ingredients,
    );

    _cook.duration = Duration(milliseconds: _durationMs(minutes));
    HapticFeedback.mediumImpact();
    setState(() {
      _cooking = true;
      _session = session;
      _notice = null;
    });

    await _cook.forward(from: 0);
    if (!mounted) return;

    final state = ref.read(gameStateProvider);
    final success = plan != null
        ? state.cookCustomMeal(plan) != null
        : state.cookMeal(recipe!);
    if (!mounted) return;
    if (!success) {
      _cook.reset();
      setState(() {
        _cooking = false;
        _session = null;
        _notice = 'The stove needs a moment. Try again.';
      });
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _lastCooked = plan?.meal ?? recipe!.toMeal();
      _cooking = false;
      _session = null;
      if (plan != null) {
        _counts.clear();
        _customMode = true;
      }
    });
    _cook.reset();
    HapticFeedback.lightImpact();
  }

  void _close() {
    if (_cooking) return;
    Navigator.of(context).pop(CookingResult(lastCooked: _lastCooked?.name));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final period = state.time.period;

    return PopScope(
      canPop: !_cooking,
      child: Scaffold(
        backgroundColor: const Color(0xFF16110D),
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) => CustomPaint(
                painter: _KitchenPainter(
                  t: _ambient.value,
                  period: period,
                  cooking: _cooking,
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                children: [
                  _header(state),
                  if (_notice != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _NoticePill(text: _notice!),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 720) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 7, child: _cookColumn(state)),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 286,
                                child: _pantryPanel(state, period),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            Expanded(child: _cookColumn(state)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 118,
                              child: _pantryPanel(state, period),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_cooking && _session != null)
              Positioned.fill(
                child: _CookingOverlay(
                  session: _session!,
                  progress: _cook,
                  ambient: _ambient,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(GameState state) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFC77D3A), Color(0xFF6C3A18)],
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
            Icons.soup_kitchen_rounded,
            color: Color(0xFFFFF4DF),
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'THE KITCHEN',
                style: TextStyle(
                  color: Color(0xFFFFF4DF),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Build a plate, then eat it at the dining table.',
                style: TextStyle(color: Color(0xFFD8C8B5), fontSize: 10.5),
              ),
            ],
          ),
        ),
        _HeaderPill(
          icon: Icons.bolt_rounded,
          label: '${state.player.energy} energy',
          tint: const Color(0xFFFFD166),
        ),
        const SizedBox(width: 6),
        _HeaderPill(
          icon: Icons.schedule_rounded,
          label: state.time.clockLabel,
          tint: const Color(0xFF9BD8FF),
        ),
        const SizedBox(width: 6),
        _HeaderPill(
          icon: Icons.wb_twilight_rounded,
          label: state.time.periodLabel,
          tint: const Color(0xFFFFB4A2),
        ),
        const SizedBox(width: 6),
        _HeaderButton(
          icon: Icons.home_outlined,
          label: 'Home menu',
          onTap: () => Navigator.of(
            context,
          ).pop(const CookingResult(openHomeMenu: true)),
        ),
        const SizedBox(width: 4),
        _HeaderButton(
          icon: Icons.close_rounded,
          label: 'Close kitchen',
          onTap: _close,
        ),
      ],
    );
  }

  Widget _cookColumn(GameState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1711).withAlpha(215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ModeChip(
                key: const ValueKey('custom-mode'),
                label: 'Custom plate',
                icon: Icons.tune_rounded,
                selected: _customMode,
                onTap: () => setState(() => _customMode = true),
              ),
              const SizedBox(width: 5),
              _ModeChip(
                key: const ValueKey('classic-mode'),
                label: 'Family recipes',
                icon: Icons.menu_book_rounded,
                selected: !_customMode,
                onTap: () => setState(() => _customMode = false),
              ),
              const Spacer(),
              Text(
                'Pantry ${_pantryTotal(state)} items',
                style: const TextStyle(color: Color(0xFFC4B39F), fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 5),
          if (_lastCooked != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: _PlatedBanner(
                meal: _lastCooked!,
                onTable: () =>
                    Navigator.of(context).pop(CookingResult(openTable: true)),
                onDismiss: () => setState(() => _lastCooked = null),
              ),
            ),
          Expanded(
            child: _customMode ? _customBuilder(state) : _classicRecipes(state),
          ),
        ],
      ),
    );
  }

  Widget _customBuilder(GameState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlatePreview(plan: _plan, portions: _portions),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 3 : 2;
              final width =
                  (constraints.maxWidth - (columns - 1) * 6) / columns;
              return SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    for (final ingredient in PantryCatalog.ingredients)
                      SizedBox(
                        width: width,
                        child: _IngredientSelector(
                          ingredient: ingredient,
                          stock: state.itemCount(ingredient.id),
                          selected: _counts[ingredient.id] ?? 0,
                          canAdd:
                              _portions < CookingCatalog.maxCustomPortions &&
                              (_counts[ingredient.id] ?? 0) <
                                  state.itemCount(ingredient.id),
                          onAdd: () => _bump(ingredient.id, 1, state),
                          onRemove: () => _bump(ingredient.id, -1, state),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            SizedBox(
              height: 34,
              child: OutlinedButton.icon(
                key: const ValueKey('chef-pick'),
                onPressed: () => _chefPick(state),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD166),
                  side: BorderSide(
                    color: const Color(0xFFFFD166).withAlpha(110),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 13),
                label: const Text(
                  "Chef's pick",
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: 34,
                child: FilledButton.icon(
                  key: const ValueKey('start-custom-cook'),
                  onPressed: _plan.isEmpty ? null : _startPlan,
                  style: FilledButton.styleFrom(
                    backgroundColor: _plan.isEmpty
                        ? Colors.white10
                        : _plan.accentDeep,
                    foregroundColor: const Color(0xFFFFF4DF),
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  icon: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 15,
                  ),
                  label: Text(
                    _plan.isEmpty
                        ? 'Add ingredients to cook'
                        : 'Start cooking  ·  ${_plan.cookMinutes} min',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _classicRecipes(GameState state) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: CookingCatalog.recipes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final recipe = CookingCatalog.recipes[index];
        return _RecipeCard(
          recipe: recipe,
          state: state,
          isFavorite: state.time.period == recipe.bestPeriod,
          onCook: () => _startRecipe(recipe),
        );
      },
    );
  }

  Widget _pantryPanel(GameState state, DayPeriod period) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2018).withAlpha(230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5E3C).withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.kitchen_rounded,
                size: 15,
                color: Color(0xFFFFC857),
              ),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'PANTRY STOCK',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFFFF4DF),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _stockHint(period),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFFBCA98F),
                    fontSize: 8.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 6) / 2;
                return SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      for (final ingredient in PantryCatalog.ingredients)
                        SizedBox(
                          width: width,
                          child: _PantryTile(
                            ingredient: ingredient,
                            count: state.itemCount(ingredient.id),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Groceries come from the Super Market. Each bundle restocks '
            'the shelf for more meals.',
            style: TextStyle(
              color: Color(0xFFAE9C85),
              fontSize: 8.3,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  int _pantryTotal(GameState state) {
    var total = 0;
    for (final id in PantryCatalog.ids) {
      total += state.itemCount(id);
    }
    return total;
  }

  String _stockHint(DayPeriod period) {
    switch (period) {
      case DayPeriod.morning:
        return 'breakfast light';
      case DayPeriod.afternoon:
        return 'midday light';
      case DayPeriod.evening:
        return 'dinner light';
      case DayPeriod.night:
        return 'late-night light';
    }
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFB7793E).withAlpha(190)
          : Colors.black.withAlpha(90),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: selected
                    ? const Color(0xFFFFF4DF)
                    : const Color(0xFFC4B39F),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFFFF4DF)
                      : const Color(0xFFC4B39F),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatePreview extends StatelessWidget {
  const _PlatePreview({required this.plan, required this.portions});

  final CustomCookPlan plan;
  final int portions;

  @override
  Widget build(BuildContext context) {
    final empty = plan.isEmpty;
    final accent = empty ? const Color(0xFF8E8071) : plan.accent;
    final accentDeep = empty ? const Color(0xFF3A3028) : plan.accentDeep;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentDeep.withAlpha(165),
            const Color(0xFF1A1410).withAlpha(225),
          ],
        ),
        border: Border.all(color: accent.withAlpha(empty ? 60 : 150)),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accentDeep],
              ),
              boxShadow: [
                BoxShadow(color: accent.withAlpha(40), blurRadius: 10),
              ],
            ),
            child: Center(
              child: Text(plan.emoji, style: const TextStyle(fontSize: 21)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        empty ? 'Your plate is empty' : plan.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFF4DF),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!empty) ...[
                      const SizedBox(width: 5),
                      Text(
                        '$portions/${CookingCatalog.maxCustomPortions} portions',
                        style: TextStyle(
                          color: accent,
                          fontSize: 7.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  empty
                      ? 'Tap + on a pantry ingredient. The energy and stove '
                            'time update live.'
                      : plan.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC8B8A5),
                    fontSize: 8.5,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    _StatChip(
                      icon: Icons.bolt_rounded,
                      label: empty ? '— energy' : '+${plan.energy} energy',
                      tint: const Color(0xFFFFD166),
                    ),
                    _StatChip(
                      icon: Icons.local_fire_department_rounded,
                      label: empty ? '— min' : '${plan.cookMinutes} min cook',
                      tint: const Color(0xFFFFA36C),
                    ),
                    _StatChip(
                      icon: Icons.restaurant_rounded,
                      label: empty ? '— min' : '${plan.eatMinutes} min meal',
                      tint: const Color(0xFF9ED9BD),
                    ),
                    _StatChip(
                      icon: Icons.battery_charging_full_rounded,
                      label: empty ? '— cost' : '-${plan.cookEnergyCost} now',
                      tint: const Color(0xFF9BD8FF),
                    ),
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

class _StatChip extends StatelessWidget {
  const _StatChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withAlpha(55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: tint),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: tint,
              fontSize: 7.7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientSelector extends StatelessWidget {
  const _IngredientSelector({
    required this.ingredient,
    required this.stock,
    required this.selected,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
  });

  final PantryIngredient ingredient;
  final int stock;
  final int selected;
  final bool canAdd;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final chosen = selected > 0;
    final empty = stock <= 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: chosen
            ? ingredient.color.withAlpha(42)
            : empty
            ? const Color(0xFF1A1410).withAlpha(160)
            : const Color(0xFF33261B).withAlpha(215),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: chosen
              ? ingredient.color.withAlpha(175)
              : empty
              ? Colors.white10
              : ingredient.color.withAlpha(55),
          width: chosen ? 1.3 : 1,
        ),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: empty ? 0.35 : 1,
            child: Text(ingredient.emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ingredient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: empty
                        ? const Color(0xFF8E8071)
                        : const Color(0xFFFFF4DF),
                    fontSize: 8.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  empty ? 'out of stock' : '$stock in pantry',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: empty
                        ? const Color(0xFFB06A5E)
                        : const Color(0xFFC4B39F),
                    fontSize: 7.4,
                  ),
                ),
              ],
            ),
          ),
          _StepButton(
            key: ValueKey('remove-${ingredient.id}'),
            icon: Icons.remove_rounded,
            enabled: selected > 0,
            tint: ingredient.color,
            onTap: onRemove,
            semanticLabel: 'Remove one ${ingredient.name}',
          ),
          SizedBox(
            width: 15,
            child: Text(
              '$selected',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: chosen
                    ? const Color(0xFFFFF4DF)
                    : const Color(0xFF8E8071),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _StepButton(
            key: ValueKey('add-${ingredient.id}'),
            icon: Icons.add_rounded,
            enabled: canAdd,
            tint: ingredient.color,
            onTap: onAdd,
            semanticLabel: 'Add one ${ingredient.name}',
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.tint,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final bool enabled;
  final Color tint;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: enabled ? tint.withAlpha(48) : Colors.white.withAlpha(8),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 20,
            height: 20,
            child: Icon(icon, size: 13, color: enabled ? tint : Colors.white24),
          ),
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
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

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
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
        color: Colors.black.withAlpha(110),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: Icon(icon, size: 16, color: const Color(0xFFFFF4DF)),
          ),
        ),
      ),
    );
  }
}

class _NoticePill extends StatelessWidget {
  const _NoticePill({required this.text});

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFFFD166),
            size: 13,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatedBanner extends StatelessWidget {
  const _PlatedBanner({
    required this.meal,
    required this.onTable,
    required this.onDismiss,
  });

  final CookedMeal meal;
  final VoidCallback onTable;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 4, 5),
      decoration: BoxDecoration(
        color: meal.accentDeep.withAlpha(110),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: meal.accent.withAlpha(160)),
      ),
      child: Row(
        children: [
          Text(meal.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${meal.name} is plated. It is waiting on the table.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFF4DF),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onTable,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFFE4A3),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 24),
            ),
            icon: const Icon(Icons.table_restaurant_rounded, size: 13),
            label: const Text('Set the table', style: TextStyle(fontSize: 9.5)),
          ),
          IconButton(
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
            icon: const Icon(
              Icons.close_rounded,
              size: 14,
              color: Color(0xFFD8C8B5),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.state,
    required this.isFavorite,
    required this.onCook,
  });

  final CookingRecipe recipe;
  final GameState state;
  final bool isFavorite;
  final VoidCallback onCook;

  bool get _hasStock => state.hasItems(recipe.ingredients);

  bool get _hasEnergy => state.canDoActivity(recipe.activityId);

  @override
  Widget build(BuildContext context) {
    final canCook = _hasStock && _hasEnergy;
    final cfg = Activities.of(recipe.activityId);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2B2118).withAlpha(235),
            const Color(0xFF1A1410).withAlpha(235),
          ],
        ),
        border: Border.all(
          color: isFavorite
              ? recipe.accent.withAlpha(170)
              : Colors.white.withAlpha(16),
          width: isFavorite ? 1.4 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [recipe.accent, recipe.accentDeep],
              ),
              boxShadow: [
                BoxShadow(color: recipe.accent.withAlpha(45), blurRadius: 10),
              ],
            ),
            child: Center(
              child: Text(recipe.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        recipe.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFF4DF),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isFavorite) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: recipe.accent.withAlpha(35),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: recipe.accent.withAlpha(100),
                          ),
                        ),
                        child: Text(
                          recipe.periodHint,
                          style: TextStyle(
                            color: recipe.accent,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  recipe.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFC8B8A5), fontSize: 9),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 3,
                  runSpacing: 2,
                  children: [
                    for (final entry in recipe.ingredients.entries)
                      _RequirementChip(
                        name: PantryCatalog.byId(entry.key)?.name ?? entry.key,
                        have: state.itemCount(entry.key),
                        need: entry.value,
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 10,
                      color: _hasEnergy
                          ? const Color(0xFFFFD166)
                          : const Color(0xFFFF8A80),
                    ),
                    Text(
                      ' -${cfg.energyDelta.abs()}  ·  ${cfg.minutes}m',
                      style: const TextStyle(
                        color: Color(0xFFC8B8A5),
                        fontSize: 8.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.restaurant_rounded,
                      size: 10,
                      color: Color(0xFF7FC8A9),
                    ),
                    Text(
                      ' +${recipe.eatEnergy} energy when eaten',
                      style: const TextStyle(
                        color: Color(0xFF9ED9BD),
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 58,
            height: 32,
            child: FilledButton(
              onPressed: canCook ? onCook : null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: recipe.accentDeep,
                foregroundColor: const Color(0xFFFFF4DF),
                disabledBackgroundColor: Colors.white10,
                disabledForegroundColor: Colors.white38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Text(
                canCook
                    ? 'Cook'
                    : _hasStock
                    ? 'Rest'
                    : 'Need',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({
    required this.name,
    required this.have,
    required this.need,
  });

  final String name;
  final int have;
  final int need;

  @override
  Widget build(BuildContext context) {
    final ok = have >= need;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: ok
            ? const Color(0xFF315C3B).withAlpha(120)
            : const Color(0xFF6B2420).withAlpha(150),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ok
              ? const Color(0xFF7FC8A9).withAlpha(70)
              : const Color(0xFFFF8A80).withAlpha(80),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_rounded : Icons.close_rounded,
            size: 8,
            color: ok ? const Color(0xFFB8E6CF) : const Color(0xFFFFC2BC),
          ),
          const SizedBox(width: 2),
          Text(
            '$name $have/$need',
            style: TextStyle(
              color: ok ? const Color(0xFFD8F3E5) : const Color(0xFFFFD7D2),
              fontSize: 7.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PantryTile extends StatelessWidget {
  const _PantryTile({required this.ingredient, required this.count});

  final PantryIngredient ingredient;
  final int count;

  @override
  Widget build(BuildContext context) {
    final empty = count <= 0;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: empty
            ? const Color(0xFF1A1410).withAlpha(160)
            : const Color(0xFF3A2B1E).withAlpha(210),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: empty ? Colors.white10 : ingredient.color.withAlpha(75),
        ),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: empty ? 0.35 : 1,
            child: Text(ingredient.emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ingredient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: empty
                        ? const Color(0xFF8E8071)
                        : const Color(0xFFFFF4DF),
                    fontSize: 8.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  empty ? 'out of stock' : '× $count',
                  style: TextStyle(
                    color: empty
                        ? const Color(0xFFB06A5E)
                        : const Color(0xFFFFD166),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CookingOverlay extends StatelessWidget {
  const _CookingOverlay({
    required this.session,
    required this.progress,
    required this.ambient,
  });

  final _CookSession session;
  final Animation<double> progress;
  final Animation<double> ambient;

  String _stage(double value) {
    if (value < 0.16) return 'Heating the pan…';
    if (value < 0.42) return 'Sizzling the first ingredients…';
    if (value < 0.7) return 'Simmering low and slow…';
    if (value < 0.92) return 'Seasoning and plating…';
    return 'Ready to serve.';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0D0906).withAlpha(246),
      child: SafeArea(
        minimum: const EdgeInsets.all(18),
        child: AnimatedBuilder(
          animation: Listenable.merge([progress, ambient]),
          builder: (context, _) {
            final value = progress.value;
            final minutesLeft = math.max(
              0,
              (session.minutes * (1 - value)).ceil(),
            );
            final sceneHeight = (MediaQuery.sizeOf(context).height * 0.36)
                .clamp(130.0, 200.0);
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
                          painter: _StovePainter(
                            t: ambient.value,
                            progress: value,
                            accent: session.accent,
                            accentDeep: session.accentDeep,
                            ingredients: session.ingredientItems,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Cooking ${session.title}',
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
                            icon: Icons.bolt_rounded,
                            label: '-${session.energyCost} now',
                            tint: const Color(0xFF9BD8FF),
                          ),
                          _OverlayChip(
                            icon: Icons.restaurant_rounded,
                            label: '+${session.plateEnergy} when eaten',
                            tint: const Color(0xFF9ED9BD),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.ingredientSummary,
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
                          valueColor: AlwaysStoppedAnimation(session.accent),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${session.minutes}-minute stove session',
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

/// The stove scene behind the timed cooking HUD. Steam and flame are driven
/// by the ambient loop; the pan fills as the cook timer advances.
class _StovePainter extends CustomPainter {
  _StovePainter({
    required this.t,
    required this.progress,
    required this.accent,
    required this.accentDeep,
    required this.ingredients,
  });

  final double t;
  final double progress;
  final Color accent;
  final Color accentDeep;
  final List<PantryIngredient> ingredients;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.62);

    // Warm halo around the stove.
    canvas.drawCircle(
      center,
      h * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFA34D).withAlpha(28), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: h * 0.55)),
    );

    // Counter.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.78, w * 0.84, h * 0.12),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFF2A1C12),
    );

    // Burner ring.
    final burner = Rect.fromCenter(
      center: center + Offset(0, h * 0.18),
      width: w * 0.5,
      height: h * 0.13,
    );
    canvas.drawOval(burner, Paint()..color = const Color(0xFF080605));
    final flame = 0.75 + 0.25 * math.sin(t * math.pi * 10);
    canvas.drawOval(
      burner.deflate(5),
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFC857).withAlpha(130),
            const Color(0xFFFF6B35).withAlpha(80),
            Colors.transparent,
          ],
        ).createShader(burner),
    );
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5 + t * 0.4;
      final r = burner.width * 0.44;
      final p =
          center + Offset(math.cos(a) * r, h * 0.18 + math.sin(a) * r * 0.24);
      canvas.drawCircle(
        p,
        3 * flame,
        Paint()..color = const Color(0xFFFF8A3D).withAlpha(95),
      );
    }

    // Frying pan.
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w * 0.58, height: h * 0.2),
      Paint()..color = const Color(0xFF34302D),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center - Offset(0, h * 0.015),
        width: w * 0.51,
        height: h * 0.16,
      ),
      Paint()..color = const Color(0xFF141211),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.72, h * 0.55, w * 0.22, h * 0.045),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF4A2E1B),
    );

    // Food builds up as the timer advances.
    final fill = progress.clamp(0.0, 1.0);
    final foodWidth = w * (0.12 + 0.3 * fill);
    final foodHeight = h * (0.05 + 0.09 * fill);
    canvas.drawOval(
      Rect.fromCenter(
        center: center - Offset(0, h * 0.015),
        width: foodWidth,
        height: foodHeight,
      ),
      Paint()..color = accentDeep,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center - Offset(0, h * 0.025),
        width: foodWidth * 0.86,
        height: foodHeight * 0.74,
      ),
      Paint()..color = accent,
    );

    // Chunks of the chosen ingredients.
    for (var i = 0; i < ingredients.length; i++) {
      final ingredient = ingredients[i];
      final a = t * math.pi * 2 + i * 1.3;
      final x = center.dx + math.cos(a) * (foodWidth * 0.28);
      final y = center.dy - h * 0.02 + math.sin(a * 1.3) * (foodHeight * 0.22);
      canvas.drawCircle(
        Offset(x, y),
        3.0 + i * 0.5,
        Paint()..color = ingredient.color.withAlpha(220),
      );
    }

    // Steam curls.
    for (var i = 0; i < 5; i++) {
      final phase = (t + i * 0.17) % 1;
      final x = w * 0.36 + i * w * 0.07;
      final y = h * 0.42 - phase * h * 0.29;
      canvas.drawCircle(
        Offset(x + math.sin((t + i) * math.pi * 2) * 8, y),
        4.0 + i * 0.8,
        Paint()..color = Colors.white.withAlpha(26),
      );
    }

    // Floating ingredient emoji-like colour sparks.
    for (var i = 0; i < 8; i++) {
      final phase = (t * 0.7 + i * 0.13) % 1;
      final x = w * 0.2 + ((i * 0.11) % 0.6) * w;
      final y = h * 0.26 + math.sin(phase * math.pi * 2) * 10;
      canvas.drawCircle(
        Offset(x, y),
        1.8,
        Paint()..color = accent.withAlpha(90),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StovePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.ingredients != ingredients;
}

class _KitchenPainter extends CustomPainter {
  _KitchenPainter({
    required this.t,
    required this.period,
    required this.cooking,
  });

  final double t;
  final DayPeriod period;
  final bool cooking;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bg = Offset.zero & size;
    final night = period == DayPeriod.night;
    final evening = period == DayPeriod.evening;
    canvas.drawRect(
      bg,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night
              ? const [Color(0xFF14100E), Color(0xFF1E1713), Color(0xFF0D0907)]
              : evening
              ? const [Color(0xFF2A1B16), Color(0xFF34231A), Color(0xFF160E0A)]
              : const [Color(0xFF2B3A2E), Color(0xFF26352A), Color(0xFF17110D)],
          stops: const [0, 0.6, 1],
        ).createShader(bg),
    );

    // Tile wall.
    final tile = Paint()..color = Colors.white.withAlpha(night ? 4 : 7);
    for (var y = 0.0; y < h * 0.7; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(w, y), tile);
    }
    for (var x = 0.0; x < w; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, h * 0.7), tile);
    }

    // Window with period sky.
    _window(canvas, size, night: night, evening: evening);

    // Hanging copper pots.
    for (var i = 0; i < 4; i++) {
      final cx = w * (0.55 + i * 0.09);
      final cy = h * 0.16;
      final r = 15.0 + i * 2;
      canvas.drawLine(
        Offset(cx, 0),
        Offset(cx, cy - r),
        Paint()
          ..color = const Color(0xFF2A1D13)
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFD08A50), Color(0xFF7A4422)],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.55,
        Paint()..color = const Color(0xFF1C110A),
      );
    }

    // Warm light from the stove.
    final glow = Offset(w * 0.28, h * 0.48);
    canvas.drawCircle(
      glow,
      h * 0.3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            (cooking ? const Color(0xFFFFA34D) : const Color(0xFFFFD9A0))
                .withAlpha(cooking ? 38 : 18),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: glow, radius: h * 0.3)),
    );

    // Counter.
    final counterTop = h * 0.78;
    canvas.drawRect(
      Rect.fromLTWH(0, counterTop, w, h - counterTop),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A3221), Color(0xFF24170F)],
        ).createShader(Rect.fromLTWH(0, counterTop, w, h - counterTop)),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, counterTop, w, 6),
      Paint()..color = const Color(0xFF8B5E3C),
    );
    // Cutting board and bowl silhouettes.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, counterTop + 8, w * 0.17, h * 0.13),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF7B5535),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.44, counterTop + 24),
        width: w * 0.12,
        height: h * 0.09,
      ),
      Paint()..color = const Color(0xFFB0A38F),
    );
    // Steam from the stove when cooking.
    if (cooking) {
      for (var i = 0; i < 3; i++) {
        final x = w * 0.33 + i * 10;
        final y = counterTop - ((t * 1.4 + i * 0.25) % 1) * h * 0.24;
        canvas.drawCircle(
          Offset(x + math.sin((t + i) * math.pi * 2) * 5, y),
          4.0 + i,
          Paint()..color = Colors.white.withAlpha(22),
        );
      }
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
    final rect = Rect.fromLTWH(w * 0.07, h * 0.12, w * 0.25, h * 0.34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = const Color(0xFF3B2517),
    );
    final glass = rect.deflate(7);
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: night
            ? const [Color(0xFF0A1230), Color(0xFF1C2B55), Color(0xFF324165)]
            : evening
            ? const [Color(0xFF5A3659), Color(0xFFFF8C5A), Color(0xFFFFD08A)]
            : const [Color(0xFF7EC8E3), Color(0xFFBDE6F5), Color(0xFFF3F0D7)],
      ).createShader(glass);
    canvas.drawRect(glass, sky);
    // Rooftops outside.
    final roof = Paint()
      ..color = night
          ? const Color(0xFF070A16)
          : const Color(0xFF4A4A55).withAlpha(190);
    for (var i = 0; i < 4; i++) {
      final bw = glass.width * 0.28;
      final bh = glass.height * (0.18 + i * 0.03);
      final x = glass.left + i * glass.width * 0.26;
      canvas.drawRect(Rect.fromLTWH(x, glass.bottom - bh, bw, bh), roof);
      if (night || evening) {
        canvas.drawRect(
          Rect.fromLTWH(x + 5, glass.bottom - bh + 7, 4, 4),
          Paint()..color = const Color(0xFFFFD166).withAlpha(190),
        );
      }
    }
    // Mullions.
    final bar = Paint()..color = const Color(0xFF6A4529);
    canvas.drawRect(
      Rect.fromLTWH(rect.center.dx - 3, rect.top, 6, rect.height),
      bar,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.center.dy - 3, rect.width, 6),
      bar,
    );
    // Sill.
    canvas.drawRect(
      Rect.fromLTWH(rect.left - 8, rect.bottom, rect.width + 16, 6),
      Paint()..color = const Color(0xFF8B5E3C),
    );
  }

  @override
  bool shouldRepaint(covariant _KitchenPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.period != period ||
      oldDelegate.cooking != cooking;
}
