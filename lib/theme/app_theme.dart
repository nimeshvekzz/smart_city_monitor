import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    // Modern Neutral Palette
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surface = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final card = isDark ? const Color(0xFF334155) : const Color(0xFFFFFFFF);
    final text = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtext = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        surface: surface,
        onSurface: text,
        outline: border,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: text,
        displayColor: text,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withAlpha((255 * 0.1).toInt()),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: primary);
          }
          return GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: subtext);
        }),
      ),
    );
  }
}
