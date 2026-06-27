import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF386A5B)),
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );

  static final dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7ED0B4),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}
