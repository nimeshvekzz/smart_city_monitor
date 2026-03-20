import 'package:flutter/material.dart';
import 'package:smart_city_monitor/ui/theme/app_theme.dart';

class DesignTokens {
  // Core palette - Context Aware
  static Color bg(BuildContext context)      => Theme.of(context).scaffoldBackgroundColor;
  static Color surface(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color border(BuildContext context)  => Theme.of(context).colorScheme.outline;

  // Accents
  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color accent(BuildContext context)  => Theme.of(context).colorScheme.onSurfaceVariant;
  
  // Status colors - From Extensions
  static Color safe(BuildContext context)    => StatusColors.of(context).safe;
  static Color warning(BuildContext context) => StatusColors.of(context).warning;
  static Color alert(BuildContext context)   => StatusColors.of(context).alert;
  static Color neutral(BuildContext context) => StatusColors.of(context).neutral;

  // Text
  static Color textPrimary(BuildContext context)   => Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) => Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).toInt());
  static Color textMuted(BuildContext context)     => Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.4).toInt());

  // Gradients for Premium Feel
  static LinearGradient primaryGradient(BuildContext context) => LinearGradient(
    colors: [primary(context), primary(context).withAlpha((255 * 0.8).toInt())],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient surfaceGradient(BuildContext context) => LinearGradient(
    colors: [surface(context), surface(context).withAlpha((255 * 0.95).toInt())],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadows
  static List<BoxShadow> shadowLow(BuildContext context) => [
    BoxShadow(color: Colors.black.withAlpha((255 * 0.05).toInt()), blurRadius: 10, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> shadowMed(BuildContext context) => [
    BoxShadow(color: Colors.black.withAlpha((255 * 0.1).toInt()), blurRadius: 20, offset: const Offset(0, 8)),
  ];

  // Animation Durations
  static const fast   = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 300);
  static const slow   = Duration(milliseconds: 500);

  // Radius / spacing
  static const r8  = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));
}
