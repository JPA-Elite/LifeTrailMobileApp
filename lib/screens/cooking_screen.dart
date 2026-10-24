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

/// Full-screen kitchen and pantry.
///
/// The left side holds the three meal recipes; the right side is the actual
/// pantry stock, read from the inventory. Cooking consumes the listed
/// ingredients and adds a plated meal to the table, so buying groceries
/// later automatically enlarges what can be cooked.
class CookingScreen extends ConsumerStatefulWidget {
  const CookingScreen({super.key});

  @override
  ConsumerState<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends ConsumerState<CookingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;
  CookingRecipe? _cookingRecipe;
  CookingRecipe? _lastCooked;
  String? _notice;
  bool _cooking = false;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _cook(CookingRecipe recipe) async {
    if (_cooking) return;
    final gs = ref.read(gameStateProvider);
    if (!gs.canDoActivity(recipe.activityId)) {
      HapticFeedback.heavyImpact();
      setState(() {
        _notice = 'Too tired to cook. Sit down for a moment first.';
      });
      return;
    }
    if (!gs.hasItems(recipe.ingredients)) {
      HapticFeedback.heavyImpact();
      setState(() {
        final missing = recipe.ingredients.entries
            .where((e) => gs.itemCount(e.key) < e.value)
            .map((e) => PantryCatalog.byId(e.key)?.name ?? e.key)
            .join(', ');
        _notice = 'Missing $missing. The Super Market can restock the pantry.';
      });
      return;
    }
    final cooked = gs.cookMeal(recipe);
    if (!cooked) {
      setState(() => _notice = 'The stove needs a moment. Try again.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _cooking = true;
      _cookingRecipe = recipe;
      _notice = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1150));
    if (!mounted) return;
    setState(() {
      _cooking = false;
      _cookingRecipe = null;
      _lastCooked = recipe;
    });
    HapticFeedback.lightImpact();
  }

  void _close() {
    Navigator.of(context).pop(CookingResult(lastCooked: _lastCooked?.mealName));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final period = state.time.period;

    return Scaffold(
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
                            Expanded(flex: 7, child: _recipeColumn(state)),
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
                          Expanded(child: _recipeColumn(state)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 126,
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
          if (_cooking && _cookingRecipe != null)
            Positioned.fill(
              child: _CookingOverlay(
                recipe: _cookingRecipe!,
                ambient: _ambient,
              ),
            ),
        ],
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
                'Cook now, eat at the dining table.',
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

  Widget _recipeColumn(GameState state) {
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
              const Text(
                'What are we cooking?',
                style: TextStyle(
                  color: Color(0xFFFFF4DF),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Pantry ${_pantryTotal(state)} items',
                style: const TextStyle(color: Color(0xFFC4B39F), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 5),
          if (_lastCooked != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: _PlatedBanner(
                recipe: _lastCooked!,
                onTable: () =>
                    Navigator.of(context).pop(CookingResult(openTable: true)),
                onDismiss: () => setState(() => _lastCooked = null),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: CookingCatalog.recipes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final recipe = CookingCatalog.recipes[index];
                return _RecipeCard(
                  recipe: recipe,
                  state: state,
                  isFavorite: state.time.period == recipe.bestPeriod,
                  onCook: () => _cook(recipe),
                );
              },
            ),
          ),
        ],
      ),
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
    required this.recipe,
    required this.onTable,
    required this.onDismiss,
  });

  final CookingRecipe recipe;
  final VoidCallback onTable;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 4, 5),
      decoration: BoxDecoration(
        color: recipe.accentDeep.withAlpha(110),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: recipe.accent.withAlpha(160)),
      ),
      child: Row(
        children: [
          Text(recipe.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${recipe.mealName} is plated. It is waiting on the table.',
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
  const _CookingOverlay({required this.recipe, required this.ambient});

  final CookingRecipe recipe;
  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withAlpha(170),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1100),
          builder: (context, value, _) {
            return Container(
              width: 320,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF241A13),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: recipe.accent.withAlpha(140)),
                boxShadow: [
                  BoxShadow(color: recipe.accent.withAlpha(35), blurRadius: 30),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 82,
                    child: AnimatedBuilder(
                      animation: ambient,
                      builder: (context, _) => CustomPaint(
                        painter: _PanPainter(
                          recipe: recipe,
                          t: ambient.value,
                          progress: value,
                        ),
                        size: const Size(240, 82),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cooking ${recipe.title}',
                    style: const TextStyle(
                      color: Color(0xFFFFF4DF),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'The kitchen smells wonderful.',
                    style: const TextStyle(
                      color: Color(0xFFC8B8A5),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(recipe.accent),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PanPainter extends CustomPainter {
  _PanPainter({required this.recipe, required this.t, required this.progress});

  final CookingRecipe recipe;
  final double t;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Stove ring.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.8),
        width: w * 0.6,
        height: h * 0.2,
      ),
      Paint()..color = const Color(0xFF0C0906),
    );
    // Steam.
    for (var i = 0; i < 4; i++) {
      final x = w * 0.35 + i * w * 0.1;
      final y = h * 0.28 - ((t + i * 0.18) % 1) * h * 0.2;
      canvas.drawCircle(
        Offset(x + math.sin((t + i) * math.pi * 2) * 6, y),
        5.0 + i,
        Paint()..color = Colors.white.withAlpha(28),
      );
    }
    // Pan.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.66),
        width: w * 0.52,
        height: h * 0.14,
      ),
      Paint()..color = const Color(0xFF3C3A3A),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.62),
        width: w * 0.46,
        height: h * 0.12,
      ),
      Paint()..color = const Color(0xFF171515),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.74, h * 0.6, w * 0.24, h * 0.045),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF5E442F),
    );
    // Food.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.62),
        width: w * 0.34,
        height: h * 0.075,
      ),
      Paint()..color = recipe.accentDeep,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.605),
        width: w * 0.28,
        height: h * 0.055,
      ),
      Paint()..color = recipe.accent,
    );
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(w * (0.42 + i * 0.05), h * (0.6 + (i % 2) * 0.02)),
        3,
        Paint()..color = const Color(0xFFFFF4DF).withAlpha(160),
      );
    }
    // Flame hint.
    final flicker = 0.7 + 0.3 * math.sin(t * math.pi * 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.8),
        width: w * 0.18 * flicker,
        height: h * 0.08 * flicker,
      ),
      Paint()..color = const Color(0xFFFF8A3D).withAlpha(120),
    );
  }

  @override
  bool shouldRepaint(covariant _PanPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.progress != progress ||
      oldDelegate.recipe != recipe;
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
