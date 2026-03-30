import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── BEST COLOR PALETTE (Based on your screenshot analysis) ──────────────────────────────────────────────
  // Analysis of your current UI:
  // ✅ Total Balance card = vibrant bright blue (perfect trust color)
  // ✅ Income/You receive = green (good)
  // ✅ Expense/You owe = red-orange tones (needs polish)
  // ✅ Bottom nav + button & active Home = bright cyan-blue
  // ❌ Due & Owe gradients = slightly harsh/stark (the "disgusting" part)
  // ❌ Overall gradients had too much hue shift before
  //
  // SOLUTION: 
  // • Teal = exact bright sky-blue to match your Total Balance + bottom nav perfectly
  // • Green = fresh emerald for all positive elements
  // • Coral = clean red for expense/owe (no more orange clash)
  // • ALL GRADIENTS = ultra-smooth mono-hue (almost flat but with premium depth)
  // • No more color clashes. Looks modern, premium & clean like top finance apps.
  // • ZERO breaking changes — just replace the file. Your other code stays untouched.

  static const green       = Color(0xFF10B981); // Fresh Emerald – income / receive
  static const teal        = Color(0xFF06B6D4); // Bright Sky Blue – exactly matches your Total Balance card & bottom nav
  static const coral       = Color(0xFFEF4444); // Clean Red – expense / owe / negative
  static const gold        = Color(0xFFFBBF24); // Warm Gold – highlights (kept)

  static const red         = Color(0xFFEF4444);
  static const orange      = Color(0xFFF97316);
  static const yellow      = Color(0xFFEAB308);

  // ── Light mode (unchanged – already perfect) ───────────────────────────────────────────────────────────
  static const bgLight          = Color(0xFFF8FAFC);
  static const surfaceLight     = Color(0xFFFFFFFF);
  static const cardLight        = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF0F172A);
  static const textMutedLight   = Color(0xFF64748B);
  static const borderLight      = Color(0xFFE2E8F0);

  // ── Dark mode (unchanged – already perfect) ────────────────────────────────────────────────────────────
  static const bgDark          = Color(0xFF0B1220);
  static const surfaceDark     = Color(0xFF151E2E);
  static const cardDark        = Color(0xFF1E2937);
  static const textPrimaryDark = Color(0xFFF1F5F9);
  static const textMutedDark   = Color(0xFF64748B);
  static const borderDark      = Color(0xFF334155);

  // ── GRADIENTS (NOW PERFECT – ultra smooth, no disgusting clashes) ─────────────────────
  // All gradients are now same-hue only with tiny brightness difference → premium & subtle
  static const primaryGrad = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)], // Bright Sky → Soft Cyan (matches your balance card perfectly)
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const greenGrad = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)], // Emerald → Light Emerald (smooth & fresh for "You receive")
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const tealGrad = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)], // Same as primary (consistent)
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const redGrad = LinearGradient(  // NEW – smooth red for "You owe"
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const vaultGradLight = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)], // Pure neutral light
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const vaultGradDark = LinearGradient(
    colors: [Color(0xFF0B1220), Color(0xFF151E2E)], // Pure neutral dark
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Back-compat aliases (UNCHANGED – your other code works instantly)
  static const accent      = teal;
  static const accentLight = coral;
  static const accentGrad  = tealGrad;
  static const vaultGrad   = vaultGradDark;
  static const cardGrad    = LinearGradient(
    colors: [Color(0xFF1E2937), Color(0xFF162032)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Defaults (unchanged)
  static const bg           = bgDark;
  static const surface      = surfaceDark;
  static const card         = cardDark;
  static const textPrimary  = textPrimaryDark;
  static const textSecondary = textMutedDark;
  static const border       = borderDark;

  // ── ThemeData builders (UNCHANGED STRUCTURE) ────────────────────────────
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
        tertiary: coral,
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