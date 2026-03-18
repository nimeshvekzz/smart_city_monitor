import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/sensor_node.dart';
import '../services/data_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/sensor_card.dart';
import '../widgets/node_search_delegate.dart';
import '../widgets/status_badge.dart';
import '../widgets/city_background.dart'; // Import common painters
import 'node_detail_screen.dart';

// ─── HUD grid icon painter ─────────────────────────────────────────────────────
class _HudIconPainter extends CustomPainter {
  final double t;
  _HudIconPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final alpha = (0.65 + math.sin(t * math.pi * 2) * 0.35).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = DesignTokens.cyan.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(w * i / 3, 0), Offset(w * i / 3, h), paint);
      canvas.drawLine(Offset(0, h * i / 3), Offset(w, h * i / 3), paint);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(3)),
      paint,
    );
    canvas.drawCircle(
      Offset(w / 2, h / 2), 2.5,
      Paint()..color = DesignTokens.cyan,
    );
  }

  @override
  bool shouldRepaint(_HudIconPainter old) => old.t != t;
}

// ─── Main screen ──────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final DataService _data = DataService();
  bool _isMapView = false;

  late final AnimationController _pulseCtrl;
  late final AnimationController _scanCtrl;
  late final AnimationController _cityCtrl;
  late final AnimationController _headerCtrl;
  late final AnimationController _bannerCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _bannerFade;
  late final Animation<Offset> _bannerSlide;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 7))
      ..repeat();

    _cityCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _bannerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _bannerFade  = CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOut);
    _bannerSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOutCubic));

    _data.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _data.removeListener(_onDataChange);
    for (final c in [_pulseCtrl, _scanCtrl, _cityCtrl, _headerCtrl, _bannerCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onDataChange() { if (mounted) setState(() {}); }
  int get _alertCount => _data.alerts.where((a) => !a.isResolved).length;

  Color _statusColor(SensorStatus s) => switch (s) {
    SensorStatus.safe    => DesignTokens.safe,
    SensorStatus.warning => DesignTokens.warning,
    SensorStatus.alert   => DesignTokens.alert,
  };

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final nodes = _data.nodes;
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent, // Global background handled by MainShell
        colorScheme: ColorScheme.dark(
          primary: DesignTokens.cyan, surface: DesignTokens.surface,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(nodes),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScaleTransition(
                      scale: _bannerFade,
                      child: SlideTransition(
                        position: _bannerSlide,
                        child: FadeTransition(
                          opacity: _bannerFade,
                          child: _buildStatusBanner(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader(
                      'ACTIVE NODES',
                      '${nodes.length} ONLINE',
                      _isMapView ? 'GRID VIEW' : 'MAP VIEW',
                      () => setState(() => _isMapView = !_isMapView),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            if (_isMapView)
              SliverFillRemaining(child: _buildMapView())
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.crossAxisExtent < 600;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: narrow ? 1 : 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: narrow ? 2.1 : 1.1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _NodeCard(
                          node: nodes[i],
                          index: i,
                          statusColor: _statusColor(nodes[i].overallStatus),
                          pulseCtrl: _pulseCtrl,
                          onTap: () => Navigator.push(ctx,
                            _fadeRoute(NodeDetailScreen(node: nodes[i]))),
                        ),
                        childCount: nodes.length,
                      ),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 10),
                  child: _sectionLabel('SYSTEM OVERVIEW'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: _buildSensorTypeGrid(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Route _fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: page),
    transitionDuration: const Duration(milliseconds: 400),
  );

  // ── App bar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar(List<SensorNode> nodes) {
    final now = _data.lastUpdated;
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:'
                    '${now.minute.toString().padLeft(2, '0')}';

    return SliverAppBar(
      pinned: true,
      expandedHeight: 140,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (_, constraints) {
          final pct = ((constraints.maxHeight - kToolbarHeight) /
              (140 - kToolbarHeight)).clamp(0.0, 1.0);

          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Glass background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        DesignTokens.surface.withValues(alpha: 0.97),
                        DesignTokens.bg.withValues(alpha: (0.9 - pct * 0.1).clamp(0.7, 0.97)),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: DesignTokens.cyan.withValues(alpha: 0.15), width: 1),
                    ),
                  ),
                ),

                // Content
                Positioned(
                  left: 16, right: 16, top: 0, bottom: 0,
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo
                            _buildLogoMark(pct),
                            const SizedBox(width: 14),

                            // Title
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SMART CITY',
                                    style: TextStyle(
                                      fontFamily: 'RobotoMono',
                                      color: DesignTokens.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18 + pct * 5,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  AnimatedOpacity(
                                    opacity: pct.clamp(0.0, 1.0),
                                    duration: const Duration(milliseconds: 200),
                                    child: const Text('MONITOR SYSTEM v2.0',
                                      style: TextStyle(
                                        fontFamily: 'RobotoMono',
                                        color: DesignTokens.cyan, fontSize: 10,
                                        letterSpacing: 3, fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    AnimatedBuilder(
                                      animation: _pulseCtrl,
                                      builder: (_, __) => Container(
                                        width: 6, height: 6,
                                        decoration: BoxDecoration(
                                          color: DesignTokens.safe,
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(
                                            color: DesignTokens.safe.withValues(alpha: 
                                                0.3 + 0.7 * _pulseCtrl.value),
                                            blurRadius: 8,
                                          )],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('SYNC  $timeStr',
                                      style: TextStyle(
                                        fontFamily: 'RobotoMono',
                                        fontSize: 10, color: DesignTokens.textSecondary,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
                            ),

                            // Actions
                            Row(children: [
                              _iconBtn(
                                icon: Icons.search_rounded,
                                onTap: () => showSearch(
                                  context: context,
                                  delegate: NodeSearchDelegate(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _AlertButton(
                                count: _alertCount,
                                pulseCtrl: _pulseCtrl,
                              ),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoMark(double pct) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    width: 46 + pct * 8,
    height: 46 + pct * 8,
    decoration: BoxDecoration(
      color: DesignTokens.cyan.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: DesignTokens.cyan.withValues(alpha: 0.45), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: DesignTokens.cyan.withValues(alpha: 0.15),
          blurRadius: 12, spreadRadius: 0,
        ),
      ],
    ),
    child: Center(
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => CustomPaint(
          size: Size(22 + pct * 4, 22 + pct * 4),
          painter: _HudIconPainter(_pulseCtrl.value),
        ),
      ),
    ),
  );

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: DesignTokens.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DesignTokens.border, width: 1),
          ),
          child: Icon(icon, color: DesignTokens.textSecondary, size: 20),
        ),
      );

  // ── Status banner ──────────────────────────────────────────────────────────
  Widget _buildStatusBanner() {
    final critical = _data.nodes.where((n) => n.overallStatus == SensorStatus.alert).length;
    final warning  = _data.nodes.where((n) => n.overallStatus == SensorStatus.warning).length;
    final safe     = _data.nodes.where((n) => n.overallStatus == SensorStatus.safe).length;

    final Color color;
    final String label;
    final IconData icon;

    if (critical > 0) {
      color = DesignTokens.alert; label = '$critical NODE(S) CRITICAL — IMMEDIATE ACTION';
      icon  = Icons.error_rounded;
    } else if (warning > 0) {
      color = DesignTokens.warning; label = '$warning NODE(S) WARNING — MONITOR CLOSELY';
      icon  = Icons.warning_amber_rounded;
    } else {
      color = DesignTokens.safe; label = 'ALL $safe NODES OPERATING NOMINALLY';
      icon  = Icons.check_circle_outline_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          // Pulse icon
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) => SizedBox(
              width: 38, height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(38, 38),
                    painter: PulseRingPainter(_pulseCtrl, color),
                  ),
                  child!,
                ],
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
              style: TextStyle(
                color: color, fontWeight: FontWeight.w700,
                fontSize: 12, fontFamily: 'RobotoMono', letterSpacing: 0.5,
              ),
            ),
          ),
          // Status dots
          Row(children: [
            _statusDot(DesignTokens.alert, critical),
            _statusDot(DesignTokens.warning, warning),
            _statusDot(DesignTokens.safe, safe),
          ]),
        ],
      ),
    );
  }

  Widget _statusDot(Color c, int count) => Padding(
    padding: const EdgeInsets.only(left: 5),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: count > 0 ? 9 : 6,
      height: count > 0 ? 9 : 6,
      decoration: BoxDecoration(
        color: count > 0 ? c : c.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        boxShadow: count > 0
            ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]
            : [],
      ),
    ),
  );

  // ── Section helpers ────────────────────────────────────────────────────────
  Widget _sectionLabel(String title) => Row(children: [
    Container(width: 3, height: 16, margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: DesignTokens.cyan,
        boxShadow: [BoxShadow(color: DesignTokens.cyan.withValues(alpha: 0.5), blurRadius: 6)],
      ),
    ),
    Text(title,
      style: TextStyle(color: DesignTokens.textPrimary, fontSize: 13, fontWeight: FontWeight.w800,
        fontFamily: 'RobotoMono', letterSpacing: 1.5,
      ),
    ),
  ]);

  Widget _sectionHeader(String title, String badge, String action, VoidCallback onTap) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(width: 3, height: 16,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: DesignTokens.cyan,
                boxShadow: [BoxShadow(color: DesignTokens.cyan.withValues(alpha: 0.5), blurRadius: 6)],
              ),
            ),
            Text(title,
              style: TextStyle(color: DesignTokens.textPrimary, fontSize: 13, fontWeight: FontWeight.w800,
                fontFamily: 'RobotoMono', letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: DesignTokens.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: DesignTokens.cyan.withValues(alpha: 0.3)),
              ),
              child: Text(badge,
                style: const TextStyle(
                  color: DesignTokens.cyan, fontSize: 9,
                  fontFamily: 'RobotoMono', fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: DesignTokens.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DesignTokens.cyan.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                Icon(
                  _isMapView ? Icons.grid_view_rounded : Icons.map_rounded,
                  color: DesignTokens.cyan, size: 12,
                ),
                const SizedBox(width: 6),
                Text(action,
                  style: const TextStyle(
                    color: DesignTokens.cyan, fontSize: 9,
                    fontFamily: 'RobotoMono', fontWeight: FontWeight.w800,
                  ),
                ),
              ]),
            ),
          ),
        ],
      );

  // ── Map view ───────────────────────────────────────────────────────────────
  Widget _buildMapView() => Padding(
    padding: const EdgeInsets.all(16),
    child: Container(
      decoration: BoxDecoration(
        color: DesignTokens.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.border, width: 1),
        boxShadow: [BoxShadow(color: DesignTokens.cyan.withValues(alpha: 0.05), blurRadius: 30)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          // Animated 3-D city backdrop
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _cityCtrl,
              builder: (_, __) => CustomPaint(
                painter: _CitySkylinePainter(_cityCtrl, _data.nodes),
              ),
            ),
          ),
          // Grid overlay
          Positioned.fill(child: _MapGrid()),
          // Corner brackets
          Positioned.fill(child: CustomPaint(painter: CornerBracketPainter())),
          // Node markers
          for (var i = 0; i < _data.nodes.length; i++)
            Positioned(
              left: 30.0 + (i * 65.0) % 280,
              top:  70.0 + (i * 45.0) % 160,
              child: _MapMarker(node: _data.nodes[i], pulseCtrl: _pulseCtrl),
            ),
          // HUD label
          Positioned(
            bottom: 16, left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GEOSPATIAL OVERLAY',
                  style: TextStyle(color: DesignTokens.cyan, fontSize: 9,
                    fontWeight: FontWeight.w800, fontFamily: 'RobotoMono',
                    letterSpacing: 2),
                ),
                Text('TRACKING ${_data.nodes.length} NODES',
                  style: TextStyle(color: DesignTokens.textSecondary, fontSize: 8,
                    fontFamily: 'RobotoMono'),
                ),
              ],
            ),
          ),
        ]),
      ),
    ),
  );

  // ── Sensor overview grid ───────────────────────────────────────────────────
  Widget _buildSensorTypeGrid() {
    final nodes = _data.nodes;
    if (nodes.isEmpty) return const SizedBox.shrink();

    final avgFire  = nodes.fold(0.0, (s, n) => s + n.fire.value)  / nodes.length;
    final avgGas   = nodes.fold(0.0, (s, n) => s + n.gas.value)   / nodes.length;
    final avgWater = nodes.fold(0.0, (s, n) => s + n.water.value) / nodes.length;
    final avgLight = nodes.fold(0.0, (s, n) => s + n.light.value) / nodes.length;

    SensorStatus worst(List<SensorStatus> ss) {
      if (ss.contains(SensorStatus.alert))   return SensorStatus.alert;
      if (ss.contains(SensorStatus.warning)) return SensorStatus.warning;
      return SensorStatus.safe;
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        final narrow = constraints.maxWidth < 600;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: narrow ? 1 : 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: narrow ? 2.2 : 1.5,
          children: [
            SensorCard(label: 'Fire / Temp',  icon: Icons.local_fire_department_rounded,
              data: SensorData(value: avgFire,  status: worst(nodes.map((n) => n.fire.status).toList()),  unit: '°C')),
            SensorCard(label: 'Gas Level',    icon: Icons.air_rounded,
              data: SensorData(value: avgGas,   status: worst(nodes.map((n) => n.gas.status).toList()),   unit: 'ppm')),
            SensorCard(label: 'Water Level',  icon: Icons.water_rounded,
              data: SensorData(value: avgWater, status: worst(nodes.map((n) => n.water.status).toList()), unit: 'cm')),
            SensorCard(label: 'Street Light', icon: Icons.lightbulb_rounded,
              data: SensorData(value: avgLight, status: worst(nodes.map((n) => n.light.status).toList()), unit: 'lux')),
          ],
        );
      },
    );
  }
}

