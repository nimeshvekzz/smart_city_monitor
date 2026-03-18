import 'package:flutter/material.dart';
import '../models/sensor_node.dart';
import '../theme/design_tokens.dart';
import '../widgets/status_badge.dart';

class NodeDetailScreen extends StatelessWidget {
  final SensorNode node;
  const NodeDetailScreen({super.key, required this.node});

  Color _statusColor(SensorStatus s) {
    switch (s) {
      case SensorStatus.safe:    return DesignTokens.safe;
      case SensorStatus.warning: return DesignTokens.warning;
      case SensorStatus.alert:   return DesignTokens.alert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(node.overallStatus);
    
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      body: Stack(
        children: [
          // Background effects
          Positioned.fill(child: _CyberBackground()),
          
          CustomScrollView(
            slivers: [
              _buildAppBar(context, statusColor),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick status strip
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 85, child: _StatusStrip(label: 'FIRE', status: node.fire.status)),
                            const SizedBox(width: 10),
                            SizedBox(width: 85, child: _StatusStrip(label: 'GAS', status: node.gas.status)),
                            const SizedBox(width: 10),
                            SizedBox(width: 85, child: _StatusStrip(label: 'WATER', status: node.water.status)),
                            const SizedBox(width: 10),
                            SizedBox(width: 85, child: _StatusStrip(label: 'LIGHT', status: node.light.status)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      const Text('SENSOR READOUTS',
                        style: TextStyle(
                          color: DesignTokens.cyan,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _sensorRow(
                        icon: Icons.local_fire_department_rounded,
                        label: 'THERMAL ANALYSIS',
                        desc: 'FIRE & TEMPERATURE PROBE',
                        data: node.fire,
                      ),
                      const SizedBox(height: 14),
                      _sensorRow(
                        icon: Icons.air_rounded,
                        label: 'AIR QUALITY',
                        desc: 'GAS CONCENTRATION MONITOR',
                        data: node.gas,
                      ),
                      const SizedBox(height: 14),
                      _sensorRow(
                        icon: Icons.water_rounded,
                        label: 'HYDRO LEVEL',
                        desc: 'FLOOD & OVERFLOW SENSOR',
                        data: node.water,
                      ),
                      const SizedBox(height: 14),
                      _sensorRow(
                        icon: Icons.lightbulb_rounded,
                        label: 'LUMINOSITY',
                        desc: 'AMBIENT LIGHT SENSOR',
                        data: node.light,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Thresholds technical card
                      _buildThresholdCard(),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color statusColor) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: DesignTokens.bg,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: DesignTokens.textPrimary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            // Gradient header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withValues(alpha: 0.15), DesignTokens.bg],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Header content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(node.id.toUpperCase(),
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: DesignTokens.cyan, size: 14),
                      const SizedBox(width: 6),
                      Text(node.location.toUpperCase(),
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                      const Spacer(),
                      StatusBadge(status: node.overallStatus, compact: true),
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

  Widget _sensorRow({
    required IconData icon,
    required String label,
    required String desc,
    required SensorData data,
  }) {
    final color = _statusColor(data.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.card.withValues(alpha: 0.5),
        borderRadius: DesignTokens.r12,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: DesignTokens.r8,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, 
                  style: TextStyle(
                    color: DesignTokens.textPrimary, 
                    fontWeight: FontWeight.w700, 
                    fontSize: 13,
                    fontFamily: 'RobotoMono',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: DesignTokens.textMuted, fontSize: 9, letterSpacing: 0.5)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.value.toStringAsFixed(1)} ${data.unit}',
                style: TextStyle(
                  color: DesignTokens.textPrimary, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 12,
                  fontFamily: 'RobotoMono',
                ),
              ),
              const SizedBox(height: 4),
              StatusBadge(status: data.status, compact: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.card.withValues(alpha: 0.3),
        borderRadius: DesignTokens.r16,
        border: Border.all(color: DesignTokens.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.terminal_rounded, color: DesignTokens.cyan, size: 16),
              const SizedBox(width: 8),
              Text('THRESHOLD SYSTEM SPECS',
                style: TextStyle(
                  color: DesignTokens.cyan, 
                  fontWeight: FontWeight.w800, 
                  fontSize: 11,
                  letterSpacing: 1,
                  fontFamily: 'RobotoMono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _thresholdRow('FIRE',  'SAFE < 45°C | WARN 45-60°C | ALERT ≥ 60°C'),
          _thresholdRow('GAS',   'SAFE < 200ppm | WARN 200-400ppm | ALERT ≥ 400ppm'),
          _thresholdRow('WATER', 'SAFE < 70cm | WARN 70-90cm | ALERT ≥ 90cm'),
          _thresholdRow('LIGHT', 'SAFE > 200lx | WARN 100-200lx | ALERT < 100lx'),
        ],
      ),
    );
  }

  Widget _thresholdRow(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 4, color: DesignTokens.cyanDim),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: DesignTokens.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'RobotoMono')),
            ],
          ),
          const SizedBox(height: 4),
          Text(text, style: TextStyle(color: DesignTokens.textMuted, fontSize: 10, fontFamily: 'RobotoMono')),
          const SizedBox(height: 8),
          Divider(height: 1, thickness: 0.5, color: DesignTokens.border),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final String label;
  final SensorStatus status;
  const _StatusStrip({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == SensorStatus.safe ? DesignTokens.safe : (status == SensorStatus.warning ? DesignTokens.warning : DesignTokens.alert);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: DesignTokens.card.withValues(alpha: 0.4),
        borderRadius: DesignTokens.r12,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: color, 
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, 
            style: TextStyle(
              color: color, 
              fontSize: 10, 
              fontWeight: FontWeight.w800,
              fontFamily: 'RobotoMono',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberBackground extends StatefulWidget {
  @override
  State<_CyberBackground> createState() => _CyberBackgroundState();
}

class _CyberBackgroundState extends State<_CyberBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.03,
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => Container(
              height: 2,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white, width: 1)),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Positioned(
              top: _ctrl.value * MediaQuery.of(context).size.height,
              left: 0, right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      DesignTokens.cyan.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
