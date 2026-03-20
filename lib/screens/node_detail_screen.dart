import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sensor_node.dart';
import '../theme/design_tokens.dart';
import '../widgets/status_badge.dart';

class NodeDetailScreen extends StatelessWidget {
  final SensorNode node;
  const NodeDetailScreen({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: Text(node.id, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Text('Sensor Readings', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _sensorCard(Icons.local_fire_department_rounded, 'Temperature', node.fire, DesignTokens.alert),
            _sensorCard(Icons.air_rounded, 'Gas Level', node.gas, DesignTokens.warning),
            _sensorCard(Icons.water_rounded, 'Water Level', node.water, Colors.blue),
            _sensorCard(Icons.lightbulb_rounded, 'Luminosity', node.light, Colors.purple),
            const SizedBox(height: 24),
            _buildThresholds(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: DesignTokens.primary.withAlpha((255 * 0.1).toInt()),
              child: Icon(Icons.location_on_rounded, color: DesignTokens.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(node.location, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                  Text('Active Node', style: GoogleFonts.outfit(fontSize: 14, color: DesignTokens.textSecondary)),
                ],
              ),
            ),
            StatusBadge(status: node.overallStatus),
          ],
        ),
      ),
    );
  }

  Widget _sensorCard(IconData icon, String label, SensorData data, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text('Status: ${data.status.name.toUpperCase()}', style: GoogleFonts.outfit(fontSize: 12, color: DesignTokens.textMuted)),
        trailing: Text('${data.value.toStringAsFixed(1)} ${data.unit}', 
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: DesignTokens.textPrimary)),
      ),
    );
  }

  Widget _buildThresholds() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Thresholds', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _thresholdRow('Fire', 'Safe < 45°C | Warning 45-60°C | Alert ≥ 60°C'),
        _thresholdRow('Gas', 'Safe < 200ppm | Warning 200-400ppm | Alert ≥ 400ppm'),
        _thresholdRow('Water', 'Safe < 70cm | Warning 70-90cm | Alert ≥ 90cm'),
        _thresholdRow('Light', 'Safe > 200lx | Warning 100-200lx | Alert < 100lx'),
      ],
    );
  }

  Widget _thresholdRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: GoogleFonts.outfit(fontSize: 13, color: DesignTokens.textSecondary))),
        ],
      ),
    );
  }
}
