import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color ink = Color(0xFF0A0A0A);
  static const Color ink2 = Color(0xFF222222);
  static const Color ink3 = Color(0xFF444444);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color bg2 = Color(0xFFF4F4F4);
  static const Color bg3 = Color(0xFFEBEBEB);
  static const Color muted = Color(0xFF888888);
  static const Color border = Color(0xFFD0D0D0);
  static const Color dark = Color(0xFF0A0A0A);
  static const Color dark2 = Color(0xFF181818);
  static const Color dark3 = Color(0xFF252525);

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w900, color: ink),
      displayMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, color: ink),
      titleLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, color: ink),
      bodyLarge: GoogleFonts.jetBrainsMono(color: ink),
      bodyMedium: GoogleFonts.jetBrainsMono(color: ink),
      bodySmall: GoogleFonts.jetBrainsMono(color: muted),
      labelSmall: GoogleFonts.jetBrainsMono(color: muted, letterSpacing: 2),
    );
  }

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.light(
          primary: ink,
          secondary: ink2,
          surface: bg,
          onPrimary: bg,
          onSurface: ink,
        ),
        textTheme: _buildTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: bg,
          foregroundColor: ink,
          elevation: 0,
          titleTextStyle: GoogleFonts.jetBrainsMono(
            color: ink,
            fontSize: 11,
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
          ),
        ),
        dividerColor: border,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      );
}
