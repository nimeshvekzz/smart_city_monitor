import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sensor_node.dart';
import '../theme/design_tokens.dart';
import 'status_badge.dart';

class SensorCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final SensorData data;
  final VoidCallback? onTap;

  const SensorCard({
    super.key,
    required this.label,
    required this.icon,
    required this.data,
    this.onTap,
  });

  @override
  State<SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends State<SensorCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(SensorStatus s) => switch (s) {
    SensorStatus.safe    => DesignTokens.safe,
    SensorStatus.warning => DesignTokens.warning,
    SensorStatus.alert   => DesignTokens.alert,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(widget.data.status);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            // Pre-calculate to avoid redundant work in BoxDecoration
            final pulseValue = (math.sin(_pulseCtrl.value * math.pi * 2) + 1) / 2;
            final opacityMod = _isHovered ? 1.0 : (0.7 + pulseValue * 0.3);
            
            return Container(
              // Using Fixed Container instead of AnimatedContainer inside AnimatedBuilder
              transform: Matrix4.diagonal3Values(_isHovered ? 1.02 : 1.0, _isHovered ? 1.02 : 1.0, 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: DesignTokens.isDark 
                    ? (_isHovered ? DesignTokens.card.withValues(alpha: 0.7) : DesignTokens.card.withValues(alpha: 0.5))
                    : (_isHovered ? DesignTokens.card : DesignTokens.card.withValues(alpha: 0.9)),
                borderRadius: DesignTokens.r20,
                border: Border.all(
                  color: color.withValues(alpha: _isHovered ? 0.6 : (0.15 + pulseValue * 0.15)),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: (_isHovered ? 0.25 : 0.04) * opacityMod),
                    blurRadius: _isHovered ? 24 : 12,
                    spreadRadius: _isHovered ? 2 : 0,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: DesignTokens.r8,
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Icon(widget.icon, color: color, size: 22),
                    ),
                    StatusBadge(status: widget.data.status, compact: true),
                  ],
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${widget.data.value.toStringAsFixed(1)} ${widget.data.unit}',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label.toUpperCase(),
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'RobotoMono',
                    letterSpacing: 2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

