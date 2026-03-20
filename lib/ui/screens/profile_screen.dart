import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_city_monitor/core/services/data_service.dart';
import 'package:smart_city_monitor/ui/screens/agent_detail_screen.dart';


// ─────────────────────────────────────────────────────────────
//  DESIGN SYSTEM
// ─────────────────────────────────────────────────────────────
class _DS {
  static const bg      = Color(0xFF0A0D14);
  static const surface = Color(0xFF121720);
  static const card    = Color(0xFF171E2B);

  static const cyan    = Color(0xFF00E5FF);
  static const blue    = Color(0xFF2979FF);
  static const green   = Color(0xFF00E676);
  static const amber   = Color(0xFFFFAB40);
  static const red     = Color(0xFFFF5252);

  static const textPrimary   = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8892A4);
  static const textMuted     = Color(0xFF4A5568);
  static const border        = Color(0xFF1E2A3C);

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
  static const normal = Duration(milliseconds: 280);
}

// ─────────────────────────────────────────────────────────────
//  PROFILE SCREEN
// ─────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final VoidCallback onLogout;
  final VoidCallback onSimulateDisconnect;

  const ProfileScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
    required this.onLogout,
    required this.onSimulateDisconnect,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data   = DataService();
    final isDark = widget.themeMode == ThemeMode.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _DS.bg,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildProfileHero(),
              _buildSystemOverview(data),
              _buildSectionGap(),
              _buildPreferences(isDark),
              _buildSectionGap(),
              _buildDangerZone(),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
        child: Row(
          children: [
            Expanded(child: Text('Settings', style: _DS.display(22))),
          ],
        ),
      ),
    );
  }

  // ── Profile Hero ─────────────────────────────────────────
  Widget _buildProfileHero() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _DS.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _DS.border),
              gradient: LinearGradient(
                colors: [_DS.cyan.withValues(alpha: 0.06), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Avatar with glow
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_DS.cyan, _DS.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _DS.cyan.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Operator #742', style: _DS.display(20)),
                      const SizedBox(height: 4),
                      Text('System Administrator',
                          style: _DS.body(13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _DS.cyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _DS.cyan.withValues(alpha: 0.3)),
                        ),
                        child: Text('CLEARANCE · LEVEL 3',
                            style: _DS.mono(9, color: _DS.cyan)),
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

  // ── System Overview ──────────────────────────────────────
  Widget _buildSystemOverview(DataService data) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('System Overview'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _MetricCard(
                  icon: Icons.dns_rounded,
                  label: 'NODES',
                  value: '${data.nodes.length}',
                  color: _DS.cyan,
                ),
                const SizedBox(width: 10),
                _MetricCard(
                  icon: Icons.speed_rounded,
                  label: 'LATENCY',
                  value: '14ms',
                  color: _DS.green,
                ),
                const SizedBox(width: 10),
                _MetricCard(
                  icon: Icons.update_rounded,
                  label: 'UPTIME',
                  value: '4d 12h',
                  color: _DS.amber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Preferences ──────────────────────────────────────────
  Widget _buildPreferences(bool isDark) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Preferences'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: _DS.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _DS.border),
              ),
              child: Column(
                children: [
                  // Dark mode toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: _DS.cyan.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.dark_mode_rounded,
                              color: _DS.cyan, size: 19),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dark Mode',
                                  style: _DS.body(14,
                                      w: FontWeight.w600,
                                      color: _DS.textPrimary)),
                              Text('OLED-friendly interface',
                                  style: _DS.mono(9, color: _DS.textMuted)),
                            ],
                          ),
                        ),
                        _ToggleSwitch(
                          value: isDark,
                          onChanged: (_) {
                            HapticFeedback.selectionClick();
                            widget.onToggleTheme();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: _DS.border),
                  _SettingsRow(
                    icon: Icons.shield_rounded,
                    label: 'Emergency Contacts',
                    subtitle: 'View agent & dispatch history',
                    iconColor: _DS.amber,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentDetailScreen()));
                    },
                  ),
                  const Divider(height: 1, color: _DS.border),
                  _SettingsRow(
                    icon: Icons.wifi_off_rounded,
                    label: 'Simulate Disconnect',
                    subtitle: 'Test offline behaviour',
                    iconColor: _DS.amber,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onSimulateDisconnect();
                    },
                  ),
                  const Divider(height: 1, color: _DS.border),
                  _SettingsRow(
                    icon: Icons.notifications_active_rounded,
                    label: 'Alert Preferences',
                    subtitle: 'Manage notification rules',
                    iconColor: _DS.blue,
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: _DS.border),
                  _SettingsRow(
                    icon: Icons.lock_outline_rounded,
                    label: 'Security',
                    subtitle: 'Access codes & sessions',
                    iconColor: _DS.green,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Danger Zone ──────────────────────────────────────────
  Widget _buildDangerZone() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Account'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: _DS.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _DS.red.withValues(alpha: 0.2)),
              ),
              child: _SettingsRow(
                icon: Icons.logout_rounded,
                label: 'Log Out Session',
                subtitle: 'Return to login screen',
                iconColor: _DS.red,
                labelColor: _DS.red,
                showChevron: false,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _confirmLogout();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionGap() =>
      const SliverToBoxAdapter(child: SizedBox(height: 28));

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 0, 12),
      child: Text(
        title.toUpperCase(),
        style: _DS.mono(10, color: _DS.textMuted),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: _DS.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: _DS.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: _DS.red, size: 28),
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
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Cancel',
                          style: _DS.body(15, w: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);
                        widget.onLogout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _DS.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Sign Out',
                          style: _DS.body(15,
                              w: FontWeight.w700, color: Colors.white)),
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

// ─────────────────────────────────────────────────────────────
//  METRIC CARD
// ─────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: _DS.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: _DS.display(18, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: _DS.mono(8, color: _DS.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SETTINGS ROW
// ─────────────────────────────────────────────────────────────
class _SettingsRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final Color? labelColor;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
    this.labelColor,
    this.showChevron = true,
  });

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: _DS.fast,
        color: _pressed ? _DS.surface.withValues(alpha: 0.5) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: widget.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label,
                      style: _DS.body(14,
                          w: FontWeight.w600,
                          color: widget.labelColor ?? _DS.textPrimary)),
                  Text(widget.subtitle,
                      style: _DS.mono(9, color: _DS.textMuted)),
                ],
              ),
            ),
            if (widget.showChevron)
              const Icon(Icons.chevron_right_rounded,
                  color: _DS.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TOGGLE SWITCH
// ─────────────────────────────────────────────────────────────
class _ToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: _DS.normal,
        width: 48,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? _DS.cyan.withValues(alpha: 0.2) : _DS.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? _DS.cyan.withValues(alpha: 0.5) : _DS.border,
            width: 1.5,
          ),
        ),
        child: AnimatedAlign(
          duration: _DS.normal,
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value ? _DS.cyan : _DS.textMuted,
              shape: BoxShape.circle,
              boxShadow: value
                  ? [BoxShadow(color: _DS.cyan.withValues(alpha: 0.4), blurRadius: 6)]
                  : [],
            ),
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