// ─── Map grid overlay ──────────────────────────────────────────────────────────
class _MapGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _MapGridPainter());
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = DesignTokens.cyan.withValues(alpha: 0.06)..strokeWidth = 0.5;
    for (double x = 0; x <= size.width; x += 36)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y <= size.height; y += 36)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Map marker ────────────────────────────────────────────────────────────────
class _MapMarker extends StatelessWidget {
  final SensorNode node;
  final AnimationController pulseCtrl;
  const _MapMarker({required this.node, required this.pulseCtrl});

  Color get _color => switch (node.overallStatus) {
    SensorStatus.safe    => DesignTokens.safe,
    SensorStatus.warning => DesignTokens.warning,
    SensorStatus.alert   => DesignTokens.alert,
  };

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedBuilder(
        animation: pulseCtrl,
        builder: (_, child) => SizedBox(
          width: 24, height: 24,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: const Size(24, 24),
              painter: PulseRingPainter(pulseCtrl, _color),
            ),
            child!,
          ]),
        ),
        child: Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: _color, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.6), blurRadius: 8)],
          ),
        ),
      ),
      const SizedBox(height: 3),
      Text(node.id,
        style: TextStyle(color: DesignTokens.textPrimary, fontSize: 7,
          fontWeight: FontWeight.w800, fontFamily: 'RobotoMono',
        ),
      ),
    ],
  );
}

