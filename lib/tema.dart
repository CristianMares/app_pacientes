import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Colores {
  static const primario = Color(0xFF0F5E63);
  static const texto = Color(0xFF1C2526);
  static const secundario = Color(0xFF5B6B6C);
  static const borde = Color(0xFFD5DFE0);
  static const divisor = Color(0xFFE8EEEE);
  static const campo = Color(0xFFF1F5F5);
  static const suave = Color(0xFFE3EFF0);
  static const cancelado = Color(0xFF8A3B2C);
  static const canceladoFondo = Color(0xFFF3E8E6);
}

ThemeData crearTema() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colores.primario,
      primary: Colores.primario,
      surface: Colors.white,
      onSurface: Colores.texto,
    ),
    scaffoldBackgroundColor: Colors.white,
  );

  final radio = BorderRadius.circular(10);

  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: Colores.texto,
      displayColor: Colores.texto,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colores.texto,
      surfaceTintColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colores.campo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: radio, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: radio, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: radio, borderSide: const BorderSide(color: Colores.primario, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: radio, borderSide: const BorderSide(color: Colores.cancelado)),
      labelStyle: const TextStyle(color: Colores.secundario),
      hintStyle: const TextStyle(color: Colores.secundario),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colores.primario,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colores.texto,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: Colores.borde),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Colores.divisor, thickness: 1, space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
