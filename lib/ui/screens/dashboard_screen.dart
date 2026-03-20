import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_city_monitor/core/models/alert_model.dart';
import 'package:smart_city_monitor/core/services/data_service.dart';
import 'package:smart_city_monitor/ui/screens/sensor_detail_screen.dart';
import 'package:smart_city_monitor/ui/screens/history_screen.dart';
import 'package:smart_city_monitor/ui/screens/alerts_screen.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN SYSTEM  –  Refined Smart-City Palette
// ─────────────────────────────────────────────────────────────

class _DS {
  // Background layers
  static const bg        = Color(0xFF0A0D14);
  static const surface   = Color(0xFF121720);
  static const card      = Color(0xFF171E2B);
  static const cardHover = Color(0xFF1D2638);

  // Accent spectrum
  static const cyan      = Color(0xFF00E5FF);
  static const blue      = Color(0xFF2979FF);
  static const green     = Color(0xFF00E676);
  static const amber     = Color(0xFFFFAB40);
  static const red       = Color(0xFFFF5252);

  // Text
  static const textPrimary   = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8892A4);
  static const textMuted     = Color(0xFF4A5568);

  // Borders
  static const border     = Color(0xFF1E2A3C);

  // Sensor brand colors
  static Color sensorColor(AlertType t) => switch (t) {
    AlertType.water    => const Color(0xFF29B6F6),
    AlertType.fire     => const Color(0xFFFF7043),
    AlertType.light    => const Color(0xFFFFD740),
    AlertType.gas      => const Color(0xFF66BB6A),
    AlertType.distance => const Color(0xFF7E57C2),
    _ => cyan,
  };

  // Typography
  static TextStyle display(double size, {FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: weight,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle mono(double size, {Color? color}) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        color: color ?? textSecondary,
        letterSpacing: 0.5,
      );

  static TextStyle body(double size,
      {FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color ?? textSecondary,
      );

  // Durations
  static const fast   = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 280);
  static const slow   = Duration(milliseconds: 480);
}

// ─────────────────────────────────────────────────────────────
//  DASHBOARD SCREEN
// ─────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final DataService _data = DataService();

  late final AnimationController _headerAnim;
  late final AnimationController _staggerAnim;

  @override
  void initState() {
    super.initState();
    _data.addListener(_onDataChange);

    _headerAnim = AnimationController(vsync: this, duration: _DS.slow)
      ..forward();
    _staggerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() {
    _data.removeListener(_onDataChange);
    _headerAnim.dispose();
    _staggerAnim.dispose();
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _DS.bg,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              _onDataChange();
              await Future.delayed(const Duration(milliseconds: 600));
            },
            displacement: 24,
            color: _DS.cyan,
            backgroundColor: _DS.card,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _buildAppBar(),
                _buildHeroHeader(),
                _buildStatusBanner(),
                _buildSectionHeader('Sensor Network', Icons.sensors_rounded),
                _buildSensorGrid(),
                _buildSectionHeader('Active Alerts', Icons.notifications_active_rounded),
                _buildAlertsSummary(),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────

  Widget _buildAppBar() {
    final unresolvedCount =
        _data.alerts.where((a) => !a.isResolved).length;

    return SliverAppBar(
      backgroundColor: _DS.bg,
      elevation: 0,
      pinned: true,
      toolbarHeight: 64,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_DS.cyan, _DS.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_city_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'CITY\u200BMONITOR',
            style: _DS.display(18, weight: FontWeight.w800).copyWith(
              letterSpacing: 2,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [_DS.cyan, _DS.blue],
                ).createShader(const Rect.fromLTWH(0, 0, 160, 20)),
            ),
          ),
        ],
      ),
      actions: [
        _AppBarButton(
          icon: Icons.history_rounded,
          onTap: () => _navigate(const HistoryScreen()),
        ),
        _NotificationButton(
          count: unresolvedCount,
          onTap: () => _navigate(const AlertsScreen()),
        ),
        _AppBarButton(
          icon: Icons.person_outline_rounded,
          onTap: () => _showProfileSheet(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _navigate(Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, _) => screen,
        transitionsBuilder: (context, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: _DS.normal,
      ),
    );
  }

  // ── Hero Header ──────────────────────────────────────────

  Widget _buildHeroHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOutCubic)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: _DS.body(13, color: _DS.cyan, weight: FontWeight.w600)
                      .copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text('Operator', style: _DS.display(34)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _DS.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_data.alerts.length} sensors active  ·  ${_getDate(now)}',
                      style: _DS.body(13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  // ── Status Banner ────────────────────────────────────────

  Widget _buildStatusBanner() {
    final critical = _data.alerts
        .where((a) => !a.isResolved && a.severity == AlertSeverity.high)
        .length;
    final warning = _data.alerts
        .where((a) => !a.isResolved && a.severity == AlertSeverity.medium)
        .length;

    final Color accentColor;
    final String title;
    final String subtitle;
    final IconData icon;

    if (critical > 0) {
      accentColor = _DS.red;
      title = 'CRITICAL';
      subtitle = '$critical critical alert${critical > 1 ? 's' : ''} require attention';
      icon = Icons.error_rounded;
    } else if (warning > 0) {
      accentColor = _DS.amber;
      title = 'WARNING';
      subtitle = '$warning warning${warning > 1 ? 's' : ''} detected';
      icon = Icons.warning_rounded;
    } else {
      accentColor = _DS.green;
      title = 'NOMINAL';
      subtitle = 'All systems operating within safe parameters';
      icon = Icons.verified_rounded;
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: _PulsingBorder(
          color: accentColor,
          pulse: critical > 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _DS.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withAlpha((255 * 0.3).toInt()),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha((255 * 0.12).toInt()),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accentColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'STATUS: ',
                            style: _DS.mono(10, color: _DS.textMuted),
                          ),
                          Text(
                            title,
                            style: _DS.mono(10, color: accentColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: _DS.body(14, weight: FontWeight.w500)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: _DS.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Row(
          children: [
            Icon(icon, color: _DS.cyan, size: 18),
            const SizedBox(width: 8),
            Text(title, style: _DS.display(18)),
            const Spacer(),
            Text('VIEW ALL', style: _DS.mono(10, color: _DS.textMuted)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: _DS.textMuted, size: 10),
          ],
        ),
      ),
    );
  }

  // ── Sensor Grid ──────────────────────────────────────────

  static const _sensors = [
    (AlertType.water,    'Water',    Icons.water_drop_rounded),
    (AlertType.fire,     'Fire',     Icons.local_fire_department_rounded),
    (AlertType.light,    'Light',    Icons.light_mode_rounded),
    (AlertType.gas,      'Gas',      Icons.air_rounded),
    (AlertType.distance, 'Proximity',Icons.sensors_rounded),
  ];

  Widget _buildSensorGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final (type, label, icon) = _sensors[i];
            final count = _data.getSensorAlertsCount(type);

            return _StaggeredEntry(
              delay: Duration(milliseconds: 60 * i),
              controller: _staggerAnim,
              child: _SensorCard(
                label: label,
                icon: icon,
                type: type,
                alertsCount: count,
                onTap: () => _navigate(
                  SensorDetailScreen(type: type, label: label, icon: icon),
                ),
              ),
            );
          },
          childCount: _sensors.length,
        ),
      ),
    );
  }

  // ── Alerts Summary ───────────────────────────────────────

  Widget _buildAlertsSummary() {
    final unresolved = _data.alerts.where((a) => !a.isResolved).toList();

    if (unresolved.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _DS.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _DS.border),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_rounded, color: _DS.green, size: 36),
                const SizedBox(height: 10),
                Text('No Active Alerts', style: _DS.display(16)),
                const SizedBox(height: 4),
                Text('All sensors reporting normal',
                    style: _DS.body(13)),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i >= unresolved.length) return null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AlertTile(alert: unresolved[i]),
            );
          },
          childCount: math.min(unresolved.length, 3),
        ),
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────


  // ── Profile Bottom Sheet ─────────────────────────────────

  void _showProfileSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ProfileSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PROFILE SHEET