// ─── Alert button ──────────────────────────────────────────────────────────────
class _AlertButton extends StatelessWidget {
  final int count;
  final AnimationController pulseCtrl;
  const _AlertButton({required this.count, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, child) => Stack(
        clipBehavior: Clip.none,
        children: [
          if (count > 0)
            Positioned.fill(
              child: CustomPaint(
                painter: PulseRingPainter(pulseCtrl, DesignTokens.alert),
              ),
            ),
          child!,
        ],
      ),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: DesignTokens.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: count > 0 ? DesignTokens.alert.withValues(alpha: 0.4) : DesignTokens.border,
              width: 1,
            ),
            boxShadow: count > 0
                ? [BoxShadow(color: DesignTokens.alert.withValues(alpha: 0.2), blurRadius: 12)]
                : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                count > 0 ? Icons.notifications_rounded : Icons.notifications_outlined,
                color: count > 0 ? DesignTokens.alert : DesignTokens.textSecondary,
                size: 20,
              ),
              if (count > 0)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(
                      color: DesignTokens.alert, shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('$count',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Node card ─────────────────────────────────────────────────────────────────
class _NodeCard extends StatefulWidget {
  final SensorNode node;
  final int index;
  final Color statusColor;
  final AnimationController pulseCtrl;
  final VoidCallback onTap;
  const _NodeCard({
    required this.node,
    required this.index,
    required this.statusColor,
    required this.pulseCtrl,
    required this.onTap,
  });

  @override
  State<_NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends State<_NodeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500 + widget.index * 80),
    )..forward();
  }

  @override
  void dispose() { _entryCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final sc   = widget.statusColor;

    return FadeTransition(
      opacity: _entryCtrl,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
            .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic)),
        child: GestureDetector(
          onTapDown:   (_) => setState(() => _pressed = true),
          onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
          onTapCancel: ()  => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.diagonal3Values(_pressed ? 0.95 : 1.0, _pressed ? 0.95 : 1.0, 1.0),
            transformAlignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _pressed ? DesignTokens.cardHover : DesignTokens.card.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sc.withValues(alpha: _pressed ? 0.6 : 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: sc.withValues(alpha: _pressed ? 0.25 : 0.12),
                  blurRadius: 20, offset: const Offset(0, 4),
                ),
                const BoxShadow(
                  color: Color(0x77000000),
                  blurRadius: 16, offset: Offset(0, 8),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  sc.withValues(alpha: 0.12),
                  DesignTokens.card.withValues(alpha: 0.4),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header row
                Row(children: [
                  // Status icon box
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: sc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sc.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Icon(Icons.router_rounded, color: sc, size: 17),
                  ),
                  const Spacer(),
                  StatusBadge(status: node.overallStatus, compact: true),
                ]),

                const SizedBox(height: 8),

                // Node ID & location
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(node.id,
                          style: TextStyle(color: DesignTokens.textPrimary, fontWeight: FontWeight.w800,
                            fontSize: 15, fontFamily: 'RobotoMono',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(node.location,
                          style: TextStyle(color: DesignTokens.textSecondary, fontSize: 11,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Live pulse bar
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: widget.pulseCtrl,
                  builder: (_, __) {
                    return Container(
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        gradient: LinearGradient(
                          colors: [
                            sc.withValues(alpha: 0.1),
                            sc.withValues(alpha: 
                              0.4 + 0.6 * widget.pulseCtrl.value,
                            ),
                            sc.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Sensor mini indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _miniChip(Icons.local_fire_department_rounded, node.fire.status,  '°C'),
                    _miniChip(Icons.air_rounded,                   node.gas.status,   'GAS'),
                    _miniChip(Icons.water_rounded,                 node.water.status, 'H₂O'),
                    _miniChip(Icons.lightbulb_rounded,             node.light.status, 'LUX'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, SensorStatus status, String label) {
    final c = switch (status) {
      SensorStatus.safe    => DesignTokens.safe,
      SensorStatus.warning => DesignTokens.warning,
      SensorStatus.alert   => DesignTokens.alert,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.withValues(alpha: 0.25), width: 0.8),
          ),
          child: Icon(icon, size: 13, color: c),
        ),
        const SizedBox(height: 3),
        Text(label,
          style: TextStyle(
            color: c.withValues(alpha: 0.75), fontSize: 7.5,
            fontFamily: 'RobotoMono', letterSpacing: 0.3, fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── City skyline painter (Copied for Map View) ──────────────────────────────
class _CitySkylinePainter extends CustomPainter {
  final Animation<double> anim;
  final List<SensorNode> nodes;
  _CitySkylinePainter(this.anim, this.nodes) : super(repaint: anim);
  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value; final rng = math.Random(42);
    final skyPaint = Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [const Color(0xFF010812), DesignTokens.bg, const Color(0xFF071428)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (int i = 0; i < 40; i++) {
      final sx = rng.nextDouble() * size.width; final sy = rng.nextDouble() * size.height * 0.5;
      final sr = (rng.nextDouble() * 1.2 + 0.3);
      final twinkle = (0.4 + 0.6 * math.sin(t * math.pi * 2 + i * 0.7)).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(sx, sy), sr, starPaint..color = Colors.white.withValues(alpha: twinkle * 0.3));
    }
    const int bCount = 10; final bw = size.width / bCount;
    for (int i = 0; i < bCount; i++) {
      final h = 30.0 + rng.nextDouble() * (size.height * 0.4);
      final w = bw * 0.6; final x = i * bw; final y = size.height - h;
      final statusIdx = i % (nodes.isEmpty ? 3 : nodes.length);
      final color = nodes.isEmpty ? DesignTokens.safe : (_statusColor(nodes[statusIdx].overallStatus));
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), Paint()..color = color.withValues(alpha: 0.08));
    }
  }
  Color _statusColor(SensorStatus s) => switch (s) {
    SensorStatus.safe    => DesignTokens.safe,
    SensorStatus.warning => DesignTokens.warning,
    SensorStatus.alert   => DesignTokens.alert,
  };
  @override
  bool shouldRepaint(_) => false;
}