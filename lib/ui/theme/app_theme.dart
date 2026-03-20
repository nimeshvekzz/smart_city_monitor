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
        surfaceContainer: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: text,
        displayColor: text,
      ),
      extensions: [
        StatusColors(
          safe: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
          warning: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
          alert: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
          neutral: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ],
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
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

class StatusColors extends ThemeExtension<StatusColors> {
  final Color safe;
  final Color warning;
  final Color alert;
  final Color neutral;

  StatusColors({
    required this.safe,
    required this.warning,
    required this.alert,
    required this.neutral,
  });

  @override
  StatusColors copyWith({Color? safe, Color? warning, Color? alert, Color? neutral}) {
    return StatusColors(
      safe: safe ?? this.safe,
      warning: warning ?? this.warning,
      alert: alert ?? this.alert,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      safe: Color.lerp(safe, other.safe, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      alert: Color.lerp(alert, other.alert, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }

  static StatusColors of(BuildContext context) => Theme.of(context).extension<StatusColors>()!;
}
