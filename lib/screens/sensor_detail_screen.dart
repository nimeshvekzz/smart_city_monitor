import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alert_model.dart';
import '../models/sensor_node.dart';
import '../services/data_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/status_badge.dart';

class SensorDetailScreen extends StatelessWidget {
  final AlertType type;
  final String label;
  final IconData icon;

  const SensorDetailScreen({
    super.key,
    required this.type,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final data = DataService();
    final nodes = data.getNodesForSensor(type);
    final activeCount = data.getActiveSensorsCount(type);
    final alertsCount = data.getSensorAlertsCount(type);
    final criticalCount = data.getSensorAlertsCount(type, criticalOnly: true);

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: Text(label),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // Header Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _statItem('Sensors Active', activeCount.toString(), Icons.check_circle_rounded, DesignTokens.safe),
                  const SizedBox(width: 12),
                  _statItem('Sensors Alerts', alertsCount.toString(), Icons.warning_rounded, DesignTokens.warning),
                  const SizedBox(width: 12),
                  _statItem('Critical Alerts', criticalCount.toString(), Icons.error_rounded, DesignTokens.alert),
                ],
              ),
            ),
          ),

          // Node List Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Reporting Nodes',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textPrimary,
                ),
              ),
            ),
          ),

          // Node List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final node = nodes[index];
                  final sensorData = data.getSensorDataForNode(node, type);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NodeSensorCard(
                      nodeId: node.id,
                      location: node.location,
                      value: sensorData.value,
                      unit: sensorData.unit,
                      status: sensorData.status,
                    ),
                  );
                },
                childCount: nodes.length,
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DesignTokens.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeSensorCard extends StatelessWidget {
  final String nodeId;
  final String location;
  final double value;
  final String unit;
  final SensorStatus status;

  const _NodeSensorCard({
    required this.nodeId,
    required this.location,
    required this.value,
    required this.unit,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nodeId,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                Text(
                  location,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${value.toStringAsFixed(1)}$unit',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              StatusBadge(status: status, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}
