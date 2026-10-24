import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/state/game_state.dart';
import '../models/outfit.dart';

/// Returned when the player closes the closet.
class WardrobeResult {
  const WardrobeResult({required this.changed});

  /// True when the final look differs from the one worn on entry.
  final bool changed;
}

const Color _cream = Color(0xFFF6E8D6);
const Color _gold = Color(0xFFE8B86A);
const Color _dark = Color(0xFF1A1114);

/// Full-screen dress-up room behind the home closet.
///
/// A large mirror shows the player wearing the current tee and shorts. The
/// five tees and five shorts are laid out as cards; tapping one applies it
/// to the player model immediately (so the town sprite updates too), while
/// the mirror preview and the mood line react right away.
class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen>
    with TickerProviderStateMixin {
  static const List<String> _compliments = [
    'That color was made for you.',
    'Crisp. Easy. Completely you.',
    'The mirror approves. So do I.',
    'A little bold, a little breezy.',
    'You look like a good day.',
    'Effortless, with a sparkle.',
    'New fit, same charm.',
    'This one feels like sunshine.',
  ];

  late final AnimationController _ambient;
  late final AnimationController _idle;
  late final AnimationController _open;
  late final AnimationController _sparkle;
  late final Animation<double> _contentFade;
  late final Listenable _roomAnim;
  late final int _initialShirt;
  late final int _initialShorts;

  int _compliment = 0;

  @override
  void initState() {
    super.initState();
    final player = ref.read(gameStateProvider).player;
    _initialShirt = player.shirtIndex;
    _initialShorts = player.shortsIndex;

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _open = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentFade = CurvedAnimation(
      parent: _open,
      curve: const Interval(0.42, 1, curve: Curves.easeOut),
    );
    _roomAnim = Listenable.merge([_ambient, _open]);
  }

  @override
  void dispose() {
    _ambient.dispose();
    _idle.dispose();
    _open.dispose();
    _sparkle.dispose();
    super.dispose();
  }

  bool _lookChanged(GameState state) =>
      state.player.shirtIndex != _initialShirt ||
      state.player.shortsIndex != _initialShorts;

  void _wearShirt(int index) {
    final state = ref.read(gameStateProvider);
    if (state.player.shirtIndex == index) {
      _sparkle.forward(from: 0);
      HapticFeedback.selectionClick();
      return;
    }
    state.setOutfit(shirtIndex: index);
    _react();
  }

  void _wearShorts(int index) {
    final state = ref.read(gameStateProvider);
    if (state.player.shortsIndex == index) {
      _sparkle.forward(from: 0);
      HapticFeedback.selectionClick();
      return;
    }
    state.setOutfit(shortsIndex: index);
    _react();
  }

  void _react() {
    setState(() {
      _compliment = (_compliment + 1) % _compliments.length;
    });
    _sparkle.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  void _surprise() {
    final state = ref.read(gameStateProvider);
    final random = math.Random();
    var shirt = random.nextInt(OutfitCatalog.shirts.length);
    var shorts = random.nextInt(OutfitCatalog.shorts.length);
    // Avoid handing back the exact same look.
    if (shirt == state.player.shirtIndex &&
        shorts == state.player.shortsIndex) {
      shirt = (shirt + 1 + random.nextInt(3)) % OutfitCatalog.shirts.length;
      shorts = (shorts + 1 + random.nextInt(3)) % OutfitCatalog.shorts.length;
    }
    state.setOutfit(shirtIndex: shirt, shortsIndex: shorts);
    _react();
    HapticFeedback.mediumImpact();
  }

  void _done() {
    Navigator.of(
      context,
    ).pop(WardrobeResult(changed: _lookChanged(ref.read(gameStateProvider))));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final shirt = OutfitCatalog.shirtAt(state.player.shirtIndex);
    final shorts = OutfitCatalog.shortsAt(state.player.shortsIndex);
    final look = OutfitCatalog.lookName(
      state.player.shirtIndex,
      state.player.shortsIndex,
    );

    return Scaffold(
      backgroundColor: _dark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _roomAnim,
            builder: (context, _) => CustomPaint(
              painter: _ClosetRoomPainter(ambient: _ambient.value),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(14),
            child: FadeTransition(
              opacity: _contentFade,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 700;
                  if (wide) {
                    final panelWidth = math.min(
                      478.0,
                      constraints.maxWidth * 0.56,
                    );
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _PreviewStage(
                            shirt: shirt,
                            shorts: shorts,
                            idle: _idle,
                            sparkle: _sparkle,
                            compact: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: panelWidth,
                          child: _WardrobePanel(
                            shirt: shirt,
                            shorts: shorts,
                            look: look,
                            compliment: _compliments[_compliment],
                            complimentIndex: _compliment,
                            changed: _lookChanged(state),
                            compact: false,
                            onShirt: _wearShirt,
                            onShorts: _wearShorts,
                            onRandom: _surprise,
                            onDone: _done,
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _PreviewStage(
                          shirt: shirt,
                          shorts: shorts,
                          idle: _idle,
                          sparkle: _sparkle,
                          compact: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 6,
                        child: _WardrobePanel(
                          shirt: shirt,
                          shorts: shorts,
                          look: look,
                          compliment: _compliments[_compliment],
                          complimentIndex: _compliment,
                          changed: _lookChanged(state),
                          compact: true,
                          onShirt: _wearShirt,
                          onShorts: _wearShorts,
                          onRandom: _surprise,
                          onDone: _done,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // The closet doors open over everything at the start, then slide
          // away to reveal the room. IgnorePointer keeps them from eating
          // taps while they are still on screen.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _open,
                builder: (context, _) => CustomPaint(
                  painter: _DoorPainter(open: _open.value),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewStage extends StatelessWidget {
  const _PreviewStage({
    required this.shirt,
    required this.shorts,
    required this.idle,
    required this.sparkle,
    required this.compact,
  });

  final OutfitItem shirt;
  final OutfitItem shorts;
  final Animation<double> idle;
  final Animation<double> sparkle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(
          child: CustomPaint(
            painter: _MirrorPainter(),
            child: SizedBox.expand(),
          ),
        ),
        Positioned.fill(
          bottom: compact ? 18 : 26,
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 270,
                height: 310,
                child: AnimatedBuilder(
                  animation: Listenable.merge([idle, sparkle]),
                  builder: (context, _) => CustomPaint(
                    painter: _DressUpFigurePainter(
                      shirt: shirt,
                      shorts: shorts,
                      idle: idle.value,
                      sparkle: sparkle.value,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(top: 0, left: 0, child: _ScenePill(compact: compact)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Center(
            child: _LookChip(shirt: shirt, shorts: shorts),
          ),
        ),
      ],
    );
  }
}

class _WardrobePanel extends StatelessWidget {
  const _WardrobePanel({
    required this.shirt,
    required this.shorts,
    required this.look,
    required this.compliment,
    required this.complimentIndex,
    required this.changed,
    required this.compact,
    required this.onShirt,
    required this.onShorts,
    required this.onRandom,
    required this.onDone,
  });

  final OutfitItem shirt;
  final OutfitItem shorts;
  final String look;
  final String compliment;
  final int complimentIndex;
  final bool changed;
  final bool compact;
  final ValueChanged<int> onShirt;
  final ValueChanged<int> onShorts;
  final VoidCallback onRandom;
  final VoidCallback onDone;

  Widget _cards({required bool isShirt}) {
    final items = isShirt ? OutfitCatalog.shirts : OutfitCatalog.shorts;
    final selectedIndex = isShirt ? shirtIndex : shortsIndex;
    return SizedBox(
      height: compact ? 68 : 76,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _GarmentCard(
                item: items[i],
                isShirt: isShirt,
                selected: i == selectedIndex,
                onTap: () => isShirt ? onShirt(i) : onShorts(i),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Filled in by the caller through the selected items below.
  int get shirtIndex => OutfitCatalog.shirts.indexOf(shirt);
  int get shortsIndex => OutfitCatalog.shorts.indexOf(shorts);

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 10.0 : 14.0;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF21E1418), Color(0xF20E090B)],
        ),
        border: Border.all(color: const Color(0x33FFE3B0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _HangerBadge(),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TODAY'S FIT",
                        style: TextStyle(
                          color: _cream,
                          fontSize: compact ? 10 : 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap a piece to wear it',
                        style: TextStyle(
                          color: _cream.withAlpha(150),
                          fontSize: compact ? 8 : 8.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: _StyleChip(text: look),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(label: 'TOPS', count: '5 tees'),
                    const SizedBox(height: 6),
                    _cards(isShirt: true),
                    const SizedBox(height: 10),
                    const _SectionHeader(label: 'BOTTOMS', count: '5 shorts'),
                    const SizedBox(height: 6),
                    _cards(isShirt: false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: _gold, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Text(
                      compliment,
                      key: ValueKey(complimentIndex),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _cream.withAlpha(210),
                        fontSize: compact ? 9.5 : 10.5,
                        fontStyle: FontStyle.italic,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
                if (changed) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF9CCC65),
                    size: 14,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRandom,
                    icon: const Icon(Icons.casino, size: 15),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Surprise me'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cream,
                      side: BorderSide(color: _cream.withAlpha(60)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: TextStyle(
                        fontSize: compact ? 9.5 : 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDone,
                    icon: const Icon(Icons.check, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Done'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: _dark,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: TextStyle(
                        fontSize: compact ? 9.5 : 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenePill extends StatelessWidget {
  const _ScenePill({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC1A1114),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x33FFE3B0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.checkroom, color: _gold, size: 16),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The Closet',
                style: TextStyle(
                  color: _cream,
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              if (!compact)
                Text(
                  'Home · dressing room',
                  style: TextStyle(color: _cream.withAlpha(150), fontSize: 8.5),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LookChip extends StatelessWidget {
  const _LookChip({required this.shirt, required this.shorts});

  final OutfitItem shirt;
  final OutfitItem shorts;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xD91A1114),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cream.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ColorDot(color: shirt.primary),
          const SizedBox(width: 5),
          _ColorDot(color: shorts.primary),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '${shirt.name}  ·  ${shorts.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _cream.withAlpha(225),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});

  final String label;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _gold,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: _cream.withAlpha(24))),
        const SizedBox(width: 8),
        Text(
          count,
          style: TextStyle(color: _cream.withAlpha(120), fontSize: 8),
        ),
      ],
    );
  }
}

class _HangerBadge extends StatelessWidget {
  const _HangerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFDE9B), _gold],
        ),
        borderRadius: BorderRadius.circular(11),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66E8B86A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.checkroom, color: _dark, size: 19),
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _gold.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: _gold, size: 10),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _gold,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GarmentCard extends StatelessWidget {
  const _GarmentCard({
    required this.item,
    required this.isShirt,
    required this.selected,
    required this.onTap,
  });

  final OutfitItem item;
  final bool isShirt;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${isShirt ? 'Tee' : 'Shorts'}: ${item.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? item.primary.withAlpha(54)
                : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? item.accent : Colors.white.withAlpha(28),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: item.primary.withAlpha(100),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(3, 5, 3, 4),
                child: Column(
                  children: [
                    Expanded(
                      child: SizedBox.expand(
                        child: CustomPaint(
                          painter: _GarmentIconPainter(
                            item: item,
                            isShirt: isShirt,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : _cream.withAlpha(185),
                        fontSize: 7.8,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 3,
                  right: 3,
                  child: _CheckBadge(color: item.accent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: const Icon(Icons.check, size: 9, color: _dark),
    );
  }
}

/// Warm dressing-room backdrop: blush wall, dark wood floor, a patterned
/// rug and drifting golden motes. The mirror and the figure are painted by
/// separate layers above this.
class _ClosetRoomPainter extends CustomPainter {
  _ClosetRoomPainter({required this.ambient});

  final double ambient;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wall = Rect.fromLTWH(0, 0, w, h * 0.76);
    canvas.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1A25), Color(0xFF6F4450), Color(0xFFD19A86)],
          stops: [0, 0.58, 1],
        ).createShader(wall),
    );

    // Faint vertical wallpaper lines.
    final stripe = Paint()..color = Colors.white.withAlpha(8);
    for (var i = 1; i < 12; i++) {
      final x = w * i / 12;
      canvas.drawRect(Rect.fromLTWH(x, 0, 1.2, h * 0.74), stripe);
    }

    // Warm glow behind the mirror.
    final glowCenter = Offset(w * 0.5, h * 0.34);
    final glowRect = Rect.fromCircle(center: glowCenter, radius: w * 0.52);
    canvas.drawCircle(
      glowCenter,
      w * 0.52,
      Paint()
        ..shader = RadialGradient(
          colors: [_gold.withAlpha(34), _gold.withAlpha(0)],
        ).createShader(glowRect),
    );

    // Dark wood floor.
    final floor = Rect.fromLTWH(0, h * 0.74, w, h * 0.26);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF64402F), Color(0xFF2A1813)],
        ).createShader(floor),
    );

    // Plank seams.
    final seam = Paint()..color = Colors.black.withAlpha(30);
    for (var i = 1; i < 7; i++) {
      final y = h * 0.74 + i * h * 0.036;
      canvas.drawLine(Offset(0, y), Offset(w, y), seam);
    }
    for (var i = 0; i < 8; i++) {
      final x = w * i / 8;
      canvas.drawLine(
        Offset(x, h * 0.74),
        Offset(x + w * 0.03, h),
        Paint()..color = Colors.black.withAlpha(18),
      );
    }

    // Skirting board.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.727, w, h * 0.016),
      Paint()..color = const Color(0xFF3A241C),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.727, w, 2),
      Paint()..color = const Color(0x66E8B86A),
    );

    // Oval rug under the mirror.
    final rug = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.895),
      width: w * 0.78,
      height: h * 0.155,
    );
    canvas.drawOval(
      rug.inflate(4),
      Paint()..color = Colors.black.withAlpha(40),
    );
    canvas.drawOval(rug, Paint()..color = const Color(0xFF7A3F4B));
    canvas.drawOval(
      rug.deflate(9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _cream.withAlpha(70),
    );
    final fringe = Paint()
      ..color = _cream.withAlpha(90)
      ..strokeWidth = 1.3;
    for (var i = 0; i < 22; i++) {
      final t = i / 21;
      final x = rug.left + rug.width * t;
      final y = rug.center.dy + rug.height * 0.46;
      canvas.drawLine(Offset(x, y), Offset(x + 2, y + 5), fringe);
    }

    // Slim wardrobe frames at the edges.
    _paintSideFrame(canvas, Rect.fromLTWH(0, 0, w * 0.055, h), left: true);
    _paintSideFrame(
      canvas,
      Rect.fromLTWH(w * 0.945, 0, w * 0.055, h),
      left: false,
    );

    // Drifting golden motes.
    for (var i = 0; i < 14; i++) {
      final seed = i * 0.61803398875;
      final drift = math.sin(ambient * math.pi * 2 + i * 0.9) * 3;
      final x = w * (0.08 + 0.84 * (seed % 1.0)) + drift;
      final y =
          h * (0.14 + 0.64 * ((seed * 1.71 + ambient * 0.05) % 1.0)) + drift;
      final radius = 1.1 + (i % 3) * 0.6;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = _gold.withAlpha(34 + (i % 3) * 22),
      );
    }

    // Soft bottom vignette so the panel edge sits naturally.
    final vignette = Rect.fromLTWH(0, h * 0.70, w, h * 0.30);
    canvas.drawRect(
      vignette,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withAlpha(0), Colors.black.withAlpha(80)],
        ).createShader(vignette),
    );
  }

  void _paintSideFrame(Canvas canvas, Rect rect, {required bool left}) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF3A2119), Color(0xFF6B4431)],
        ).createShader(rect),
    );
    final innerX = left ? rect.right - 3 : rect.left + 3;
    canvas.drawLine(
      Offset(innerX, rect.top),
      Offset(innerX, rect.bottom),
      Paint()..color = const Color(0x66E8B86A),
    );
    for (var i = 1; i < 5; i++) {
      final y = rect.height * i / 5;
      canvas.drawLine(
        Offset(rect.left + 4, y),
        Offset(rect.right - 4, y),
        Paint()..color = Colors.black.withAlpha(40),
      );
    }
    // Brass hook.
    canvas.drawCircle(
      Offset(rect.center.dx, rect.height * 0.30),
      3.2,
      Paint()..color = _gold,
    );
  }

  @override
  bool shouldRepaint(covariant _ClosetRoomPainter oldDelegate) =>
      oldDelegate.ambient != ambient;
}

/// Two wardrobe doors that slide apart at the start of the scene.
class _DoorPainter extends CustomPainter {
  _DoorPainter({required this.open});

  final double open;

  @override
  void paint(Canvas canvas, Size size) {
    if (open >= 0.999) return;
    final w = size.width;
    final h = size.height;
    final t = Curves.easeInOutCubic.transform(open.clamp(0.0, 1.0));
    final doorW = w * 0.5;
    _paintDoor(canvas, Rect.fromLTWH(-t * doorW, 0, doorW, h), left: true);
    _paintDoor(
      canvas,
      Rect.fromLTWH(w - doorW + t * doorW, 0, doorW, h),
      left: false,
    );
  }

  void _paintDoor(Canvas canvas, Rect rect, {required bool left}) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Color(0xFF5A382B), Color(0xFF3B2119)],
        ).createShader(rect),
    );

    // Grain.
    for (var i = 0; i < 7; i++) {
      final x = rect.left + rect.width * (i + 0.5) / 7;
      canvas.drawLine(
        Offset(x, rect.top + 8),
        Offset(x + 4, rect.bottom - 8),
        Paint()..color = Colors.black.withAlpha(18),
      );
    }

    // Inset panels.
    final panelPaint = Paint()
      ..color = const Color(0xFF2A1712)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final topPanel = Rect.fromLTRB(
      rect.left + rect.width * 0.13,
      rect.top + rect.height * 0.11,
      rect.right - rect.width * 0.13,
      rect.top + rect.height * 0.42,
    );
    final bottomPanel = Rect.fromLTRB(
      rect.left + rect.width * 0.13,
      rect.top + rect.height * 0.50,
      rect.right - rect.width * 0.13,
      rect.top + rect.height * 0.88,
    );
    for (final panel in [topPanel, bottomPanel]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(panel, const Radius.circular(4)),
        Paint()..color = const Color(0x22000000),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(panel, const Radius.circular(4)),
        panelPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(panel.deflate(5), const Radius.circular(2)),
        Paint()
          ..color = _gold.withAlpha(26)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Center seam shadow.
    final seamX = left ? rect.right - 1 : rect.left + 1;
    canvas.drawRect(
      Rect.fromLTWH(seamX - 1, rect.top, 2, rect.height),
      Paint()..color = Colors.black.withAlpha(120),
    );

    // Brass handle near the seam.
    final hx = left ? rect.right - 26 : rect.left + 26;
    final hy = rect.top + rect.height * 0.54;
    canvas.drawCircle(
      Offset(hx, hy),
      13,
      Paint()..color = const Color(0xFF2A1712),
    );
    canvas.drawCircle(
      Offset(hx, hy),
      10,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFE3A0), _gold, Color(0xFF9A6A2C)],
        ).createShader(Rect.fromCircle(center: Offset(hx, hy), radius: 10)),
    );
    canvas.drawCircle(
      Offset(hx - 2, hy - 3),
      2.4,
      Paint()..color = Colors.white.withAlpha(80),
    );

    // Small monogram plaque.
    final plaque = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          left ? rect.right - 42 : rect.left + 42,
          rect.top + rect.height * 0.18,
        ),
        width: 34,
        height: 18,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(plaque, Paint()..color = const Color(0xFF2A1712));
    canvas.drawRRect(
      plaque,
      Paint()
        ..color = _gold.withAlpha(150)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _DoorPainter oldDelegate) =>
      oldDelegate.open != open;
}

