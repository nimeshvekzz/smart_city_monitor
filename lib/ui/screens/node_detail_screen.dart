import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_city_monitor/core/models/sensor_node.dart';
import 'package:smart_city_monitor/ui/widgets/status_badge.dart';

// ─────────────────────────────────────────────────────────────
//  SHARED DESIGN SYSTEM  (mirrors dashboard / history)
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

  // Sensor-type colours
  static const fireColor     = Color(0xFFFF7043);
  static const gasColor      = Color(0xFF66BB6A);
  static const waterColor    = Color(0xFF29B6F6);
  static const lightColor    = Color(0xFFFFD740);

  static TextStyle display(double size,
      {FontWeight w = FontWeight.w700, Color? color}) =>
      GoogleFonts.rajdhani(
          fontSize: size,
          fontWeight: w,
          color: color ?? textPrimary,
          letterSpacing: -0.3);

  static TextStyle mono(double size, {Color? color}) =>
      GoogleFonts.spaceMono(
          fontSize: size, color: color ?? textSecondary, letterSpacing: 0.5);

  static TextStyle body(double size,
      {FontWeight w = FontWeight.w500, Color? color}) =>
      GoogleFonts.dmSans(
          fontSize: size, fontWeight: w, color: color ?? textSecondary);

  static const fast   = Duration(milliseconds: 120);
}

// ─────────────────────────────────────────────────────────────
//  NODE DETAIL SCREEN
// ─────────────────────────────────────────────────────────────
class NodeDetailScreen extends StatefulWidget {
  final SensorNode node;
  const NodeDetailScreen({super.key, required this.node});

  @override
  State<NodeDetailScreen> createState() => _NodeDetailScreenState();
}

class _NodeDetailScreenState extends State<NodeDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    super.dispose();
  }

  // Map each sensor type to its meta
  static const _sensorMeta = [
    (label: 'Temperature', icon: Icons.local_fire_department_rounded, color: _DS.fireColor,     unit: '°C'),
    (label: 'Gas Level',   icon: Icons.air_rounded,                   color: _DS.gasColor,      unit: 'ppm'),
    (label: 'Water Level', icon: Icons.water_drop_rounded,            color: _DS.waterColor,    unit: 'cm'),
    (label: 'Luminosity',  icon: Icons.light_mode_rounded,            color: _DS.lightColor,    unit: 'lux'),
  ];

  static const _thresholds = [
    (sensor: 'FIRE',    safe: '< 45°C',    warn: '45–60°C',    alert: '≥ 60°C',  color: _DS.fireColor),
    (sensor: 'GAS',     safe: '< 200 ppm', warn: '200–400 ppm',alert: '≥ 400 ppm',color: _DS.gasColor),
    (sensor: 'WATER',   safe: '< 70 cm',   warn: '70–90 cm',   alert: '≥ 90 cm', color: _DS.waterColor),
    (sensor: 'LIGHT',   safe: '> 200 lx',  warn: '100–200 lx', alert: '< 100 lx',color: _DS.lightColor),
  ];

  @override
  Widget build(BuildContext context) {
    final node = widget.node;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _DS.bg,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(node),
              _buildLocationCard(node),
              _buildSectionLabel('Sensor Readings', Icons.sensors_rounded),
              _buildSensorReadings(node),
              _buildSectionLabel('System Thresholds', Icons.tune_rounded),
              _buildThresholds(),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────
  Widget _buildAppBar(SensorNode node) {
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(node.id, style: _DS.display(20)),
                  Text('NODE DETAIL', style: _DS.mono(9, color: _DS.textMuted)),
                ],
              ),
            ),
            StatusBadge(status: node.overallStatus),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ── Location Card ────────────────────────────────────────
  Widget _buildLocationCard(SensorNode node) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _DS.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _DS.cyan.withValues(alpha: 0.2)),
              gradient: LinearGradient(
                colors: [_DS.cyan.withValues(alpha: 0.07), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _DS.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _DS.cyan.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: _DS.cyan, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(node.location, style: _DS.display(18)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _DS.green, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text('Active Node', style: _DS.body(12, color: _DS.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section Label ────────────────────────────────────────
  Widget _buildSectionLabel(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          children: [
            Container(
              width: 3, height: 18,
              decoration: BoxDecoration(
                color: _DS.cyan,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: _DS.cyan, size: 16),
            const SizedBox(width: 8),
            Text(title, style: _DS.display(17)),
          ],
        ),
      ),
    );
  }

  // ── Sensor Readings ──────────────────────────────────────
  Widget _buildSensorReadings(SensorNode node) {
    final readings = [
      (meta: _sensorMeta[0], data: node.fire),
      (meta: _sensorMeta[1], data: node.gas),
      (meta: _sensorMeta[2], data: node.water),
      (meta: _sensorMeta[3], data: node.light),
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final r = readings[i];
            final delay = Duration(milliseconds: 80 * i);
            return _StaggeredEntry(
              delay: delay,
              controller: _entryAnim,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SensorReadingTile(
                  icon: r.meta.icon,
                  label: r.meta.label,
                  value: r.data.value,
                  unit: r.meta.unit,
                  status: r.data.status,
                  color: r.meta.color,
                ),
              ),
            );
          },
          childCount: readings.length,
        ),
      ),
    );
  }

  // ── Thresholds ───────────────────────────────────────────
  Widget _buildThresholds() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: _DS.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _DS.border),
          ),
          child: Column(
            children: List.generate(_thresholds.length, (i) {
              final t = _thresholds[i];
              final isLast = i == _thresholds.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: t.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: t.color.withValues(alpha: 0.3)),
                          ),
                          child: Text(t.sensor, style: _DS.mono(9, color: t.color)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _ThresholdChip(label: 'Safe', value: t.safe,  color: _DS.green),
                              _ThresholdChip(label: 'Warn', value: t.warn,  color: _DS.amber),
                              _ThresholdChip(label: 'Alert',value: t.alert, color: _DS.red),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, color: _DS.border),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SENSOR READING TILE
// ─────────────────────────────────────────────────────────────
class _SensorReadingTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final double value;
  final String unit;
  final SensorStatus status;
  final Color color;

  const _SensorReadingTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.color,
  });

  @override
  State<_SensorReadingTile> createState() => _SensorReadingTileState();
}

class _SensorReadingTileState extends State<_SensorReadingTile> {
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
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: _DS.fast,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _DS.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.status == SensorStatus.alert
                  ? _DS.red.withValues(alpha: 0.4)
                  : _DS.border,
              width: widget.status == SensorStatus.alert ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label, style: _DS.body(14, w: FontWeight.w600, color: _DS.textPrimary)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: _statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: _statusColor.withValues(alpha: 0.5), blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(_statusLabel,
                            style: _DS.mono(9, color: _statusColor)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.value.toStringAsFixed(1),
                    style: _DS.display(22, color: widget.color),
                  ),
                  Text(widget.unit, style: _DS.mono(10, color: _DS.textMuted)),
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
//  THRESHOLD CHIP
// ─────────────────────────────────────────────────────────────
class _ThresholdChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ThresholdChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: _DS.mono(9, color: _DS.textMuted)),
        Text(value, style: _DS.body(12, color: color, w: FontWeight.w600)),
      ],
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
