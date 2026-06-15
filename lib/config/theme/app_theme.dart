import 'package:flutter/material.dart';

class C {
  static const primary = Color(0xFF5C6BC0);
  static const primaryDark = Color(0xFF3949AB);
  static const bg = Color(0xFFF5F6FA);
  static const white = Colors.white;
  static const text = Color(0xFF1A1A2E);
  static const textSub = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const card = Colors.white;
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(seedColor: C.primary, brightness: Brightness.light),
    scaffoldBackgroundColor: C.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: C.text,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18, color: C.text),
    ),
    cardTheme: CardThemeData(
      color: Colors.white, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: C.border)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.error)),
      labelStyle: const TextStyle(color: C.textSub, fontFamily: 'Inter', fontSize: 14),
      hintStyle: const TextStyle(color: C.textMuted, fontFamily: 'Inter', fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: C.primary, foregroundColor: Colors.white,
        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.primary, side: const BorderSide(color: C.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: C.text, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
      headlineMedium: TextStyle(color: C.text, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
      titleLarge: TextStyle(color: C.text, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
      titleMedium: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
      bodyLarge: TextStyle(color: C.text, fontFamily: 'Inter'),
      bodyMedium: TextStyle(color: C.text, fontFamily: 'Inter'),
      bodySmall: TextStyle(color: C.textSub, fontFamily: 'Inter'),
    ),
  );
}
