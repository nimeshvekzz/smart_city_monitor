import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_city_monitor/core/models/sensor_node.dart';
import 'package:smart_city_monitor/core/models/alert_model.dart';
import 'package:smart_city_monitor/ui/theme/design_tokens.dart';
import 'package:smart_city_monitor/ui/widgets/status_badge.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onResolve;

  const AlertCard({super.key, required this.alert, this.onResolve});

  Color _typeColor(BuildContext context) {
    switch (alert.type) {
      case AlertType.fire:     return DesignTokens.alert(context);
      case AlertType.gas:      return DesignTokens.warning(context);
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
    final color = alert.isResolved ? DesignTokens.textMuted(context) : _typeColor(context);
    final isResolved = alert.isResolved;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: DesignTokens.surface(context),
        borderRadius: BorderRadius.circular(20),
        gradient: DesignTokens.surfaceGradient(context),
        boxShadow: DesignTokens.shadowLow(context),
        border: Border.all(
          color: isResolved 
              ? DesignTokens.border(context).withAlpha((255 * 0.3).toInt()) 
              : color.withAlpha((255 * 0.25).toInt()),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((255 * 0.12).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(_typeIcon, color: color, size: 22),
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
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        _timeAgo(),
                        style: GoogleFonts.outfit(
                          color: DesignTokens.textMuted(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert.nodeLocation,
                    style: GoogleFonts.outfit(
                      color: DesignTokens.textPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.message,
                    style: GoogleFonts.outfit(
                      color: DesignTokens.textSecondary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(
                        status: isResolved ? SensorStatus.safe : SensorStatus.alert,
                        compact: true,
                      ),
                      if (!isResolved && onResolve != null)
                        GestureDetector(
                          onTap: onResolve,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: DesignTokens.safe(context).withAlpha((255 * 0.1).toInt()),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: DesignTokens.safe(context).withAlpha((255 * 0.3).toInt())),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_rounded, size: 16, color: DesignTokens.safe(context)),
                                const SizedBox(width: 6),
                                Text(
                                  'Resolve',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: DesignTokens.safe(context),
                                  ),
                                ),
                              ],
                            ),
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
