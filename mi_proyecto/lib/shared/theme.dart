import 'package:flutter/material.dart';

ThemeData buildTheme() {
  const seed = Color(0xFF0E4A7C);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}
