import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ultra-premium Harmonious Color System
  // Dark Mode - Deep space obsidian base with glowing teal and magenta accents
  static const Color darkBackground = Color(0xFF0D0E12);
  static const Color darkSurface = Color(0xFF161820);
  static const Color darkCard = Color(0xFF1E212E);
  
  static const Color primaryTeal = Color(0xFF00F2FE);
  static const Color primaryMagenta = Color(0xFF4FACFE);
  
  static const Color accentNeonGreen = Color(0xFF39FF14);
  static const Color accentNeonOrange = Color(0xFFFF5E36);
  static const Color accentNeonPurple = Color(0xFFBF55EC);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        brightness: Brightness.dark,
        primary: primaryTeal,
        secondary: primaryMagenta,
        tertiary: accentNeonPurple,
        background: darkBackground,
        surface: darkSurface,
        surfaceVariant: darkCard,
        error: accentNeonOrange,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      
      // Text styling using gorgeous Outfit google font
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white70,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: primaryTeal,
        ),
      ),

      // Glassmorphic Card Style
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),

      // Custom buttons style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ).copyWith(
          // Gradient styling handled in widgets but basic fallback here
          side: WidgetStateProperty.all(
            BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
        ),
      ),

      // Input fields (for AI Prompt input)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
        hintStyle: GoogleFonts.outfit(
          color: Colors.white38,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.outfit(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }

  // Linear Gradient helper
  static Gradient get primaryGradient => const LinearGradient(
        colors: [primaryTeal, primaryMagenta],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static Gradient get accentGradient => const LinearGradient(
        colors: [accentNeonPurple, primaryMagenta],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
