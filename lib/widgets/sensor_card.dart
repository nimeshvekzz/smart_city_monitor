import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sensor_node.dart';
import '../theme/design_tokens.dart';
import 'status_badge.dart';

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

  Color _statusColor(SensorStatus s) => switch (s) {
    SensorStatus.safe    => DesignTokens.safe,
    SensorStatus.warning => DesignTokens.warning,
    SensorStatus.alert   => DesignTokens.alert,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(data.status);
    
    return InkWell(
      onTap: onTap,
      borderRadius: DesignTokens.r12,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: DesignTokens.r12,
          border: Border.all(color: DesignTokens.border),
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
                color: DesignTokens.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: DesignTokens.textSecondary,
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

