import 'package:flutter/material.dart';

/// Shared visual language for the in-game phone apps: midnight glass,
/// warm cream type, soft neon accents and a compact phone-first layout that
/// still breathes on a landscape handset.
const Color kPhoneBg = Color(0xFF0A0E15);
const Color kPhonePanel = Color(0xFF141B26);
const Color kPhonePanelSoft = Color(0xFF1B2432);
const Color kPhoneInk = Color(0xFFF3EEE2);
const Color kPhoneMuted = Color(0xFF94A2B8);
const Color kPhoneGreen = Color(0xFF7BD88F);
const Color kPhoneBlue = Color(0xFF6FA8FF);
const Color kPhonePurple = Color(0xFFB79CFF);
const Color kPhoneAmber = Color(0xFFFFC46B);
const Color kPhoneRose = Color(0xFFFF8FA3);
const Color kPhoneCream = Color(0xFFFBF3E2);

/// Full-screen shell used by every phone app. Content is capped to a phone
/// width and centred so the apps still look like apps on a tablet.
class PhoneAppScaffold extends StatelessWidget {
  const PhoneAppScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    this.subtitle,
    this.actions = const [],
    this.body,
    this.child,
    this.padding = const EdgeInsets.fromLTRB(14, 6, 14, 12),
    this.showBack = true,
  }) : assert(body == null || child == null);

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final List<Widget> actions;
  final Widget? body;
  final Widget? child;
  final EdgeInsets padding;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPhoneBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF111927), kPhoneBg, Color(0xFF0C1119)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      title: title,
                      subtitle: subtitle,
                      icon: icon,
                      accent: accent,
                      actions: actions,
                      showBack: showBack,
                    ),
                    const SizedBox(height: 10),
                    Expanded(child: child ?? body ?? const SizedBox.shrink()),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.actions,
    required this.showBack,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final List<Widget> actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.06),
            ),
            icon: const Icon(Icons.arrow_back_rounded, color: kPhoneInk),
          ),
        if (showBack) const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent, accent.withValues(alpha: 0.55)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF0A0E15), size: 22),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kPhoneInk,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kPhoneMuted, fontSize: 11.5),
                ),
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

/// Rounded glass card used for list rows, stat blocks and settings.
class PhoneCard extends StatelessWidget {
  const PhoneCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = kPhonePanel,
    this.borderColor,
    this.onTap,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.055),
        ),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

/// Circular initials avatar with a deterministic warm gradient.
class PhoneAvatar extends StatelessWidget {
  const PhoneAvatar({
    super.key,
    required this.name,
    this.size = 46,
    this.ring = false,
  });

  final String name;
  final double size;
  final bool ring;

  static const _palettes = [
    [Color(0xFF6FA8FF), Color(0xFF3D6BB3)],
    [Color(0xFFFFA26B), Color(0xFFB85B38)],
    [Color(0xFFB79CFF), Color(0xFF6D55B8)],
    [Color(0xFF7BD88F), Color(0xFF3C8A5D)],
    [Color(0xFFFF8FA3), Color(0xFFB94F68)],
    [Color(0xFF6FD8D2), Color(0xFF2F8F8A)],
  ];

  @override
  Widget build(BuildContext context) {
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    final palette = _palettes[hash % _palettes.length];
    final initials = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
        border: ring
            ? Border.all(
                color: kPhoneCream.withValues(alpha: 0.65),
                width: 2,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Small tinted status chip (online, view-only, unread counts...).
class PhonePill extends StatelessWidget {
  const PhonePill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: dense ? 10 : 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly placeholder for empty lists.
class PhoneEmptyState extends StatelessWidget {
  const PhoneEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.accent = kPhoneMuted,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: accent, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kPhoneInk,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kPhoneMuted,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Human-readable place name for NPC whereabouts.
String friendlyLocation(String id) => switch (id) {
  'workplace' => 'Sunbeam Café',
  'pizzahut' => 'Pizza Hut',
  'bookstore' => 'Book Store',
  'supermarket' => 'Super Market',
  'repair' => 'Fix-It Repair',
  'police' => 'Police Station',
  'computer' => 'Computer Center',
  'home' => 'Home',
  'school' => 'School',
  'plaza' => 'Plaza',
  'church' => 'Church',
  'park' => 'Park',
  'bank' => 'First Bank',
  'mall' => 'Grand Mall',
  'hospital' => 'Hospital',
  'restaurant' => 'Restaurant',
  'laundry' => 'Laundry Shop',
  'amusement' => 'Amusement Park',
  'beach' => 'Beach',
  'fishing' => 'Fishing Area',
  'hotel' => 'Hotel',
  _ => id,
};

/// Themed text field for logins, search and chat.
InputDecoration phoneFieldDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
  Color accent = kPhoneBlue,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: kPhoneMuted.withValues(alpha: 0.8)),
    prefixIcon: Icon(icon, color: kPhoneMuted, size: 19),
    suffixIcon: suffix,
    filled: true,
    fillColor: kPhonePanelSoft,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: accent.withValues(alpha: 0.75)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: kPhoneRose),
    ),
    errorStyle: const TextStyle(color: kPhoneRose, fontSize: 11),
  );
}

/// Standard filled action button used inside the apps.
class PhoneButton extends StatelessWidget {
  const PhoneButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = kPhoneGreen,
    this.expand = true,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool expand;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: const Color(0xFF07110B),
        disabledBackgroundColor: color.withValues(alpha: 0.2),
        disabledForegroundColor: kPhoneMuted,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
