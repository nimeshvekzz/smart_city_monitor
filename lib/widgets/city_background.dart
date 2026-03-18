import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/sensor_node.dart';
import '../services/data_service.dart';
import '../theme/design_tokens.dart';

class CityBackground extends StatefulWidget {
  final List<SensorNode> nodes;
  const CityBackground({super.key, required this.nodes});

  @override
  State<CityBackground> createState() => _CityBackgroundState();
}

class _CityBackgroundState extends State<CityBackground> with TickerProviderStateMixin {
  late final AnimationController _cityCtrl;
  late final AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();
    _cityCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── 3-D City background (Dimmed & Blurred)
        Positioned.fill(
          child: Opacity(
            opacity: 0.6,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: AnimatedBuilder(
                animation: _cityCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _CitySkylinePainter(_cityCtrl, widget.nodes),
                ),
              ),
            ),
          ),
        ),

        // ── Scan line
        Positioned.fill(
          child: CustomPaint(painter: _ScanLinePainter(_scanCtrl)),
        ),

        // ── Vignette overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    DesignTokens.bg.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CitySkylinePainter extends CustomPainter {
  final Animation<double> anim;
  final List<SensorNode> nodes;
  _CitySkylinePainter(this.anim, this.nodes) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final t  = anim.value;
    final rng = math.Random(42);

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF010812),
          DesignTokens.bg,
          const Color(0xFF071428),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (int i = 0; i < 60; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * size.height * 0.5;
      final sr = (rng.nextDouble() * 1.2 + 0.3);
      final twinkle = (0.4 + 0.6 * math.sin(t * math.pi * 2 + i * 0.7)).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(sx, sy), sr, starPaint..color = Colors.white.withValues(alpha: twinkle * 0.4));
    }

    const int bCount = 14;
    final bw = size.width / bCount;
    for (int i = 0; i < bCount; i++) {
      final h   = 60.0 + rng.nextDouble() * (size.height * 0.55);
      final w   = bw * 0.55 + rng.nextDouble() * bw * 0.3;
      final x   = i * bw + (bw - w) / 2;
      final y   = size.height - h;

      final statusIdx = i % (nodes.isEmpty ? 3 : nodes.length);
      final status = nodes.isEmpty ? SensorStatus.safe : nodes[statusIdx].overallStatus;
      final buildingColor = switch (status) {
        SensorStatus.safe    => DesignTokens.safe,
        SensorStatus.warning => DesignTokens.warning,
        SensorStatus.alert   => DesignTokens.alert,
      };

      final depth = w * 0.22;
      final sidePath = Path()
        ..moveTo(x + w, y)
        ..lineTo(x + w + depth, y - depth * 0.4)
        ..lineTo(x + w + depth, size.height - depth * 0.4)
        ..lineTo(x + w, size.height)
        ..close();
      canvas.drawPath(sidePath, Paint()..color = buildingColor.withValues(alpha: 0.04));

      final topPath = Path()
        ..moveTo(x, y)
        ..lineTo(x + depth, y - depth * 0.4)
        ..lineTo(x + w + depth, y - depth * 0.4)
        ..lineTo(x + w, y)
        ..close();
      canvas.drawPath(topPath, Paint()..color = buildingColor.withValues(alpha: 0.08));

      final frontGrad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          buildingColor.withValues(alpha: 0.12),
          buildingColor.withValues(alpha: 0.03),
          const Color(0xFF070F20).withValues(alpha: 0.6),
        ],
      );
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), Paint()..shader = frontGrad.createShader(Rect.fromLTWH(x, y, w, h)));

      final edgePaint = Paint()..color = buildingColor.withValues(alpha: 0.15)..strokeWidth = 0.6;
      canvas.drawLine(Offset(x, y), Offset(x, size.height), edgePaint);
      canvas.drawLine(Offset(x + w, y), Offset(x + w, size.height), edgePaint);
      canvas.drawLine(Offset(x, y), Offset(x + w, y), edgePaint);

      const wCols = 3;
      const wRows = 6;
      final wColW = w / (wCols + 1);
      final wRowH = h / (wRows + 1);
      for (int wr = 0; wr < wRows; wr++) {
        for (int wc = 0; wc < wCols; wc++) {
          final wx = x + wColW * (wc + 0.5);
          final wy = y + wRowH * (wr + 0.7);
          final litChance = math.sin(t * math.pi * 2 + i * 0.4 + wr * 0.3 + wc * 0.5);
          if (litChance > 0.0) {
            canvas.drawRect(Rect.fromLTWH(wx, wy, wColW * 0.45, wRowH * 0.5), 
              Paint()..color = buildingColor.withValues(alpha: 0.25));
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CitySkylinePainter old) => false;
}

class _ScanLinePainter extends CustomPainter {
  final Animation<double> anim;
  _ScanLinePainter(this.anim) : super(repaint: anim);
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * anim.value;
    final rect = Rect.fromLTWH(0, y - 28, size.width, 56);
    canvas.drawRect(rect, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Colors.transparent, DesignTokens.cyan.withValues(alpha: 0.04), DesignTokens.cyan.withValues(alpha: 0.1), DesignTokens.cyan.withValues(alpha: 0.04), Colors.transparent],
    ).createShader(rect));
  }
  @override
  bool shouldRepaint(_) => false;
}

class PulseRingPainter extends CustomPainter {
  final Animation<double> anim;
  final Color color;
  PulseRingPainter(this.anim, this.color) : super(repaint: anim);
  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), (size.width / 2) * (0.55 + t * 0.45),
      Paint()..color = color.withValues(alpha: ((1 - t) * 0.7).clamp(0.0, 1.0))..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }
  @override
  bool shouldRepaint(PulseRingPainter old) => old.color != color;
}

class CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = DesignTokens.cyan.withValues(alpha: 0.5)..strokeWidth = 1.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    const l = 20.0;
    canvas.drawLine(Offset.zero, const Offset(l, 0), p); canvas.drawLine(Offset.zero, const Offset(0, l), p);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - l, 0), p); canvas.drawLine(Offset(size.width, 0), Offset(size.width, l), p);
    canvas.drawLine(Offset(0, size.height), Offset(l, size.height), p); canvas.drawLine(Offset(0, size.height), Offset(0, size.height - l), p);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - l, size.height), p); canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - l), p);
  }
  @override
  bool shouldRepaint(_) => false;
}
