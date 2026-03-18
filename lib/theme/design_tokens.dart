import 'package:flutter/material.dart';

class DesignTokens {
  static bool isDark = true;

  // Core palette
  static Color get bg         => isDark ? const Color(0xFF040D1A) : const Color(0xFFF1F5F9);
  static Color get surface    => isDark ? const Color(0xFF070F20) : const Color(0xFFFFFFFF);
  static Color get card       => isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC);
  static Color get cardHover  => isDark ? const Color(0xFF0D1F38) : const Color(0xFFF1F5F9);
  static Color get border     => isDark ? const Color(0x1F00E5FF) : const Color(0xFFE2E8F0);

  // Accent — electric cyan
  static const cyan       = Color(0xFF00E5FF);
  static const cyanDim    = Color(0xFF00B8D4);
  static const cyanGlow   = Color(0x3D00E5FF);

  // Status colours
  static const safe       = Color(0xFF00E676);
  static const warning    = Color(0xFFFFAB00);
  static const alert      = Color(0xFFFF1744);

  // Text
  static Color get textPrimary   => isDark ? const Color(0xFFE8F4FF) : const Color(0xFF0F172A);
  static Color get textSecondary => isDark ? const Color(0xFF6B8CAE) : const Color(0xFF475569);
  static Color get textMuted     => isDark ? const Color(0xFF3D5A78) : const Color(0xFF94A3B8);

  // Radius / spacing
  static const r8  = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));

  // Shared Painter utilities
  static Paint getGlowPaint(Color color, double t) {
    return Paint()
      ..color = color.withValues(alpha: ((1 - t) * 0.6).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
  }
}
