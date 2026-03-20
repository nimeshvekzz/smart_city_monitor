import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_city_monitor/core/models/sensor_node.dart';
import 'package:smart_city_monitor/ui/theme/design_tokens.dart';

class StatusBadge extends StatelessWidget {
  final SensorStatus status;
  final bool compact;
  const StatusBadge({super.key, required this.status, this.compact = false});

  Color _color(BuildContext context) {
    switch (status) {
      case SensorStatus.safe:    return DesignTokens.safe(context);
      case SensorStatus.warning: return DesignTokens.warning(context);
      case SensorStatus.alert:   return DesignTokens.alert(context);
    }
  }

  String get _label {
    switch (status) {
      case SensorStatus.safe:    return 'SAFE';
      case SensorStatus.warning: return 'WARNING';
      case SensorStatus.alert:   return 'ALERT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).toInt()),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 8,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            _label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
