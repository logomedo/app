import 'package:flutter/material.dart';

/// Boje s weba (logomedo.com src/components/Tema.astro): med na papiru.
abstract final class Boje {
  static const med = Color(0xFFD48A06);
  static const medTamno = Color(0xFF9C6300);
  static const papir = Color(0xFFF8F5EF);
  static const povrsina = Color(0xFFFFFDF9);
  static const tinta = Color(0xFF1D1914);
  static const uspjeh = Color(0xFF2F7D4A);
  static const greska = Color(0xFFB3261E);
  static const papirNoc = Color(0xFF13110E);
  static const povrsinaNoc = Color(0xFF1B1814);
}

ThemeData tema(Brightness b) {
  final noc = b == Brightness.dark;
  final shema = ColorScheme.fromSeed(
    seedColor: Boje.med,
    brightness: b,
    primary: noc ? const Color(0xFFF0B03A) : Boje.medTamno,
    surface: noc ? Boje.povrsinaNoc : Boje.povrsina,
    error: noc ? const Color(0xFFFF8A80) : Boje.greska,
  );
  return ThemeData(
    colorScheme: shema,
    scaffoldBackgroundColor: noc ? Boje.papirNoc : Boje.papir,
    appBarTheme: AppBarTheme(backgroundColor: noc ? Boje.papirNoc : Boje.papir, scrolledUnderElevation: 0),
    cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}