/// The tall arched mirror behind the dress-up figure, plus a little shelf of
/// perfume bottles at its base.
class _MirrorPainter extends CustomPainter {
  const _MirrorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(w * 0.075, h * 0.045, w * 0.85, h * 0.815);
    final shape = _arch(rect);

    // Soft halo and drop shadow.
    canvas.drawPath(
      shape,
      Paint()
        ..color = _gold.withAlpha(40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..color = Colors.black.withAlpha(60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Glass.
    canvas.drawPath(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF1EF), Color(0xFFD9C6CB), Color(0xFFB59AA6)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );

    canvas.save();
    canvas.clipPath(shape);
    // Diagonal shine.
    final shine = Path()
      ..moveTo(rect.left + rect.width * 0.05, rect.bottom)
      ..lineTo(rect.left + rect.width * 0.38, rect.top)
      ..lineTo(rect.left + rect.width * 0.58, rect.top)
      ..lineTo(rect.left + rect.width * 0.25, rect.bottom)
      ..close();
    canvas.drawPath(shine, Paint()..color = Colors.white.withAlpha(34));
    final shine2 = Path()
      ..moveTo(rect.left + rect.width * 0.58, rect.bottom)
      ..lineTo(rect.left + rect.width * 0.80, rect.top)
      ..lineTo(rect.left + rect.width * 0.86, rect.top)
      ..lineTo(rect.left + rect.width * 0.64, rect.bottom)
      ..close();
    canvas.drawPath(shine2, Paint()..color = Colors.white.withAlpha(16));
    // Soft reflected light.
    canvas.drawCircle(
      Offset(rect.center.dx, rect.top + rect.height * 0.33),
      rect.width * 0.30,
      Paint()
        ..shader =
            RadialGradient(
              colors: [Colors.white.withAlpha(38), Colors.white.withAlpha(0)],
            ).createShader(
              Rect.fromCircle(
                center: Offset(rect.center.dx, rect.top + rect.height * 0.33),
                radius: rect.width * 0.30,
              ),
            ),
    );
    canvas.restore();

    // Brass frame.
    canvas.drawPath(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8A5B22),
            Color(0xFFF4DCA0),
            Color(0xFFC4933F),
            Color(0xFFF4DCA0),
            Color(0xFF8A5B22),
          ],
          stops: [0, 0.25, 0.5, 0.75, 1],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11,
    );
    canvas.drawPath(
      shape,
      Paint()
        ..color = const Color(0xFF5A3A1C).withAlpha(120)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Glass sparkles.
    for (final sparkle in [
      (0.22, 0.24, 7.0),
      (0.76, 0.18, 5.0),
      (0.64, 0.46, 3.5),
      (0.34, 0.56, 3.0),
    ]) {
      final center = Offset(
        rect.left + rect.width * sparkle.$1,
        rect.top + rect.height * sparkle.$2,
      );
      _paintSparkle(canvas, center, sparkle.$3, Colors.white.withAlpha(150));
    }

    // Shelf with perfume bottles.
    final shelf = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left - 8, rect.bottom - 4, rect.width + 16, 12),
      const Radius.circular(4),
    );
    canvas.drawRRect(shelf, Paint()..color = const Color(0xFF3A2119));
    canvas.drawRRect(
      shelf,
      Paint()
        ..color = _gold.withAlpha(150)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final bottles = [
      (0.16, 24.0, 14.0, const Color(0xFFD98C8C)),
      (0.27, 30.0, 11.0, const Color(0xFF8FC5B8)),
      (0.38, 19.0, 12.0, const Color(0xFFE3C16F)),
    ];
    for (final bottle in bottles) {
      final bottleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left + rect.width * bottle.$1,
          rect.bottom - bottle.$2 - 3,
          bottle.$3,
          bottle.$2,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(bottleRect, Paint()..color = bottle.$4);
      canvas.drawRRect(
        bottleRect,
        Paint()
          ..color = Colors.black.withAlpha(40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          bottleRect.left + bottle.$3 * 0.32,
          bottleRect.top - 5,
          bottle.$3 * 0.36,
          6,
        ),
        Paint()..color = _gold,
      );
    }
  }

  Path _arch(Rect r) {
    final arch = math.min(r.width * 0.42, r.height * 0.52);
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + arch)
      ..quadraticBezierTo(r.left, r.top, r.left + arch, r.top)
      ..lineTo(r.right - arch, r.top)
      ..quadraticBezierTo(r.right, r.top, r.right, r.top + arch)
      ..lineTo(r.right, r.bottom)
      ..close();
  }

  void _paintSparkle(Canvas canvas, Offset center, double r, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..quadraticBezierTo(
        center.dx + r * 0.18,
        center.dy - r * 0.18,
        center.dx + r,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + r * 0.18,
        center.dy + r * 0.18,
        center.dx,
        center.dy + r,
      )
      ..quadraticBezierTo(
        center.dx - r * 0.18,
        center.dy + r * 0.18,
        center.dx - r,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - r * 0.18,
        center.dy - r * 0.18,
        center.dx,
        center.dy - r,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MirrorPainter oldDelegate) => false;
}