// ─────────────────────────────────────────────────────────────

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: _DS.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _DS.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _DS.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_DS.cyan, _DS.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _DS.cyan.withAlpha((255 * 0.3).toInt()),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 16),

          Text('Operator', style: _DS.display(22)),
          const SizedBox(height: 4),
          Text('admin@citymonitor.io', style: _DS.body(14)),
          const SizedBox(height: 8),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _DS.cyan.withAlpha((255 * 0.12).toInt()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _DS.cyan.withAlpha((255 * 0.3).toInt())),
            ),
            child: Text(
              'SYSTEM OPERATOR · LEVEL 3',
              style: _DS.mono(10, color: _DS.cyan),
            ),
          ),

          const SizedBox(height: 28),
          Divider(color: _DS.border, height: 1),
          const SizedBox(height: 8),

          // Menu Items
          _ProfileMenuItem(
            icon: Icons.manage_accounts_rounded,
            label: 'Account Settings',
            onTap: () {},
          ),
          _ProfileMenuItem(
            icon: Icons.notifications_active_rounded,
            label: 'Alert Preferences',
            onTap: () {},
          ),
          _ProfileMenuItem(
            icon: Icons.lock_outline_rounded,
            label: 'Security',
            onTap: () {},
          ),
          _ProfileMenuItem(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () {},
          ),

          const SizedBox(height: 8),
          Divider(color: _DS.border, height: 1),
          const SizedBox(height: 8),

          // Logout
          _ProfileMenuItem(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            color: _DS.red,
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: _DS.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _DS.red.withAlpha((255 * 0.12).toInt()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: _DS.red, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Sign Out?', style: _DS.display(22)),
              const SizedBox(height: 8),
              Text(
                'You will be redirected to the login screen.',
                style: _DS.body(14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _DS.border),
                        foregroundColor: _DS.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text('Cancel', style: _DS.body(15, weight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);
                        _performLogout(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _DS.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text('Sign Out',
                          style: _DS.body(15, weight: FontWeight.w700, color: Colors.white)),
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

  void _performLogout(BuildContext context) {
    // Pop to root and push login
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }
}

// ─────────────────────────────────────────────────────────────
//  SENSOR CARD
// ─────────────────────────────────────────────────────────────

class _SensorCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final AlertType type;
  final int alertsCount;
  final VoidCallback onTap;

  const _SensorCard({
    required this.label,
    required this.icon,
    required this.type,
    required this.alertsCount,
    required this.onTap,
  });

  @override
  State<_SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends State<_SensorCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _DS.sensorColor(widget.type);
    final hasAlerts = widget.alertsCount > 0;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: _DS.fast,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: _DS.normal,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _pressed ? _DS.cardHover : _DS.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hasAlerts
                  ? _DS.red.withAlpha((255 * 0.5).toInt())
                  : color.withAlpha((255 * 0.2).toInt()),
              width: hasAlerts ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (hasAlerts ? _DS.red : color).withAlpha((255 * 0.08).toInt()),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withAlpha((255 * 0.12).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: color, size: 22),
                    ),
                    if (hasAlerts)
                      _PulseDot(color: _DS.red)
                    else
                      _PulseDot(color: _DS.green, pulse: false),
                  ],
                ),

                // Label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label.toUpperCase(),
                      style: _DS.mono(10, color: _DS.textMuted)
                          .copyWith(letterSpacing: 1),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasAlerts
                          ? '${widget.alertsCount} Alert${widget.alertsCount > 1 ? "s" : ""}'
                          : 'Normal',
                      style: _DS.display(16, weight: FontWeight.w600).copyWith(
                        color: hasAlerts ? _DS.red : color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
//  ALERT TILE
// ─────────────────────────────────────────────────────────────

class _AlertTile extends StatelessWidget {
  final AlertModel alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isHigh = alert.severity == AlertSeverity.high;
    final color = isHigh ? _DS.red : _DS.amber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha((255 * 0.25).toInt())),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withAlpha((255 * 0.5).toInt()), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.typeLabel,
                  style: _DS.body(14, weight: FontWeight.w600,
                      color: _DS.textPrimary),
                ),
                Text(
                  alert.message,
                  style: _DS.body(12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.12).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isHigh ? 'HIGH' : 'MED',
              style: _DS.mono(10, color: color),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
//  APP BAR BUTTON
// ─────────────────────────────────────────────────────────────

class _AppBarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarButton({required this.icon, required this.onTap});

  @override
  State<_AppBarButton> createState() => _AppBarButtonState();
}

class _AppBarButtonState extends State<_AppBarButton> {
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
          width: 38,
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _DS.border),
          ),
          child: Icon(widget.icon, color: _DS.textSecondary, size: 19),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NOTIFICATION BUTTON
