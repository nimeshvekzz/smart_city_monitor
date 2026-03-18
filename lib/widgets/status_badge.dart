import 'package:flutter/material.dart';
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
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 5 : 7,
            height: compact ? 5 : 7,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 3 : 5),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
