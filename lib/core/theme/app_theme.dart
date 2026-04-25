import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 84,
          fontWeight: FontWeight.w100,
          color: Colors.white,
          letterSpacing: -2,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 64,
          fontWeight: FontWeight.w200,
          color: Colors.white,
          letterSpacing: -1.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          letterSpacing: 4,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
          letterSpacing: 2,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 18,
          height: 1.6,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          height: 1.5,
          color: Colors.white70,
        ),
      ),
    );
  }
}
