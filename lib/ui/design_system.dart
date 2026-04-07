import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFFDC800);
  static const Color primaryContainer = Color(0xFFFDC800);
  static const Color secondary = Color(0xFF432DD7);
  static const Color surface = Color(0xFFFBFBF9);
  static const Color background = Color(0xFFF6F6F5);
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFB02500);
  static const Color text = Color(0xFF1C293C);
  static const Color outline = Color(0xFF767776);
  static const Color shadow = Color(0xFF1C293C);
}

class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 56,
        fontWeight: FontWeight.w900,
        height: 1.1,
        letterSpacing: -1.12,
        color: AppColors.text,
      );

  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.64,
        color: AppColors.text,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: AppColors.text,
      );

  static TextStyle get dataLarge => GoogleFonts.jetBrainsMono(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      );

  static TextStyle get dataMedium => GoogleFonts.jetBrainsMono(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      );

  static TextStyle get labelMedium => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
      );
}

class AppDecoration {
  static BoxShadow hardShadow({Color? color}) => BoxShadow(
        color: color ?? AppColors.shadow,
        offset: const Offset(4, 4),
        blurRadius: 0,
      );

  static BoxDecoration kineticContainer({
    Color backgroundColor = Colors.white,
    double borderWidth = 3,
    bool showShadow = true,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      border: Border.all(color: AppColors.text, width: borderWidth),
      boxShadow: showShadow ? [hardShadow()] : [],
    );
  }
}
