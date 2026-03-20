import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_city_monitor/core/models/alert_model.dart';
import 'package:smart_city_monitor/core/models/sensor_node.dart';
import 'package:smart_city_monitor/core/services/data_service.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN SYSTEM
// ─────────────────────────────────────────────────────────────
class _DS {
  static const bg      = Color(0xFF0A0D14);
  static const surface = Color(0xFF121720);
  static const card    = Color(0xFF171E2B);

  static const cyan    = Color(0xFF00E5FF);
  static const green   = Color(0xFF00E676);
  static const amber   = Color(0xFFFFAB40);
  static const red     = Color(0xFFFF5252);

  static const textPrimary   = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8892A4);
  static const textMuted     = Color(0xFF4A5568);
  static const border        = Color(0xFF1E2A3C);

  static Color sensorColor(AlertType t) => switch (t) {
    AlertType.water    => const Color(0xFF29B6F6),
    AlertType.fire     => const Color(0xFFFF7043),
    AlertType.light    => const Color(0xFFFFD740),
    AlertType.gas      => const Color(0xFF66BB6A),
    AlertType.distance => const Color(0xFF7E57C2),
    _ => cyan,
  };

  static TextStyle display(double size,
      {FontWeight w = FontWeight.w700, Color? color}) =>
      GoogleFonts.rajdhani(fontSize: size, fontWeight: w,
          color: color ?? textPrimary, letterSpacing: -0.3);

  static TextStyle mono(double size, {Color? color}) =>
      GoogleFonts.spaceMono(fontSize: size, color: color ?? textSecondary,
          letterSpacing: 0.5);

  static TextStyle body(double size,
      {FontWeight w = FontWeight.w500, Color? color}) =>
      GoogleFonts.dmSans(fontSize: size, fontWeight: w,
          color: color ?? textSecondary);

  static const fast   = Duration(milliseconds: 120);
}
// ─────────────────────────────────────────────────────────────
//  SENSOR DETAIL SCREEN
// ─────────────────────────────────────────────────────────────
class SensorDetailScreen extends StatefulWidget {
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
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryAnim;
  final DataService _data = DataService();