/// Large paper-doll style preview of the player wearing the chosen look.
///
/// Everything is authored against a 270 x 310 box: big head, oversized tee,
/// shorts, socks and sneakers. The idle controller drives a gentle bob and
/// blink; the sparkle controller fires a ring of stars after a change.
class _DressUpFigurePainter extends CustomPainter {
  _DressUpFigurePainter({
    required this.shirt,
    required this.shorts,
    required this.idle,
    required this.sparkle,
  });

  final OutfitItem shirt;
  final OutfitItem shorts;
  final double idle;
  final double sparkle;

  static const Color _skin = Color(0xFFF2C9A4);
  static const Color _ink = Color(0xFF3A2C26);
  static const Color _sock = Color(0xFFF8F2E8);
  static const Color _shoe = Color(0xFF2A2C34);
  static const Color _sole = Color(0xFFF1E7D8);
  static const Color _hair = Color(0xFF4A3B32);
  static const Color _hairLight = Color(0xFF5F4B3D);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final bob = math.sin(idle * math.pi * 2) * 2.2;
    final sway = math.sin(idle * math.pi * 2) * 1.4;
    final blink = idle > 0.93;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h - 16), width: w * 0.44, height: 16),
      Paint()..color = Colors.black.withAlpha(48),
    );

    if (sparkle > 0 && sparkle < 1) {
      final t = sparkle;
      for (var i = 0; i < 8; i++) {
        final angle = -math.pi / 2 + i * math.pi / 4;
        final distance = 82 + t * 62;
        final center = Offset(
          cx + math.cos(angle) * distance,
          158 + math.sin(angle) * distance * 0.9,
        );
        _drawSparkle(
          canvas,
          center,
          (1 - t) * 7 + 2,
          shirt.accent.withAlpha(((1 - t) * 210).round()),
        );
      }
    }

    canvas.save();
    canvas.translate(0, bob);
    _paintLegs(canvas, cx, sway);
    _paintShorts(canvas, cx);
    _paintArms(canvas, cx, sway);
    _paintNeck(canvas, cx);
    _paintTee(canvas, cx);
    _paintHead(canvas, cx, blink);
    canvas.restore();
  }

  void _paintLegs(Canvas canvas, double cx, double sway) {
    final leg = Paint()
      ..color = _skin
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final leftAnkle = Offset(cx - 24 + sway, 266);
    final rightAnkle = Offset(cx + 24 + sway, 266);
    canvas.drawLine(Offset(cx - 22, 234), leftAnkle, leg);
    canvas.drawLine(Offset(cx + 22, 234), rightAnkle, leg);

    final sock = Paint()
      ..color = _sock
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 24 + sway, 252), leftAnkle, sock);
    canvas.drawLine(Offset(cx + 24 + sway, 252), rightAnkle, sock);
    final stripe = Paint()
      ..color = shorts.accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 24 + sway, 256),
      Offset(cx - 24 + sway, 261),
      stripe,
    );
    canvas.drawLine(
      Offset(cx + 24 + sway, 256),
      Offset(cx + 24 + sway, 261),
      stripe,
    );

    _paintShoe(canvas, Offset(cx - 26 + sway, 278));
    _paintShoe(canvas, Offset(cx + 26 + sway, 278));
  }

  void _paintShoe(Canvas canvas, Offset center) {
    final shoe = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 48, height: 18),
      const Radius.circular(8),
    );
    canvas.drawRRect(shoe, Paint()..color = _shoe);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + const Offset(0, 6),
          width: 48,
          height: 6,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = _sole,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + const Offset(0, 6),
          width: 22,
          height: 3,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = shorts.accent.withAlpha(200),
    );
    final lace = Paint()
      ..color = _sole.withAlpha(180)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final x = center.dx - 9 + i * 6;
      canvas.drawLine(Offset(x, center.dy - 2), Offset(x, center.dy + 2), lace);
    }
  }

  void _paintShorts(Canvas canvas, double cx) {
    const top = 182.0;
    const bottom = 242.0;
    final left = cx - 50;
    final right = cx + 50;
    final hip = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, top + 30),
      const Radius.circular(10),
    );
    final leftLeg = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top + 18, cx - 6, bottom),
      const Radius.circular(9),
    );
    final rightLeg = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx + 6, top + 18, right, bottom),
      const Radius.circular(9),
    );

    final fill = Paint()..color = shorts.primary;
    final outline = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    for (final piece in [hip, leftLeg, rightLeg]) {
      canvas.drawRRect(piece, fill);
      canvas.drawRRect(piece, outline);
    }

    // Waistband and drawstring sit under the tee hem but still peek out.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left + 3, top + 4, right - 3, top + 12),
        const Radius.circular(4),
      ),
      Paint()..color = shorts.accent.withAlpha(170),
    );
    final cord = Paint()
      ..color = shorts.accent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, top + 8), Offset(cx - 6, top + 18), cord);
    canvas.drawLine(Offset(cx, top + 8), Offset(cx + 6, top + 18), cord);

    switch (shorts.pattern) {
      case OutfitPattern.solid:
        break;
      case OutfitPattern.trim:
        final stripe = Paint()
          ..color = shorts.accent
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(left + 5, top + 16),
          Offset(left + 5, bottom - 6),
          stripe,
        );
        canvas.drawLine(
          Offset(right - 5, top + 16),
          Offset(right - 5, bottom - 6),
          stripe,
        );
        break;
      case OutfitPattern.stripe:
        canvas.save();
        canvas.clipRRect(hip);
        canvas.drawRect(
          Rect.fromLTRB(left, top + 21, right, top + 29),
          Paint()..color = shorts.accent,
        );
        canvas.restore();
        break;
      case OutfitPattern.pocket:
        final stitch = Paint()
          ..color = shorts.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawArc(
          Rect.fromLTWH(left + 8, top + 10, 24, 22),
          0.2,
          2.4,
          false,
          stitch,
        );
        canvas.drawArc(
          Rect.fromLTWH(right - 32, top + 10, 24, 22),
          0.7,
          2.4,
          false,
          stitch,
        );
        break;
      case OutfitPattern.star:
        _drawStar(canvas, Offset(cx - 26, 220), 9, shorts.accent);
        break;
      case OutfitPattern.heart:
        _drawHeart(canvas, Offset(cx - 26, 220), 9, shorts.accent);
        break;
    }

    final hem = Paint()
      ..color = shorts.accent.withAlpha(170)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(left + 4, bottom - 4),
      Offset(cx - 8, bottom - 4),
      hem,
    );
    canvas.drawLine(
      Offset(cx + 8, bottom - 4),
      Offset(right - 4, bottom - 4),
      hem,
    );
  }

  void _paintArms(Canvas canvas, double cx, double sway) {
    final arm = Paint()
      ..color = _skin
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(cx - 44, 136)
        ..lineTo(cx - 58 + sway, 172)
        ..lineTo(cx - 54 + sway, 198),
      arm,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 44, 136)
        ..lineTo(cx + 58 + sway, 172)
        ..lineTo(cx + 54 + sway, 198),
      arm,
    );
    canvas.drawCircle(Offset(cx - 54 + sway, 200), 7, Paint()..color = _skin);
    canvas.drawCircle(Offset(cx + 54 + sway, 200), 7, Paint()..color = _skin);
    // Tiny bracelet.
    canvas.drawCircle(
      Offset(cx + 57 + sway, 192),
      2.4,
      Paint()..color = shirt.accent,
    );
  }

  void _paintNeck(Canvas canvas, double cx) {
    final neck = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 114), width: 26, height: 32),
      const Radius.circular(10),
    );
    canvas.drawRRect(neck, Paint()..color = _skin);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 120), width: 24, height: 8),
      Paint()..color = Colors.black.withAlpha(20),
    );
  }

  void _paintTee(Canvas canvas, double cx) {
    const top = 120.0;
    const hem = 202.0;
    final left = cx - 52;
    final right = cx + 52;
    final body = Path()
      ..moveTo(left + 15, top)
      ..quadraticBezierTo(cx, top + 13, right - 15, top)
      ..lineTo(right, top + 10)
      ..lineTo(right + 18, top + 30)
      ..lineTo(right + 7, top + 54)
      ..lineTo(right, top + 46)
      ..lineTo(right, hem - 7)
      ..quadraticBezierTo(cx, hem + 8, left, hem - 7)
      ..lineTo(left, top + 46)
      ..lineTo(left - 7, top + 54)
      ..lineTo(left - 18, top + 30)
      ..lineTo(left, top + 10)
      ..close();

    canvas.drawPath(body, Paint()..color = shirt.primary);
    canvas.drawPath(
      body,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );

    // Neckline skin patch and collar.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, top + 1), width: 30, height: 13),
      Paint()..color = _skin,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left + 15, top)
        ..quadraticBezierTo(cx, top + 13, right - 15, top),
      Paint()
        ..color = shirt.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.save();
    canvas.clipPath(body);
    switch (shirt.pattern) {
      case OutfitPattern.solid:
        break;
      case OutfitPattern.stripe:
        canvas.drawRect(
          Rect.fromLTRB(left - 20, 148, right + 20, 158),
          Paint()..color = shirt.accent,
        );
        canvas.drawRect(
          Rect.fromLTRB(left - 20, 160, right + 20, 162),
          Paint()..color = Colors.white.withAlpha(120),
        );
        break;
      case OutfitPattern.pocket:
        final pocket = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 38, 140, 26, 24),
          const Radius.circular(4),
        );
        canvas.drawRRect(pocket, Paint()..color = shirt.accent.withAlpha(65));
        canvas.drawRRect(
          pocket,
          Paint()
            ..color = shirt.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
        canvas.drawCircle(
          Offset(cx - 25, 143),
          1.6,
          Paint()..color = shirt.accent,
        );
        break;
      case OutfitPattern.star:
        _drawStar(canvas, Offset(cx, 158), 17, shirt.accent);
        break;
      case OutfitPattern.heart:
        _drawHeart(canvas, Offset(cx, 158), 17, shirt.accent);
        break;
      case OutfitPattern.trim:
        final trim = Paint()
          ..color = shirt.accent
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(left + 8, top + 52),
          Offset(left + 8, hem - 8),
          trim,
        );
        canvas.drawLine(
          Offset(left - 7, top + 51),
          Offset(left + 7, top + 43),
          trim,
        );
        canvas.drawLine(
          Offset(right + 7, top + 51),
          Offset(right - 7, top + 43),
          trim,
        );
        break;
    }

    // Soft fabric highlight down the left side.
    canvas.drawPath(
      Path()
        ..moveTo(left + 8, top + 16)
        ..quadraticBezierTo(left + 14, 160, left + 10, hem - 12),
      Paint()
        ..color = Colors.white.withAlpha(30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    // Hem shadow.
    canvas.drawPath(
      Path()
        ..moveTo(left + 2, hem - 7)
        ..quadraticBezierTo(cx, hem + 8, right - 2, hem - 7),
      Paint()
        ..color = _ink.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Necklace with a tiny pendant.
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, top + 2), radius: 15),
      0.15 * math.pi,
      0.70 * math.pi,
      false,
      Paint()
        ..color = _gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(Offset(cx, top + 17), 2.8, Paint()..color = shirt.accent);
  }

  void _paintHead(Canvas canvas, double cx, bool blink) {
    const cy = 72.0;
    const radius = 40.0;

    // Ears.
    for (final direction in const [-1.0, 1.0]) {
      final ear = Offset(cx + direction * 40, cy + 4);
      canvas.drawCircle(ear, 9, Paint()..color = _skin);
      canvas.drawCircle(
        ear,
        9,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        Offset(ear.dx + direction * 2, ear.dy),
        3,
        Paint()..color = _ink.withAlpha(40),
      );
    }

    // Face.
    canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = _skin);
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Hair cap.
    final hair = Path()
      ..moveTo(cx - 42, 76)
      ..cubicTo(cx - 48, 24, cx - 10, 20, cx + 4, 28)
      ..cubicTo(cx + 34, 24, cx + 46, 40, cx + 42, 76)
      ..lineTo(cx + 34, 64)
      ..quadraticBezierTo(cx + 22, 46, cx + 4, 48)
      ..quadraticBezierTo(cx - 20, 48, cx - 30, 68)
      ..close();
    canvas.drawPath(hair, Paint()..color = _hair);
    canvas.drawPath(
      hair,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Side-swept fringe and highlight.
    final fringe = Path()
      ..moveTo(cx - 32, 58)
      ..quadraticBezierTo(cx - 8, 33, cx + 26, 43)
      ..quadraticBezierTo(cx + 4, 52, cx - 16, 62)
      ..close();
    canvas.drawPath(fringe, Paint()..color = _hairLight);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: 33),
      math.pi * 1.15,
      math.pi * 0.55,
      false,
      Paint()
        ..color = const Color(0xFF8A7562).withAlpha(150)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Hair clip.
    _drawSparkle(canvas, Offset(cx + 27, 49), 5.2, shirt.accent);

    // Brows.
    final brow = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH(cx - 24, 59, 15, 7), 0.15, 2.5, false, brow);
    canvas.drawArc(Rect.fromLTWH(cx + 9, 59, 15, 7), 0.5, 2.5, false, brow);

    if (blink) {
      final closed = Paint()
        ..color = _ink
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - 21, 76), Offset(cx - 9, 76), closed);
      canvas.drawLine(Offset(cx + 9, 76), Offset(cx + 21, 76), closed);
    } else {
      for (final direction in const [-1.0, 1.0]) {
        final eye = Offset(cx + direction * 15, 76);
        canvas.drawOval(
          Rect.fromCenter(center: eye, width: 8, height: 10),
          Paint()..color = _ink,
        );
        canvas.drawCircle(
          Offset(eye.dx - 2, eye.dy - 3),
          2,
          Paint()..color = Colors.white.withAlpha(230),
        );
        canvas.drawCircle(
          Offset(eye.dx + 2, eye.dy + 2),
          1,
          Paint()..color = Colors.white.withAlpha(140),
        );
      }
    }

    // Nose.
    canvas.drawArc(
      Rect.fromLTWH(cx - 3, 83, 7, 5),
      0.2,
      2.4,
      false,
      Paint()
        ..color = _ink.withAlpha(160)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Smile.
    canvas.drawArc(
      Rect.fromLTWH(cx - 10, 88, 20, 12),
      0.15 * math.pi,
      0.70 * math.pi,
      false,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // Blush and freckles.
    for (final direction in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + direction * 25, 90),
          width: 15,
          height: 8,
        ),
        Paint()..color = const Color(0xFFE88787).withAlpha(70),
      );
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(cx + direction * (20 + i * 4), 86 + (i % 2)),
          1,
          Paint()..color = const Color(0xFFB77A5A).withAlpha(120),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DressUpFigurePainter oldDelegate) =>
      oldDelegate.shirt != shirt ||
      oldDelegate.shorts != shorts ||
      oldDelegate.idle != idle ||
      oldDelegate.sparkle != sparkle;
}

