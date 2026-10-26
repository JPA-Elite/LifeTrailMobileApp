import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color webInk = Color(0xFF060D16);
const Color webPanel = Color(0xFF0C1926);
const Color webPanelHi = Color(0xFF122736);
const Color webLine = Color(0xFF21414F);
const Color webText = Color(0xFFE9F6F4);
const Color webMuted = Color(0xFF9DB8C2);
const Color webMint = Color(0xFF5EEAD4);
const Color webAmber = Color(0xFFFFD166);
const Color webCoral = Color(0xFFFF8FA3);

/// A tap target used for every link, card, chip, and toolbar button.
///
/// The browser is driven by touch: tapping fires [onTap] directly, and
/// dragging still scrolls the page because the tap recognizer steps aside as
/// soon as the finger starts to move. Pressed and hovered targets glow.
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
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = _pressed || _hovered;
    final glow = widget.glowColor ?? webMint;
    return Semantics(
      identifier: widget.id,
      label: widget.tooltip,
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(
                color: active ? glow.withAlpha(235) : Colors.transparent,
                width: 1.2,
              ),
              color: active
                  ? (widget.hoverColor ?? Colors.white).withAlpha(16)
                  : Colors.transparent,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: glow.withAlpha(70),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
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
