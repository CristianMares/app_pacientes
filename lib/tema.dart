import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Colores de la app para tema claro y oscuro
@immutable
class Paleta extends ThemeExtension<Paleta> {
  final Color fondo;
  final Color superficie;
  final Color texto;
  final Color secundario;
  final Color borde;
  final Color divisor;
  final Color campo;
  final Color suave;
  final Color primario;
  final Color sobrePrimario;
  final Color cancelado;
  final Color canceladoFondo;
  final bool oscuro;

  const Paleta({
    required this.fondo,
    required this.superficie,
    required this.texto,
    required this.secundario,
    required this.borde,
    required this.divisor,
    required this.campo,
    required this.suave,
    required this.primario,
    required this.sobrePrimario,
    required this.cancelado,
    required this.canceladoFondo,
    required this.oscuro,
  });

  static const clara = Paleta(
    fondo: Color(0xFFFFFFFF),
    superficie: Color(0xFFFFFFFF),
    texto: Color(0xFF1C2526),
    secundario: Color(0xFF5B6B6C),
    borde: Color(0xFFD5DFE0),
    divisor: Color(0xFFE8EEEE),
    campo: Color(0xFFF1F5F5),
    suave: Color(0xFFE3EFF0),
    primario: Color(0xFF0F5E63),
    sobrePrimario: Color(0xFFFFFFFF),
    cancelado: Color(0xFF8A3B2C),
    canceladoFondo: Color(0xFFF3E8E6),
    oscuro: false,
  );

  static const oscura = Paleta(
    fondo: Color(0xFF0F1516),
    superficie: Color(0xFF182122),
    texto: Color(0xFFE4ECEC),
    secundario: Color(0xFF9AACAD),
    borde: Color(0xFF2E3D3E),
    divisor: Color(0xFF223031),
    campo: Color(0xFF1C2728),
    suave: Color(0xFF163B3D),
    primario: Color(0xFF5CC0C6),
    sobrePrimario: Color(0xFF062426),
    cancelado: Color(0xFFF2A391),
    canceladoFondo: Color(0xFF3A2320),
    oscuro: true,
  );

  @override
  Paleta copyWith() => this;

  @override
  Paleta lerp(ThemeExtension<Paleta>? other, double t) =>
      other is Paleta && t >= 0.5 ? other : this;
}

extension PaletaContexto on BuildContext {
  Paleta get paleta => Theme.of(this).extension<Paleta>()!;
}

// fuentesGoogle = false solo para las capturas de prueba
ThemeData crearTema(Brightness brillo, {bool fuentesGoogle = true}) {
  final p = brillo == Brightness.dark ? Paleta.oscura : Paleta.clara;
  final radio = BorderRadius.circular(10);

  final esquema = ColorScheme.fromSeed(
    seedColor: p.primario,
    brightness: brillo,
  ).copyWith(
    primary: p.primario,
    onPrimary: p.sobrePrimario,
    surface: p.superficie,
    onSurface: p.texto,
    onSurfaceVariant: p.secundario,
    outline: p.borde,
    outlineVariant: p.divisor,
    error: p.cancelado,
    surfaceContainerLowest: p.fondo,
    surfaceContainerLow: p.superficie,
    surfaceContainer: p.superficie,
    surfaceContainerHigh: p.superficie,
    surfaceContainerHighest: p.campo,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brillo,
    colorScheme: esquema,
    scaffoldBackgroundColor: p.fondo,
    extensions: [p],
  );

  final barraEstado = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: p.oscuro ? Brightness.light : Brightness.dark,
    statusBarBrightness: brillo,
    systemNavigationBarColor: p.fondo,
    systemNavigationBarIconBrightness: p.oscuro ? Brightness.light : Brightness.dark,
  );

  final textos = (fuentesGoogle
          ? GoogleFonts.interTextTheme(base.textTheme)
          : base.textTheme.apply(fontFamily: 'Inter'))
      .apply(bodyColor: p.texto, displayColor: p.texto);
  // Los estilos que se definen a mano también llevan la fuente de la app
  TextStyle estilo(TextStyle t) =>
      fuentesGoogle ? GoogleFonts.inter(textStyle: t) : t.copyWith(fontFamily: 'Inter');

  return base.copyWith(
    textTheme: textos,
    iconTheme: IconThemeData(color: p.texto),
    appBarTheme: AppBarTheme(
      backgroundColor: p.fondo,
      foregroundColor: p.texto,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: barraEstado,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.campo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: radio, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: radio, borderSide: BorderSide.none),
      disabledBorder: OutlineInputBorder(borderRadius: radio, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: radio, borderSide: BorderSide(color: p.primario, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: radio, borderSide: BorderSide(color: p.cancelado)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: radio, borderSide: BorderSide(color: p.cancelado, width: 1.5)),
      labelStyle: estilo(TextStyle(color: p.secundario)),
      floatingLabelStyle: estilo(TextStyle(color: p.primario)),
      hintStyle: estilo(TextStyle(color: p.secundario)),
      suffixStyle: estilo(TextStyle(color: p.secundario)),
      prefixIconColor: p.secundario,
      suffixIconColor: p.secundario,
      errorStyle: estilo(TextStyle(color: p.cancelado)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.primario,
      selectionColor: p.primario.withValues(alpha: 0.3),
      selectionHandleColor: p.primario,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primario,
        foregroundColor: p.sobrePrimario,
        disabledBackgroundColor: p.borde,
        disabledForegroundColor: p.secundario,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: estilo(TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.texto,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: p.borde),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: estilo(TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.primario),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.primario,
      foregroundColor: p.sobrePrimario,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primario),
    dialogTheme: DialogThemeData(
      backgroundColor: p.superficie,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: estilo(TextStyle(color: p.texto, fontSize: 18, fontWeight: FontWeight.w700)),
      contentTextStyle: estilo(TextStyle(color: p.secundario, fontSize: 15, height: 1.4)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.superficie,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: p.superficie,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.superficie,
      surfaceTintColor: Colors.transparent,
      textStyle: estilo(TextStyle(color: p.texto, fontSize: 15)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.borde),
      ),
    ),
    listTileTheme: ListTileThemeData(textColor: p.texto, iconColor: p.primario),
    dividerTheme: DividerThemeData(color: p.divisor, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.oscuro ? const Color(0xFFE4ECEC) : const Color(0xFF1C2526),
      contentTextStyle: estilo(TextStyle(color: p.oscuro ? const Color(0xFF1C2526) : Colors.white)),
      actionTextColor: p.oscuro ? Paleta.clara.primario : Paleta.oscura.primario,
    ),
  );
}