/// Tiny tee or shorts drawing for the selection cards, using the same colors
/// and print as the full-size preview.
class _GarmentIconPainter extends CustomPainter {
  _GarmentIconPainter({required this.item, required this.isShirt});

  final OutfitItem item;
  final bool isShirt;

  @override
  void paint(Canvas canvas, Size size) {
    if (isShirt) {
      _paintTee(canvas, size);
    } else {
      _paintShorts(canvas, size);
    }
  }

  void _paintTee(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final top = h * 0.16;
    final bottom = h * 0.88;
    final left = cx - w * 0.21;
    final right = cx + w * 0.21;
    final sleeve = w * 0.15;
    final body = Path()
      ..moveTo(left + 7, top)
      ..quadraticBezierTo(cx, top + 6, right - 7, top)
      ..lineTo(right, top + 4)
      ..lineTo(right + sleeve, top + 14)
      ..lineTo(right + sleeve * 0.6, top + 24)
      ..lineTo(right, top + 20)
      ..lineTo(right, bottom)
      ..quadraticBezierTo(cx, bottom + 3, left, bottom)
      ..lineTo(left, top + 20)
      ..lineTo(left - sleeve * 0.6, top + 24)
      ..lineTo(left - sleeve, top + 14)
      ..lineTo(left, top + 4)
      ..close();

    canvas.drawPath(body, Paint()..color = item.primary);
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.white.withAlpha(42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.save();
    canvas.clipPath(body);
    switch (item.pattern) {
      case OutfitPattern.solid:
        break;
      case OutfitPattern.stripe:
        canvas.drawRect(
          Rect.fromLTRB(
            left - 20,
            top + (bottom - top) * 0.34,
            right + 20,
            top + (bottom - top) * 0.46,
          ),
          Paint()..color = item.accent,
        );
        canvas.drawRect(
          Rect.fromLTRB(
            left - 20,
            top + (bottom - top) * 0.48,
            right + 20,
            top + (bottom - top) * 0.50,
          ),
          Paint()..color = Colors.white.withAlpha(120),
        );
        break;
      case OutfitPattern.pocket:
        final pocket = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx - w * 0.17,
            top + (bottom - top) * 0.30,
            w * 0.13,
            h * 0.14,
          ),
          const Radius.circular(2),
        );
        canvas.drawRRect(pocket, Paint()..color = item.accent.withAlpha(70));
        canvas.drawRRect(
          pocket,
          Paint()
            ..color = item.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        break;
      case OutfitPattern.star:
        _drawStar(
          canvas,
          Offset(cx, top + (bottom - top) * 0.42),
          w * 0.10,
          item.accent,
        );
        break;
      case OutfitPattern.heart:
        _drawHeart(
          canvas,
          Offset(cx, top + (bottom - top) * 0.42),
          w * 0.10,
          item.accent,
        );
        break;
      case OutfitPattern.trim:
        final trim = Paint()
          ..color = item.accent
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(left + 4, top + 22),
          Offset(left + 4, bottom - 5),
          trim,
        );
        canvas.drawLine(
          Offset(right - 4, top + 22),
          Offset(right - 4, bottom - 5),
          trim,
        );
        break;
    }
    canvas.restore();

