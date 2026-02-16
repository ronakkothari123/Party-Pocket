import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KawaiiColors {
  static const Color background = Color(0xFFFFF6FB);
  static const Color primaryPink = Color(0xFFFF4FA3);
  static const Color skyBlue = Color(0xFF4CC9FF);
  static const Color sunshineYellow = Color(0xFFFFD84D);
  static const Color mintGreen = Color(0xFF4DFFA8);
  static const Color softPurple = Color(0xFFA78BFA);
  static const Color deepInk = Color(0xFF2B2B2B);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color lightPink = Color(0xFFFFD6EC);
  static const Color lightBlue = Color(0xFFD6F0FF);
  static const Color lightYellow = Color(0xFFFFF3CC);
}

class AppTheme {
  static ThemeData get theme {
    final baseTextTheme = GoogleFonts.fredokaTextTheme();

    return ThemeData(
      scaffoldBackgroundColor: KawaiiColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: KawaiiColors.primaryPink,
        surface: KawaiiColors.background,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: KawaiiColors.deepInk,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: KawaiiColors.deepInk,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: KawaiiColors.deepInk,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: KawaiiColors.deepInk,
        ),
      ),
      splashColor: KawaiiColors.primaryPink.withValues(alpha: 0.1),
      highlightColor: KawaiiColors.primaryPink.withValues(alpha: 0.05),
      useMaterial3: true,
    );
  }
}
