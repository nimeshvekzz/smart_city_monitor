import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_city_monitor/core/models/sensor_node.dart';
import 'package:smart_city_monitor/ui/theme/design_tokens.dart';
import 'package:smart_city_monitor/ui/widgets/status_badge.dart';

class SensorCard extends StatelessWidget {
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

  Color _statusColor(BuildContext context, SensorStatus s) => switch (s) {
    SensorStatus.safe    => DesignTokens.safe(context),
    SensorStatus.warning => DesignTokens.warning(context),
    SensorStatus.alert   => DesignTokens.alert(context),
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, data.status);
    
    return InkWell(
      onTap: onTap,
      borderRadius: DesignTokens.r12,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.surface(context),
          borderRadius: DesignTokens.r12,
          border: Border.all(color: DesignTokens.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                StatusBadge(status: data.status, compact: true),
              ],
            ),
            const Spacer(),
            Text(
              '${data.value.toStringAsFixed(1)} ${data.unit}',
              style: GoogleFonts.outfit(
                color: DesignTokens.textPrimary(context),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: DesignTokens.textSecondary(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