// ─────────────────────────────────────────────────────────────

class _NotificationButton extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationButton({required this.count, required this.onTap});

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _DS.border),
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  color: _DS.textSecondary, size: 19),
            ),
            if (widget.count > 0)
              Positioned(
                right: 2,
                top: -1,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: _DS.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: _DS.bg, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: _DS.red.withAlpha((255 * 0.4).toInt()), blurRadius: 6)
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.count > 9 ? '9+' : '${widget.count}',
                      style: _DS.body(8,
                          weight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PROFILE MENU ITEM
// ─────────────────────────────────────────────────────────────

class _ProfileMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  State<_ProfileMenuItem> createState() => _ProfileMenuItemState();
}

class _ProfileMenuItemState extends State<_ProfileMenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? _DS.textPrimary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: _DS.fast,
        color: _pressed ? _DS.surface : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha((255 * 0.08).toInt()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: color, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.label,
                style: _DS.body(15,
                    weight: FontWeight.w500,
                    color: color),
              ),
            ),
            if (widget.color == null)
              Icon(Icons.chevron_right_rounded,
                  color: _DS.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  UTILITY WIDGETS
// ─────────────────────────────────────────────────────────────

/// Pulsing border ring for critical status
class _PulsingBorder extends StatefulWidget {
  final Color color;
  final bool pulse;
  final Widget child;

  const _PulsingBorder(
      {required this.color, required this.pulse, required this.child});

  @override
  State<_PulsingBorder> createState() => _PulsingBorderState();
}

class _PulsingBorderState extends State<_PulsingBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    if (widget.pulse) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(_PulsingBorder old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.pulse) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) return widget.child;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(
              color: widget.color.withAlpha((255 * _anim.value).toInt()),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Small animated status dot
class _PulseDot extends StatefulWidget {
  final Color color;
  final bool pulse;
  const _PulseDot({required this.color, this.pulse = true});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) {
      return Container(
        width: 8,
        height: 8,
        decoration:
            BoxDecoration(color: widget.color, shape: BoxShape.circle),
      );
    }

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha((255 * 0.5).toInt()),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Staggered entry animation for grid children
class _StaggeredEntry extends StatelessWidget {
  final Duration delay;
  final AnimationController controller;
  final Widget child;

  const _StaggeredEntry({
    required this.delay,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = delay.inMilliseconds / controller.duration!.inMilliseconds;
    final end = math.min(start + 0.4, 1.0);

    final opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
