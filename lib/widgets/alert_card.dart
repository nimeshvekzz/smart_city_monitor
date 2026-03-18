import 'package:flutter/material.dart';
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
      case AlertType.fire:   return DesignTokens.alert;
      case AlertType.gas:    return DesignTokens.warning;
      case AlertType.water:  return DesignTokens.cyan;
      case AlertType.light:  return const Color(0xFFA855F7);
      case AlertType.system: return DesignTokens.cyanDim;
    }
  }

  IconData get _typeIcon {
    switch (alert.type) {
      case AlertType.fire:   return Icons.local_fire_department_rounded;
      case AlertType.gas:    return Icons.air_rounded;
      case AlertType.water:  return Icons.water_rounded;
      case AlertType.light:  return Icons.lightbulb_rounded;
      case AlertType.system: return Icons.settings_rounded;
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(alert.timestamp);
    if (diff.inMinutes < 1)  return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    if (diff.inHours < 24)   return '${diff.inHours}H AGO';
    return '${diff.inDays}D AGO';
  }

  @override
  Widget build(BuildContext context) {
    final color = alert.isResolved ? DesignTokens.textMuted : _typeColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: DesignTokens.card.withValues(alpha: alert.isResolved ? 0.4 : 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: alert.isResolved ? 0.2 : 0.4),
          width: 1.2,
        ),
        boxShadow: [
          if (!alert.isResolved)
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          const BoxShadow(
            color: Color(0x77000000),
            blurRadius: 16, offset: Offset(0, 8),
          ),
        ],
        gradient: !alert.isResolved ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            DesignTokens.card.withValues(alpha: 0.4),
          ],
        ) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background subtle pattern or glow
          if (!alert.isResolved)
            Positioned(
              top: -20, right: -20,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon block
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Icon(_typeIcon, color: color, size: 20),
                ),
                const SizedBox(width: 18),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(alert.typeLabel.toUpperCase(),
                            style: TextStyle(
                              color: color, 
                              fontSize: 10, 
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                          const Spacer(),
                          Text(_timeAgo(),
                            style: TextStyle(
                              color: DesignTokens.textMuted,
                              fontSize: 9,
                              fontFamily: 'RobotoMono',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
                            ),
                            child: Text(alert.severityLabel,
                              style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, fontFamily: 'RobotoMono'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(alert.nodeLocation.toUpperCase(),
                              style: TextStyle(
                                color: DesignTokens.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                fontFamily: 'RobotoMono',
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(alert.message,
                        style: TextStyle(
                          color: DesignTokens.textPrimary.withValues(alpha: alert.isResolved ? 0.6 : 0.95),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          StatusBadge(
                            status: alert.isResolved ? SensorStatus.safe : SensorStatus.alert,
                            compact: true,
                          ),
                          const Spacer(),
                          if (!alert.isResolved && onResolve != null)
                            _ResolveButton(onTap: onResolve!, color: DesignTokens.safe),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolveButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  const _ResolveButton({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: -2),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: color, size: 14),
            const SizedBox(width: 8),
            Text('RESOLVE',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontFamily: 'RobotoMono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
