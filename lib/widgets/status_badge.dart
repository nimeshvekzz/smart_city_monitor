import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sensor_node.dart';
import '../theme/design_tokens.dart';

class StatusBadge extends StatelessWidget {
  final SensorStatus status;
  final bool compact;
  const StatusBadge({super.key, required this.status, this.compact = false});

  Color get _color {
    switch (status) {
      case SensorStatus.safe:    return DesignTokens.safe;
      case SensorStatus.warning: return DesignTokens.warning;
      case SensorStatus.alert:   return DesignTokens.alert;
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: _color.withAlpha((255 * 0.1).toInt()),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 8,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            _label,
            style: GoogleFonts.outfit(
              color: _color,
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