    // Neck opening.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, top + 1),
        width: w * 0.14,
        height: h * 0.055,
      ),
      Paint()..color = const Color(0x66000000),
    );
  }

  void _paintShorts(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final top = h * 0.24;
    final bottom = h * 0.82;
    final left = cx - w * 0.23;
    final right = cx + w * 0.23;
    final hip = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, top + h * 0.20),
      const Radius.circular(4),
    );
    final leftLeg = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top + h * 0.14, cx - w * 0.025, bottom),
      const Radius.circular(3),
    );
    final rightLeg = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx + w * 0.025, top + h * 0.14, right, bottom),
      const Radius.circular(3),
    );
    final fill = Paint()..color = item.primary;
    final outline = Paint()
      ..color = Colors.white.withAlpha(42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final piece in [hip, leftLeg, rightLeg]) {
      canvas.drawRRect(piece, fill);
      canvas.drawRRect(piece, outline);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left + 1, top + 2, right - 1, top + h * 0.075),
        const Radius.circular(2),
      ),
      Paint()..color = item.accent.withAlpha(180),
    );

    switch (item.pattern) {
      case OutfitPattern.solid:
        break;
      case OutfitPattern.trim:
        final stripe = Paint()
          ..color = item.accent
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(left + 3, top + h * 0.16),
          Offset(left + 3, bottom - 3),
          stripe,
        );
        canvas.drawLine(
          Offset(right - 3, top + h * 0.16),
          Offset(right - 3, bottom - 3),
          stripe,
        );
        break;
      case OutfitPattern.stripe:
        canvas.save();
        canvas.clipRRect(hip);
        canvas.drawRect(
          Rect.fromLTRB(left, top + h * 0.13, right, top + h * 0.18),
          Paint()..color = item.accent,
        );
        canvas.restore();
        break;
      case OutfitPattern.pocket:
        final stitch = Paint()
          ..color = item.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawArc(
          Rect.fromLTWH(left + 2, top + h * 0.09, w * 0.13, h * 0.14),
          0.2,
          2.4,
          false,
          stitch,
        );
        canvas.drawArc(
          Rect.fromLTWH(right - w * 0.15, top + h * 0.09, w * 0.13, h * 0.14),
          0.7,
          2.4,
          false,
          stitch,
        );
        break;
      case OutfitPattern.star:
        _drawStar(
          canvas,
          Offset(cx - w * 0.12, top + h * 0.30),
          w * 0.055,
          item.accent,
        );
        break;
      case OutfitPattern.heart:
        _drawHeart(
          canvas,
          Offset(cx - w * 0.12, top + h * 0.30),
          w * 0.055,
          item.accent,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GarmentIconPainter oldDelegate) =>
      oldDelegate.item != item || oldDelegate.isShirt != isShirt;
}

