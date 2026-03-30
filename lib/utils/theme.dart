import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand palette (same in both modes) ────────────────────────────────────
  static const green       = Color(0xFF22C55E); // Emerald Green  – income / success
  static const teal        = Color(0xFF0E7490); // Ocean Teal     – headers / nav / charts
  static const tealLight   = Color(0xFF67C5D9); // Teal highlight
  static const red         = Color(0xFFEF4444); // Alert Red      – expense / delete / warning
  static const orange      = Color(0xFFF97316); // Warning orange – partial / overdue
  static const yellow      = Color(0xFFEAB308); // Caution yellow – reminders

  // ── Light mode ─────────────────────────────────────────────────────────────
  static const bgLight          = Color(0xFFF8FAFC); // Soft Slate
  static const surfaceLight     = Color(0xFFFFFFFF); // Pure White
  static const cardLight        = Color(0xFFFFFFFF); // Pure White cards
  static const textPrimaryLight = Color(0xFF0F172A); // Deep Navy
  static const textMutedLight   = Color(0xFF64748B); // Cool Gray
  static const borderLight      = Color(0xFFE2E8F0); // Slate-200

  // ── Dark mode ──────────────────────────────────────────────────────────────
  static const bgDark          = Color(0xFF0F172A); // Deep Navy bg
  static const surfaceDark     = Color(0xFF1E2937); // Dark surface
  static const cardDark        = Color(0xFF1E2937); // Dark cards
  static const textPrimaryDark = Color(0xFFF1F5F9); // Slate-100
  static const textMutedDark   = Color(0xFF64748B); // Cool Gray (same)
  static const borderDark      = Color(0xFF334155); // Slate-700

  // ── Gradients (theme-independent) ─────────────────────────────────────────
  static const primaryGrad = LinearGradient(
    colors: [Color(0xFF0E7490), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const greenGrad = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const tealGrad = LinearGradient(
    colors: [Color(0xFF0E7490), Color(0xFF0369A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const vaultGradLight = LinearGradient(
    colors: [Color(0xFF0E7490), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const vaultGradDark = LinearGradient(
    colors: [Color(0xFF0C1829), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Back-compat alias used widely across all screens
  static const accent      = teal;
  static const accentLight = tealLight;
  static const accentGrad  = tealGrad;
  static const vaultGrad   = vaultGradDark;
  static const cardGrad    = LinearGradient(
    colors: [Color(0xFF1E2937), Color(0xFF1A2535)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Defaults used by widgets (dark mode values kept as static const for compat)
  static const bg           = bgDark;
  static const surface      = surfaceDark;
  static const card         = cardDark;
  static const textPrimary  = textPrimaryDark;
  static const textSecondary = textMutedDark;
  static const border       = borderDark;

  // ── ThemeData builders ─────────────────────────────────────────────────────
  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    bg: bgDark, surface: surfaceDark, cardColor: cardDark,
    textPrimary: textPrimaryDark, textMuted: textMutedDark,
    border: borderDark,
    systemOverlay: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: surfaceDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    bg: bgLight, surface: surfaceLight, cardColor: cardLight,
    textPrimary: textPrimaryLight, textMuted: textMutedLight,
    border: borderLight,
    systemOverlay: SystemUiOverlayStyle(
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
        brightness == Brightness.dark
            ? ThemeData.dark().textTheme
            : ThemeData.light().textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
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
      tabBarTheme: TabBarTheme(
        labelColor: teal,
        unselectedLabelColor: textMuted,
        indicatorColor: teal,
        dividerColor: border,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF253042) : const Color(0xFFF1F5F9),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? teal : textMuted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? teal.withOpacity(0.4)
                : border),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
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
