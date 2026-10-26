import 'package:flutter/material.dart';

const Color webInk = Color(0xFF060D16);
const Color webPanel = Color(0xFF0C1926);
const Color webPanelHi = Color(0xFF122736);
const Color webLine = Color(0xFF21414F);
const Color webText = Color(0xFFE9F6F4);
const Color webMuted = Color(0xFF9DB8C2);
const Color webMint = Color(0xFF5EEAD4);
const Color webAmber = Color(0xFFFFD166);
const Color webCoral = Color(0xFFFF8FA3);

/// Tracks the on-screen cursor and the widgets it can click.
///
/// Hit boxes register themselves with a stable token (their State object) and
/// a [GlobalKey]. Rectangles are resolved lazily at click time, so scrolling
/// and animated layouts stay accurate without extra bookkeeping.
class WebCursorController {
  final ValueNotifier<Offset> position = ValueNotifier(Offset.zero);
  final ValueNotifier<String?> hovered = ValueNotifier<String?>(null);

  final Map<Object, WebHit> _hits = <Object, WebHit>{};

  void register(
    Object token,
    String id,
    GlobalKey key,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    _hits[token] = WebHit(id, key, onTap, tooltip);
  }

  void unregister(Object token, String id) {
    final hit = _hits[token];
    if (hit != null && hit.id == id) _hits.remove(token);
  }

  void clear() {
    _hits.clear();
    hovered.value = null;
  }

  WebHit? hitAt(Offset global) {
    // Later registrations are painted on top, so search newest first.
    final entries = _hits.values.toList(growable: false).reversed;
    for (final hit in entries) {
      final rect = hit.rect;
      if (rect != null && rect.contains(global)) return hit;
    }
    return null;
  }

  void updateHover(Offset global) {
    final next = hitAt(global)?.id;
    if (hovered.value != next) hovered.value = next;
  }

  void clearHover() {
    if (hovered.value != null) hovered.value = null;
  }

  void dispose() {
    position.dispose();
    hovered.dispose();
  }
}

class WebHit {
  WebHit(this.id, this.key, this.onTap, this.tooltip);

  final String id;
  final GlobalKey key;
  final VoidCallback onTap;
  final String? tooltip;

  Rect? get rect {
    final context = key.currentContext;
    if (context == null) return null;
    final object = context.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return null;
    if (!object.attached) return null;
    return object.localToGlobal(Offset.zero) & object.size;
  }
}

class WebCursorScope extends InheritedWidget {
  const WebCursorScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final WebCursorController controller;

  static WebCursorController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WebCursorScope>();
    assert(scope != null, 'WebCursorScope is missing above this widget');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(WebCursorScope oldWidget) =>
      oldWidget.controller != controller;
}

/// A clickable region that highlights when the drawn cursor rests on it.
class BrowserHitBox extends StatefulWidget {
  const BrowserHitBox({
    super.key,
    required this.id,
    required this.onTap,
    required this.child,
    this.radius = 10,
    this.glowColor,
    this.hoverColor,
    this.tooltip,
  });

  final String id;
  final VoidCallback onTap;
  final Widget child;
  final double radius;
  final Color? glowColor;
  final Color? hoverColor;
  final String? tooltip;

  @override
  State<BrowserHitBox> createState() => _BrowserHitBoxState();
}

class _BrowserHitBoxState extends State<BrowserHitBox> {
  final GlobalKey _boxKey = GlobalKey();
  WebCursorController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = WebCursorScope.of(context);
    if (!identical(controller, _controller)) {
      _controller?.unregister(this, widget.id);
      _controller = controller;
      _register();
    }
  }

  @override
  void didUpdateWidget(BrowserHitBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _controller?.unregister(this, oldWidget.id);
      _register();
    } else {
      // Refresh the callback without moving this hit box to the top of the
      // registry; paint order, not rebuild order, decides who gets a click.
      _register();
    }
  }

  void _register() {
    _controller?.register(
      this,
      widget.id,
      _boxKey,
      widget.onTap,
      tooltip: widget.tooltip,
    );
  }

  @override
  void dispose() {
    _controller?.unregister(this, widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = WebCursorScope.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: controller.hovered,
      builder: (context, hoveredId, child) {
        final active = hoveredId == widget.id;
        return AnimatedContainer(
          key: _boxKey,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: active
                  ? (widget.glowColor ?? webMint).withAlpha(235)
                  : Colors.transparent,
              width: 1.2,
            ),
            color: active
                ? (widget.hoverColor ?? Colors.white).withAlpha(16)
                : Colors.transparent,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: (widget.glowColor ?? webMint).withAlpha(70),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// The arrow the player drags around the browser.
class WebCursorPainter extends CustomPainter {
  const WebCursorPainter({required this.active});

  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final tip = Offset(3, 2);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + 4.2, tip.dy + 19.4)
      ..lineTo(tip.dx + 8.1, tip.dy + 15.1)
      ..lineTo(tip.dx + 11.4, tip.dy + 22.4)
      ..lineTo(tip.dx + 14.6, tip.dy + 20.9)
      ..lineTo(tip.dx + 11.4, tip.dy + 13.9)
      ..lineTo(tip.dx + 17.6, tip.dy + 13.6)
      ..close();

    if (active) {
      canvas.drawCircle(
        tip + const Offset(8, 8),
        15,
        Paint()..color = webMint.withAlpha(30),
      );
      canvas.drawCircle(
        tip + const Offset(8, 8),
        15,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = webMint.withAlpha(120),
      );
    }

    canvas.drawPath(
      path.shift(const Offset(1.4, 1.8)),
      Paint()
        ..color = Colors.black.withAlpha(150)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF07131C),
    );
  }

  @override
  bool shouldRepaint(WebCursorPainter oldDelegate) =>
      oldDelegate.active != active;
}

/// A compact pill used for categories and tags.
class WebChip extends StatelessWidget {
  const WebChip({
    super.key,
    required this.label,
    this.color = webMint,
    this.filled = false,
    this.icon,
  });

  final String label;
  final Color color;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: filled ? color.withAlpha(38) : Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(filled ? 150 : 70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
