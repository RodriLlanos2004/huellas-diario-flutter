import 'package:flutter/material.dart';

/// Tema Material 3 de Huellas, claro y oscuro, generado a partir de un color semilla.
abstract final class TemaHuellas {
  static const semilla = Color(0xFF00796B);

  static ThemeData claro() => _construir(Brightness.light);
  static ThemeData oscuro() => _construir(Brightness.dark);

  static ThemeData _construir(Brightness brillo) {
    final esquema = ColorScheme.fromSeed(seedColor: semilla, brightness: brillo);
    return ThemeData(
      colorScheme: esquema,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: esquema.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: esquema.surfaceContainerLowest,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
