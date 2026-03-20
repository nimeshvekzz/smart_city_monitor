import 'package:flutter/material.dart';

class DesignTokens {
  static bool isDark = false;

  // Core palette - Minimal & Professional (Slate/Gray based)
  static Color get bg         => isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  static Color get surface    => isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  static Color get card       => isDark ? const Color(0xFF334155) : const Color(0xFFFFFFFF);
  static Color get cardHover  => isDark ? const Color(0xFF475569) : const Color(0xFFF1F5F9);
  static Color get border     => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  // Accents - Subtle & Professional
  static const primary    = Color(0xFF64748B); // Slate 500
  static const accent     = Color(0xFF94A3B8); // Slate 400
  static const neutral    = Color(0xFFCBD5E1); // Slate 300

  // Status colors - Softened
  static const safe       = Color(0xFF10B981); // Emerald 500
  static const warning    = Color(0xFFF59E0B); // Amber 500
  static const alert      = Color(0xFFEF4444); // Red 500

  // Text
  static Color get textPrimary   => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  static Color get textMuted     => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // Radius / spacing
  static const r8  = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));
}
