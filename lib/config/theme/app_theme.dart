import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Brand
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Accent
  static const Color accent = Color(0xFF06B6D4);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Light palette ──────────────────────────────────────
  static const Color lightBg        = Color(0xFFF4F6FF);
  static const Color lightSurface   = Color(0xFFFFFFFF);
  static const Color lightCard      = Color(0xFFFFFFFF);
  static const Color lightCardElev  = Color(0xFFF0F4FF);
  static const Color lightBorder    = Color(0xFFE4E7F5);
  static const Color lightDivider   = Color(0xFFF0F2FB);
  static const Color lightNavBg     = Color(0xFFFFFFFF);
  static const Color lightText      = Color(0xFF1E1E3F);
  static const Color lightTextSub   = Color(0xFF5C5F7A);
  static const Color lightTextMuted = Color(0xFF9395B0);

  // ── Dark palette ───────────────────────────────────────
  static const Color darkBg          = Color(0xFF0A0A0F);
  static const Color darkSurface     = Color(0xFF13131A);
  static const Color darkCard        = Color(0xFF1C1C27);
  static const Color darkCardElevated = Color(0xFF252535);
  static const Color darkBorder      = Color(0xFF2D2D3D);
  static const Color darkDivider     = Color(0xFF1E1E2E);
  static const Color textPrimary     = Color(0xFFF1F5F9);
  static const Color textSecondary   = Color(0xFF94A3B8);
  static const Color textMuted       = Color(0xFF64748B);
  static const Color textLight       = Color(0xFF1E293B);

  // Glass
  static const Color glassDark  = Color(0x1AFFFFFF);
  static const Color glassLight = Color(0x0D000000);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Priority
  static const Color priorityHigh   = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow    = Color(0xFF10B981);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF13131A), Color(0xFF0F0F1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient lightBgGradient = LinearGradient(
    colors: [Color(0xFFF4F6FF), Color(0xFFF8F9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Context-aware style helper ──────────────────────────────────────────────
class AppStyle {
  static bool _isDark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;

  static Color bg(BuildContext ctx) =>
      _isDark(ctx) ? AppColors.darkBg : AppColors.lightBg;

  static Color surface(BuildContext ctx) =>
      _isDark(ctx) ? AppColors.darkSurface : AppColors.lightSurface;

  static Color card(BuildContext ctx) =>
      _isDark(ctx) ? AppColors.darkCard : AppColors.lightCard;

  static Color cardElev(BuildContext ctx) =>
      _isDark(ctx) ? AppColors.darkCardElevated : AppColors.lightCardElev;

  static Color border(BuildContext ctx) =>
      _isDark(ctx) ? AppColors.darkBorder : AppColors.lightBorder;

  static Color divider(BuildContext ctx) =>
      _isDark(ctx) ? AppColors.darkDivider : AppColors.lightDivider;

  static Color navBg(BuildContext ctx) =>
      _isDark(ctx) ? AppColors.darkSurface : AppColors.lightNavBg;

  static Color text(BuildContext ctx) =>
      _isDark(ctx) ? AppColors.textPrimary : AppColors.lightText;

  static Color textSub(BuildContext ctx) =>
      _isDark(ctx) ? AppColors.textSecondary : AppColors.lightTextSub;

  static Color textMuted(BuildContext ctx) =>
      _isDark(ctx) ? AppColors.textMuted : AppColors.lightTextMuted;

  static Color iconColor(BuildContext ctx) =>
      _isDark(ctx) ? AppColors.textPrimary : AppColors.lightText;

  // 3D shadow for light mode, subtle for dark
  static List<BoxShadow> cardShadow(BuildContext ctx, {double opacity = 1.0}) {
    if (_isDark(ctx)) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.2 * opacity),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0x0C1E1E3F).withOpacity(opacity),
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: const Color(0x061E1E3F).withOpacity(opacity),
        blurRadius: 6,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ];
  }

  // 3D primary card (accent-colored shadow)
  static List<BoxShadow> accentShadow(BuildContext ctx, Color color) {
    if (_isDark(ctx)) {
      return [BoxShadow(color: color.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))];
    }
    return [
      BoxShadow(color: color.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 6)),
      BoxShadow(color: color.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
    ];
  }

  static BoxDecoration cardDecor(BuildContext ctx, {Color? accent, BorderRadius? radius}) {
    return BoxDecoration(
      color: card(ctx),
      borderRadius: radius ?? BorderRadius.circular(20),
      border: Border.all(color: border(ctx), width: _isDark(ctx) ? 0.5 : 0),
      boxShadow: cardShadow(ctx),
      gradient: accent != null
          ? LinearGradient(
              colors: [card(ctx), accent.withOpacity(_isDark(ctx) ? 0.05 : 0.04)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
    );
  }
}

// ─── Themes ──────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.lightSurface,
          background: AppColors.lightBg,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.lightSurface,
          background: AppColors.lightBg,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSurface: AppColors.lightText,
          onBackground: AppColors.lightText,
        ),
        scaffoldBackgroundColor: AppColors.lightBg,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.lightText,
          ),
          iconTheme: IconThemeData(color: AppColors.lightText),
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightCard,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          shadowColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15),
            shadowColor: Colors.transparent,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.lightBorder),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 14),
          labelStyle: const TextStyle(color: AppColors.lightTextSub),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.lightDivider, thickness: 1),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.lightCardElev,
          selectedColor: AppColors.primary.withOpacity(0.12),
          side: const BorderSide(color: AppColors.lightBorder),
          labelStyle: const TextStyle(color: AppColors.lightTextSub, fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.lightNavBg,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.lightTextMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.lightText, letterSpacing: -1),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.lightText, letterSpacing: -0.5),
          displaySmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.lightText),
          headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.lightText),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.lightText),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.lightText),
          titleLarge:  TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.lightText),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.lightText),
          titleSmall:  TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.lightTextSub),
          bodyLarge:   TextStyle(fontSize: 15, color: AppColors.lightText, height: 1.5),
          bodyMedium:  TextStyle(fontSize: 14, color: AppColors.lightTextSub, height: 1.5),
          bodySmall:   TextStyle(fontSize: 12, color: AppColors.lightTextMuted),
          labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.lightText),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.lightTextSub),
          labelSmall:  TextStyle(fontSize: 11, color: AppColors.lightTextMuted),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.darkSurface,
          background: AppColors.darkBg,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.darkSurface,
          background: AppColors.darkBg,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimary,
          onBackground: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.darkBg,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.darkBorder, width: 0.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkCard,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.darkBorder, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.darkBorder, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.darkDivider, thickness: 0.5),
        textTheme: const TextTheme(
          displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
          displaySmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          titleLarge:  TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          titleSmall:  TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          bodyLarge:   TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5),
          bodyMedium:  TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          bodySmall:   TextStyle(fontSize: 12, color: AppColors.textMuted),
          labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          labelSmall:  TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      );
}