  @override
  void initState() {
    super.initState();
    _data.addListener(_onDataChange);
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _data.removeListener(_onDataChange);
    _entryAnim.dispose();
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final color         = _DS.sensorColor(widget.type);
    final nodes         = _data.getNodesForSensor(widget.type);
    final activeCount   = _data.getActiveSensorsCount(widget.type);
    final alertsCount   = _data.getSensorAlertsCount(widget.type);
    final criticalCount = _data.getSensorAlertsCount(widget.type, criticalOnly: true);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _DS.bg,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(color),
              _buildHero(color, activeCount, alertsCount, criticalCount, nodes.length),
              _buildSectionLabel('Reporting Nodes', nodes.length),
              _buildNodeList(nodes, color),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────
  Widget _buildAppBar(Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
        child: Row(
          children: [
            _IconBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
            ),
            const SizedBox(width: 8),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label, style: _DS.display(20)),
                  Text('SENSOR NETWORK', style: _DS.mono(9, color: _DS.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Stats Row ────────────────────────────────────────
  Widget _buildHero(Color color, int active, int alerts, int critical, int total) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              // Big stat strip
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _DS.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.08), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(widget.icon, color: color, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.label, style: _DS.display(20)),
                              Row(children: [
                                Text('SENSOR TYPE · ', style: _DS.mono(9, color: _DS.textMuted)),
                                Text(widget.type.name.toUpperCase(),
                                    style: _DS.mono(9, color: color)),
                              ]),
                            ],
                          ),
                        ),
                        // Overall status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (critical > 0 ? _DS.red : alerts > 0 ? _DS.amber : _DS.green)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (critical > 0 ? _DS.red : alerts > 0 ? _DS.amber : _DS.green)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            critical > 0 ? 'CRITICAL' : alerts > 0 ? 'WARNING' : 'NOMINAL',
                            style: _DS.mono(9,
                                color: critical > 0 ? _DS.red : alerts > 0 ? _DS.amber : _DS.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _HeroStat(label: 'ACTIVE',   value: '$active',   color: _DS.green),
                        _HeroStat(label: 'ALERTS',   value: '$alerts',   color: _DS.amber),
                        _HeroStat(label: 'CRITICAL', value: '$critical', color: _DS.red),
                        _HeroStat(label: 'TOTAL',    value: '$total',    color: _DS.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Label ────────────────────────────────────────
  Widget _buildSectionLabel(String title, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          children: [
            Container(
              width: 3, height: 18,
              decoration: BoxDecoration(
                color: _DS.sensorColor(widget.type),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(title, style: _DS.display(17)),
            const Spacer(),
            Text('$count TOTAL', style: _DS.mono(9, color: _DS.textMuted)),
          ],
        ),
      ),
    );
  }

  // ── Node List ─────────────────────────────────────────────
  Widget _buildNodeList(List<SensorNode> nodes, Color color) {
    if (nodes.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.sensors_off_rounded, color: _DS.textMuted, size: 40),
              const SizedBox(height: 12),
              Text('No nodes reporting', style: _DS.display(16)),
              Text('Sensor network offline', style: _DS.body(13)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final node       = nodes[i];
            final sensorData = _data.getSensorDataForNode(node, widget.type);
            return _StaggeredEntry(
              delay: Duration(milliseconds: 60 * i),
              controller: _entryAnim,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NodeCard(
                  node: node,
                  value: sensorData.value,
                  unit: sensorData.unit,
                  status: sensorData.status,
                  color: color,
                ),
              ),
            );
          },
          childCount: nodes.length,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HERO STAT CELL
// ─────────────────────────────────────────────────────────────
class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HeroStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: _DS.display(24, color: color)),
          Text(label, style: _DS.mono(8, color: _DS.textMuted)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NODE CARD
// ─────────────────────────────────────────────────────────────
class _NodeCard extends StatefulWidget {
  final SensorNode node;
  final double value;
  final String unit;
  final SensorStatus status;
  final Color color;

  const _NodeCard({
    required this.node,
    required this.value,
    required this.unit,
    required this.status,
    required this.color,
  });

  @override
  State<_NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends State<_NodeCard> {
  bool _pressed = false;

  Color get _statusColor => switch (widget.status) {
    SensorStatus.alert   => _DS.red,
    SensorStatus.warning => _DS.amber,
    _                    => _DS.green,
  };

  String get _statusLabel => switch (widget.status) {
    SensorStatus.alert   => 'ALERT',
    SensorStatus.warning => 'WARN',
    _                    => 'SAFE',
  };

  @override
  Widget build(BuildContext context) {
    final isAlert = widget.status == SensorStatus.alert;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: _DS.fast,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _DS.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isAlert
                  ? _DS.red.withValues(alpha: 0.4)
                  : _DS.border,
              width: isAlert ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Status indicator bar
              Container(
                width: 3, height: 42,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: _statusColor.withValues(alpha: 0.4), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.node.id,
                        style: _DS.body(14, w: FontWeight.w700, color: _DS.textPrimary)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 11, color: _DS.textMuted),
                        const SizedBox(width: 3),
                        Text(widget.node.location,
                            style: _DS.body(12, color: _DS.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.value.toStringAsFixed(1)}${widget.unit}',
                    style: _DS.display(20, color: widget.color),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(_statusLabel,
                        style: _DS.mono(8, color: _statusColor)),
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

// ─────────────────────────────────────────────────────────────
//  ICON BUTTON
// ─────────────────────────────────────────────────────────────
class _IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: _DS.fast,
        child: Container(
          width: 38, height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _DS.border),
          ),
          child: Icon(widget.icon, color: _DS.textSecondary, size: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STAGGER HELPER
// ─────────────────────────────────────────────────────────────
class _StaggeredEntry extends StatelessWidget {
  final Duration delay;
  final AnimationController controller;
  final Widget child;
  const _StaggeredEntry({required this.delay, required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    final start = (delay.inMilliseconds / controller.duration!.inMilliseconds).clamp(0.0, 0.6);
    final end   = math.min(start + 0.4, 1.0);
    final opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Interval(start, end, curve: Curves.easeOut)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(parent: controller, curve: Interval(start, end, curve: Curves.easeOutCubic)));
    return FadeTransition(opacity: opacity, child: SlideTransition(position: slide, child: child));
  }
}
