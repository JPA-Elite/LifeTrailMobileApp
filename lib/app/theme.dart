import 'package:flutter/material.dart';

class LifeTrailTheme {
  static const _seed = Color(0xFF2E7D5B);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
    scaffoldBackgroundColor: const Color(0xFFF3EFE4),
    cardTheme: const CardThemeData(margin: EdgeInsets.all(8)),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
  );

  static const double padSm = 8;
  static const double padMd = 12;
  static const double padLg = 16;
  static const double radius = 12;
}
