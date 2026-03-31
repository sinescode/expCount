import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand colors ────────────────────────────────────────────────────────
  static const green  = Color(0xFF10B981); // Emerald – income / positive
  static const teal   = Color(0xFF06B6D4); // Sky Blue – primary / nav / headers
  static const red    = Color(0xFFEF4444); // Clean Red – expense / negative / delete
  static const orange = Color(0xFFF97316); // Orange – overdue / partial
  static const yellow = Color(0xFFFBBF24); // Gold – reminders / caution

  // Aliases kept for backward compat across all screens
  static const coral       = red;
  static const gold        = yellow;
  static const accent      = teal;
  static const accentLight = Color(0xFF67E8F9); // Sky-200 – subtle teal highlight

  // ── Light mode ──────────────────────────────────────────────────────────
  static const bgLight          = Color(0xFFF8FAFC);
  static const surfaceLight     = Color(0xFFFFFFFF);
  static const cardLight        = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF0F172A);
  static const textMutedLight   = Color(0xFF64748B);
  static const borderLight      = Color(0xFFE2E8F0);

  // ── Dark mode ────────────────────────────────────────────────────────────
  static const bgDark          = Color(0xFF0B1220);
  static const surfaceDark     = Color(0xFF151E2E);
  static const cardDark        = Color(0xFF1C2A3A);
  static const textPrimaryDark = Color(0xFFF1F5F9);
  static const textMutedDark   = Color(0xFF64748B);
  static const borderDark      = Color(0xFF263348);

  // Static defaults (dark values — widgets read live context for light mode)
  static const bg            = bgDark;
  static const surface       = surfaceDark;
  static const card          = cardDark;
  static const textPrimary   = textPrimaryDark;
  static const textSecondary = textMutedDark;
  static const border        = borderDark;

  // ── Gradients ────────────────────────────────────────────────────────────
  // Rule: same hue family, light→dark shift only, max 20% brightness delta

  /// Primary action gradient — Sky Blue family
  static const primaryGrad = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Alias used by buttons, FAB, bottom nav
  static const tealGrad    = primaryGrad;
  static const accentGrad  = primaryGrad;

  /// Income / positive — Emerald family
  static const greenGrad = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Expense / negative — Red family
  static const redGrad = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dark card surface gradient — very subtle depth only
  static const cardGrad = LinearGradient(
    colors: [Color(0xFF1C2A3A), Color(0xFF172233)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Vault background — near-black, no color cast
  static const vaultGrad = LinearGradient(
    colors: [Color(0xFF0B1220), Color(0xFF0F1A2B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const vaultGradLight = LinearGradient(
    colors: [Color(0xFFF0F9FF), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const vaultGradDark = vaultGrad;

  // ── Subtle tinted surface overlays (replaces clashing 2-color gradients) ─
  // Use these as card backgrounds for income/expense summary tiles.
  // A single flat color with low opacity looks far better than 2 conflicting colors.
  static Color incomeCardBg(bool isDark) =>
      isDark ? const Color(0xFF0D2118) : const Color(0xFFECFDF5);

  static Color expenseCardBg(bool isDark) =>
      isDark ? const Color(0xFF200D0D) : const Color(0xFFFEF2F2);

  static Color pathCardBg(bool isDark) =>
      isDark ? const Color(0xFF0D1A25) : const Color(0xFFEFF6FF);

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    bg: bgDark, surface: surfaceDark, cardColor: cardDark,
    textPrimary: textPrimaryDark, textMuted: textMutedDark, border: borderDark,
    systemOverlay: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: surfaceDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    bg: bgLight, surface: surfaceLight, cardColor: cardLight,
    textPrimary: textPrimaryLight, textMuted: textMutedLight, border: borderLight,
    systemOverlay: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: surfaceLight,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color cardColor,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
    required SystemUiOverlayStyle systemOverlay,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: teal,
        onPrimary: Colors.white,
        secondary: green,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: red,
        onError: Colors.white,
        tertiary: orange,
        onTertiary: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
            color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700,
            fontFamily: GoogleFonts.inter().fontFamily),
        systemOverlayStyle: systemOverlay,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: teal,
        unselectedLabelColor: textMuted,
        indicatorColor: teal,
        dividerColor: border,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A2535) : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: teal, width: 1.5)),
        labelStyle: TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted),
        prefixIconColor: textMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? teal : textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? teal.withOpacity(0.35) : border),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
    );
  }
}