void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final angle = -math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? radius : radius * 0.44;
    final point = Offset(
      center.dx + math.cos(angle) * r,
      center.dy + math.sin(angle) * r,
    );
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  canvas.drawPath(path, Paint()..color = color);
}

void _drawHeart(Canvas canvas, Offset center, double radius, Color color) {
  final path = Path()
    ..moveTo(center.dx, center.dy + radius * 0.75)
    ..cubicTo(
      center.dx - radius * 1.4,
      center.dy - radius * 0.2,
      center.dx - radius * 0.7,
      center.dy - radius * 1.05,
      center.dx,
      center.dy - radius * 0.35,
    )
    ..cubicTo(
      center.dx + radius * 0.7,
      center.dy - radius * 1.05,
      center.dx + radius * 1.4,
      center.dy - radius * 0.2,
      center.dx,
      center.dy + radius * 0.75,
    )
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}

void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
  final path = Path()
    ..moveTo(center.dx, center.dy - radius)
    ..quadraticBezierTo(
      center.dx + radius * 0.18,
      center.dy - radius * 0.18,
      center.dx + radius,
      center.dy,
    )
    ..quadraticBezierTo(
      center.dx + radius * 0.18,
      center.dy + radius * 0.18,
      center.dx,
      center.dy + radius,
    )
    ..quadraticBezierTo(
      center.dx - radius * 0.18,
      center.dy + radius * 0.18,
      center.dx - radius,
      center.dy,
    )
    ..quadraticBezierTo(
      center.dx - radius * 0.18,
      center.dy - radius * 0.18,
      center.dx,
      center.dy - radius,
    )
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}
