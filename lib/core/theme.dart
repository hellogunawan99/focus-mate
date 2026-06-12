import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand colors and design tokens. The "deep focus" identity — calm
/// midnight-indigo background with a warm amber accent that signals
/// "stay sharp".
class BrandColors {
  // Deep, slightly violet-indigo background — feels serious, late-night,
  // cognitively engaging. Not the generic SaaS blue.
  static const Color bg = Color(0xFF0B0E1A);
  static const Color surface = Color(0xFF141828);
  static const Color surfaceHigh = Color(0xFF1E2238);
  static const Color outline = Color(0xFF2A2F47);

  // Accents
  static const Color amber = Color(0xFFFFB547); // primary accent — warm
  static const Color amberDeep = Color(0xFFFF8A3D);
  static const Color mint = Color(0xFF6FFFB0); // success / "focusing"
  static const Color coral = Color(0xFFFF6F6F); // destructive / wrong
  static const Color lilac = Color(0xFFB57BFF); // secondary accent
  static const Color text = Color(0xFFF1F2F8);
  static const Color textMuted = Color(0xFF8A91B0);
}

class AppTheme {
  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: BrandColors.amber,
      onPrimary: Colors.black,
      secondary: BrandColors.lilac,
      onSecondary: Colors.black,
      surface: BrandColors.surface,
      onSurface: BrandColors.text,
      error: BrandColors.coral,
      onError: Colors.black,
    );

    // Plus Jakarta Sans — modern, slightly geometric, used by Linear,
    // Notion, and a lot of "productivity app" branding. Pair with
    // JetBrains Mono for numerics.
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 96,
        fontWeight: FontWeight.w300,
        letterSpacing: -3,
        height: 1,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 56,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.5,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: BrandColors.textMuted,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: BrandColors.textMuted,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: BrandColors.textMuted,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: BrandColors.textMuted,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: BrandColors.bg,
      canvasColor: BrandColors.bg,
      cardColor: BrandColors.surface,
      dividerColor: BrandColors.outline,
      textTheme: textTheme.copyWith(
        // Mono variant for numerics — the big "60" counter uses this.
        bodyLarge: GoogleFonts.jetBrainsMono(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: BrandColors.text,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: BrandColors.bg,
        foregroundColor: BrandColors.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: BrandColors.text,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BrandColors.amber,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.text,
          side: const BorderSide(color: BrandColors.outline, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: BrandColors.amber),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: BrandColors.amber,
        inactiveTrackColor: BrandColors.outline,
        thumbColor: BrandColors.amber,
        overlayColor: BrandColors.amber.withValues(alpha: 0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.surfaceHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BrandColors.amber, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: BrandColors.textMuted.withValues(alpha: 0.6),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? BrandColors.amber
              : BrandColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? BrandColors.amber.withValues(alpha: 0.4)
              : BrandColors.surfaceHigh,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: BrandColors.textMuted,
        textColor: BrandColors.text,
        tileColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BrandColors.surface,
        modalBackgroundColor: BrandColors.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BrandColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: BrandColors.text,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: BrandColors.textMuted,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BrandColors.surfaceHigh,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: BrandColors.text,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: <ThemeExtension<dynamic>>[
        // Reserved for custom tokens.
      ],
    );
  }
}

/// Reusable decoration tokens.
class AppDecorations {
  static BoxDecoration glassCard = BoxDecoration(
    color: BrandColors.surface.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: BrandColors.outline.withValues(alpha: 0.5)),
  );

  static BoxDecoration card = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A1F36), Color(0xFF141828)],
    ),
    borderRadius: BorderRadius.all(Radius.circular(24)),
    border: Border.fromBorderSide(
      BorderSide(color: BrandColors.outline, width: 1),
    ),
  );
}
