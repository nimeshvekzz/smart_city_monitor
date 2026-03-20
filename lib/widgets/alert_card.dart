import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sensor_node.dart';
import '../models/alert_model.dart';
import '../theme/design_tokens.dart';
import 'status_badge.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onResolve;

  const AlertCard({super.key, required this.alert, this.onResolve});

  Color get _typeColor {
    switch (alert.type) {
      case AlertType.fire:     return DesignTokens.alert;
      case AlertType.gas:      return DesignTokens.warning;
      case AlertType.water:    return Colors.blueAccent;
      case AlertType.light:    return Colors.purpleAccent;
      case AlertType.distance: return Colors.tealAccent;
      case AlertType.system:   return Colors.blueGrey;
    }
  }

  IconData get _typeIcon {
    switch (alert.type) {
      case AlertType.fire:     return Icons.local_fire_department_rounded;
      case AlertType.gas:      return Icons.air_rounded;
      case AlertType.water:    return Icons.water_rounded;
      case AlertType.light:    return Icons.lightbulb_rounded;
      case AlertType.distance: return Icons.settings_input_antenna_rounded;
      case AlertType.system:   return Icons.settings_rounded;
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(alert.timestamp);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = alert.isResolved ? DesignTokens.textMuted : _typeColor;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha((255 * 0.1).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(_typeIcon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alert.typeLabel.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: color, 
                          fontSize: 12, 
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _timeAgo(),
                        style: GoogleFonts.outfit(
                          color: DesignTokens.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.nodeLocation,
                    style: GoogleFonts.outfit(
                      color: DesignTokens.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.message,
                    style: GoogleFonts.outfit(
                      color: DesignTokens.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(
                        status: alert.isResolved ? SensorStatus.safe : SensorStatus.alert,
                        compact: true,
                      ),
                      if (!alert.isResolved && onResolve != null)
                        TextButton.icon(
                          onPressed: onResolve,
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Resolve'),
                          style: TextButton.styleFrom(
                            foregroundColor: DesignTokens.safe,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
