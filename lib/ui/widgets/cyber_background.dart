import 'package:flutter/material.dart';
import 'package:smart_city_monitor/ui/theme/design_tokens.dart';

class CyberBackground extends StatelessWidget {
  const CyberBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignTokens.bg(context),
                DesignTokens.surface(context),
                DesignTokens.bg(context),
              ],
            ),
          ),
        ),
        // Decorative circles
        Positioned(
          top: -100,
          right: -100,
          child: _CircularDecorator(
            size: 300,
            color: DesignTokens.primary(context).withAlpha((255 * 0.05).toInt()),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: _CircularDecorator(
            size: 400,
            color: DesignTokens.primary(context).withAlpha((255 * 0.03).toInt()),
          ),
        ),
        // Grid pattern overlay
        Opacity(
          opacity: 0.05,
          child: CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(DesignTokens.primary(context)),
          ),
        ),
      ],
    );
  }
}

class _CircularDecorator extends StatelessWidget {
  final double size;
  final Color color;

  const _CircularDecorator({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
