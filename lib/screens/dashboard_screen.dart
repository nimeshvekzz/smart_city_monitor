import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alert_model.dart';
import '../services/data_service.dart';
import '../theme/design_tokens.dart';
import 'sensor_detail_screen.dart';
import 'history_screen.dart';
import 'alerts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DataService _data = DataService();

  @override
  void initState() {
    super.initState();
    _data.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _data.removeListener(_onDataChange);
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('Smart Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                ),
              ),
              if (_data.alerts.any((a) => !a.isResolved))
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: DesignTokens.alert,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _onDataChange(),
        child: CustomScrollView(
          slivers: [
            // Status Summary Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildStatusBanner(),
              ),
            ),

            // Sensor Overview Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Active Sensors'),
                    const SizedBox(height: 12),
                    _buildSensorGrid(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: DesignTokens.textPrimary,
      ),
    );
  }

  Widget _buildStatusBanner() {
    final critical = _data.alerts.where((a) => !a.isResolved && a.severity == AlertSeverity.high).length;
    final warning  = _data.alerts.where((a) => !a.isResolved && a.severity == AlertSeverity.medium).length;

    final Color color;
    final String title;
    final String subtitle;
    final IconData icon;

    if (critical > 0) {
      color = DesignTokens.alert;
      title = 'System Critical';
      subtitle = '$critical critical alert(s) active';
      icon = Icons.error_outline_rounded;
    } else if (warning > 0) {
      color = DesignTokens.warning;
      title = 'System Warning';
      subtitle = '$warning warning(s) active';
      icon = Icons.warning_amber_rounded;
    } else {
      color = DesignTokens.safe;
      title = 'System Normal';
      subtitle = 'All sensors are operating within safe parameters';
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.05).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((255 * 0.2).toInt())),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.1).toInt()),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid() {
    final sensors = [
      {'type': AlertType.water,    'label': 'Water Sensor',  'icon': Icons.water_rounded},
      {'type': AlertType.fire,     'label': 'Fire Sensor',   'icon': Icons.local_fire_department_rounded},
      {'type': AlertType.light,    'label': 'LDR Sensor',    'icon': Icons.lightbulb_rounded},
      {'type': AlertType.gas,      'label': 'MQ2 Sensor',     'icon': Icons.air_rounded},
      {'type': AlertType.distance, 'label': 'HC-SR04 Sensor', 'icon': Icons.settings_input_antenna_rounded},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: sensors.length,
      itemBuilder: (context, index) {
        final s = sensors[index];
        final type = s['type'] as AlertType;
        final alertsCount = _data.getSensorAlertsCount(type);
        
        return _SensorTypeCard(
          label: s['label'] as String,
          icon: s['icon'] as IconData,
          type: type,
          alertsCount: alertsCount,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SensorDetailScreen(
                type: type,
                label: s['label'] as String,
                icon: s['icon'] as IconData,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SensorTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final AlertType type;
  final int alertsCount;
  final VoidCallback onTap;

  const _SensorTypeCard({
    required this.label,
    required this.icon,
    required this.type,
    required this.alertsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAlerts = alertsCount > 0;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasAlerts ? DesignTokens.alert.withAlpha((255 * 0.3).toInt()) : DesignTokens.border,
          width: hasAlerts ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (hasAlerts ? DesignTokens.alert : DesignTokens.primary).withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: hasAlerts ? DesignTokens.alert : DesignTokens.primary, size: 20),
                  ),
                  if (hasAlerts)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: DesignTokens.alert,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$alertsCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasAlerts ? 'Alert Active' : 'Operating Normal',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: hasAlerts ? DesignTokens.alert : DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
