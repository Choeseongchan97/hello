import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 르냥뮤직스 색: 딸기우유 분홍 + 코코아 선 (어두운 모드는 밤하늘 코코아)
class RC {
  final Color bg, bg2, surface, ink, muted, line, accent, accentInk, butter;
  const RC({
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentInk,
    required this.butter,
  });

  static const light = RC(
    bg: Color(0xFFFFF1F0),
    bg2: Color(0xFFFFE3E6),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF4A3430),
    muted: Color(0xFF9C807A),
    line: Color(0xFFF2D2D2),
    accent: Color(0xFFFF7F9A),
    accentInk: Color(0xFFFFFFFF),
    butter: Color(0xFFFFC75F),
  );
  static const dark = RC(
    bg: Color(0xFF261C21),
    bg2: Color(0xFF33252C),
    surface: Color(0xFF382A31),
    ink: Color(0xFFFBECEA),
    muted: Color(0xFFB39A9F),
    line: Color(0xFF4E3A43),
    accent: Color(0xFFFF95AB),
    accentInk: Color(0xFF2B1A20),
    butter: Color(0xFFF4C66E),
  );

  static RC of(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? dark : light;
}

TextStyle disp(BuildContext c, double size, {Color? color}) =>
    GoogleFonts.jua(fontSize: size, color: color ?? RC.of(c).ink, height: 1.25);

TextStyle body(BuildContext c, double size, {Color? color}) =>
    GoogleFonts.gowunDodum(fontSize: size, color: color ?? RC.of(c).ink);

BoxDecoration pageGradient(BuildContext context) {
  final c = RC.of(context);
  return BoxDecoration(
    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.bg2, c.bg, c.bg]),
  );
}

ThemeData buildTheme(Brightness b) {
  final c = b == Brightness.dark ? RC.dark : RC.light;
  final base = ThemeData(
    brightness: b,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: b,
      primary: c.accent,
      onPrimary: c.accentInk,
      surface: c.surface,
      onSurface: c.ink,
    ),
    scaffoldBackgroundColor: c.bg,
  );
  return base.copyWith(
    textTheme: GoogleFonts.gowunDodumTextTheme(base.textTheme).apply(bodyColor: c.ink, displayColor: c.ink),
    iconTheme: IconThemeData(color: c.ink),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.accent,
      inactiveTrackColor: c.line,
      thumbColor: c.accent,
      overlayColor: c.accent.withAlpha(40),
      trackHeight: 6,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
      showValueIndicator: ShowValueIndicator.always,
      valueIndicatorColor: c.ink,
      valueIndicatorTextStyle: GoogleFonts.jua(color: c.bg, fontSize: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: GoogleFonts.gowunDodum(color: c.bg, fontSize: 14),
      shape: const StadiumBorder(),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.line,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.jua(fontSize: 20, color: c.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.line, width: 2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.line, width: 2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.accent, width: 2)),
      hintStyle: TextStyle(color: c.muted),
    ),
  );
}
