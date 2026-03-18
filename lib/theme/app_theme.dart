import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    // Note: We use DesignTokens getters which depend on DesignTokens.isDark.
    // To ensure accuracy, we temporarily sync isDark if needed, but 
    // usually isDark is already set by main.dart before build.
    
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
    
    // We use the tokens corresponding to the brightness
    // This is a bit tricky since tokens are static. 
    // To make this robust, we'll use conditional logic here too.
    
    final bg = isDark ? const Color(0xFF080E1A) : const Color(0xFFF1F5F9);
    final surface = isDark ? const Color(0xFF0E1825) : const Color(0xFFFFFFFF);
    final card = isDark ? const Color(0xFF111E2E) : const Color(0xFFF8FAFC);
    final text = isDark ? const Color(0xFFE8F4FF) : const Color(0xFF0F172A);
    final subtext = isDark ? const Color(0xFF6B8CAE) : const Color(0xFF475569);
    const primary = Color(0xFF00D4FF);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        surface: surface,
        onSurface: text,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.robotoMonoTextTheme(base.textTheme).apply(
        bodyColor: text,
        displayColor: text,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: subtext.withValues(alpha: 0.2),
        thickness: 1,
      ),
    );
  }
}
