import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_city_monitor/core/models/alert_model.dart';
import 'package:smart_city_monitor/core/services/data_service.dart';
import 'package:smart_city_monitor/ui/screens/agent_detail_screen.dart';

// ─────────────────────────────────────────────────────────────
//  LOCAL DESIGN SYSTEM  (mirrors dashboard_screen.dart _DS)
// ─────────────────────────────────────────────────────────────

class _DS {
  static const bg      = Color(0xFF0A0D14);
  static const surface = Color(0xFF121720);
  static const card    = Color(0xFF171E2B);

  static const cyan   = Color(0xFF00E5FF);
  static const green  = Color(0xFF00E676);
  static const amber  = Color(0xFFFFAB40);
  static const red    = Color(0xFFFF5252);

  static const textPrimary   = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8892A4);
  static const textMuted     = Color(0xFF4A5568);
  static const border        = Color(0xFF1E2A3C);

  static Color severityColor(AlertSeverity s) => switch (s) {
    AlertSeverity.high   => red,
    AlertSeverity.medium => amber,
    AlertSeverity.low    => green,
    _ => cyan,
  };

  static String severityLabel(AlertSeverity s) => switch (s) {
    AlertSeverity.high   => 'CRITICAL',
    AlertSeverity.medium => 'WARNING',
    AlertSeverity.low    => 'LOW',
    _ => 'INFO',
  };

  static IconData severityIcon(AlertSeverity s) => switch (s) {
    AlertSeverity.high   => Icons.error_rounded,
    AlertSeverity.medium => Icons.warning_rounded,
    AlertSeverity.low    => Icons.info_rounded,
    _ => Icons.notifications_rounded,
  };

  static TextStyle display(double size, {FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.rajdhani(fontSize: size, fontWeight: weight, color: textPrimary, letterSpacing: -0.3);

  static TextStyle mono(double size, {Color? color}) =>
      GoogleFonts.spaceMono(fontSize: size, color: color ?? textSecondary, letterSpacing: 0.5);

  static TextStyle body(double size, {FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color ?? textSecondary);

  static const fast   = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 260);
  static const slow   = Duration(milliseconds: 460);
}

// ─────────────────────────────────────────────────────────────
//  FILTER ENUM
// ─────────────────────────────────────────────────────────────

enum _Filter { all, active, resolved }

// ─────────────────────────────────────────────────────────────
//  ALERTS SCREEN
// ─────────────────────────────────────────────────────────────

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with TickerProviderStateMixin {
  final DataService _data = DataService();
  _Filter _filter = _Filter.all;

  late final AnimationController _entryAnim;
  late final AnimationController _listAnim;

  @override
  void initState() {
    super.initState();
    _data.addListener(_onDataChange);
    _entryAnim = AnimationController(vsync: this, duration: _DS.slow)..forward();
    _listAnim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() {
    _data.removeListener(_onDataChange);
    _entryAnim.dispose();
    _listAnim.dispose();
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  void _setFilter(_Filter f) {
    if (_filter == f) return;
    HapticFeedback.selectionClick();
    setState(() => _filter = f);
    _listAnim
      ..reset()
      ..forward();
  }

  List<AlertModel> get _filtered => switch (_filter) {
    _Filter.all      => _data.alerts,
    _Filter.active   => _data.alerts.where((a) => !a.isResolved).toList(),
    _Filter.resolved => _data.alerts.where((a) =>  a.isResolved).toList(),
  };

  int get _criticalCount =>
      _data.alerts.where((a) => !a.isResolved && a.severity == AlertSeverity.high).length;

  int get _activeCount  =>
      _data.alerts.where((a) => !a.isResolved).length;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _DS.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              _buildStatsRow(),
              _buildFilterBar(),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────

  Widget _buildAppBar() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryAnim, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('INCIDENT', style: _DS.mono(10, color: _DS.cyan).copyWith(letterSpacing: 2)),
                  Text('Alert Logs', style: _DS.display(26)),
                ],
              ),
            ),
            // Resolve-all button (only when active alerts exist)
            if (_activeCount > 0)
              _ResolveAllButton(
                onTap: () => _confirmResolveAll(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────

  Widget _buildStatsRow() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryAnim, curve: const Interval(0.15, 0.75, curve: Curves.easeOut)),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryAnim, curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Row(
            children: [
              _StatChip(value: _data.alerts.length, label: 'Total',    color: _DS.cyan),
              const SizedBox(width: 10),
              _StatChip(value: _activeCount,        label: 'Active',   color: _DS.amber),
              const SizedBox(width: 10),
              _StatChip(value: _criticalCount,      label: 'Critical', color: _DS.red),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter Bar ───────────────────────────────────────────

  Widget _buildFilterBar() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryAnim, curve: const Interval(0.3, 0.9, curve: Curves.easeOut)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(
          children: [
            _FilterChip(label: 'All',      value: _Filter.all,      group: _filter, onTap: _setFilter,
                count: _data.alerts.length),
            const SizedBox(width: 8),
            _FilterChip(label: 'Active',   value: _Filter.active,   group: _filter, onTap: _setFilter,
                count: _activeCount),
            const SizedBox(width: 8),
            _FilterChip(label: 'Resolved', value: _Filter.resolved, group: _filter, onTap: _setFilter,
                count: _data.alerts.where((a) => a.isResolved).length),
          ],
        ),
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────

  Widget _buildList() {
    final items = _filtered;

    if (items.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final start = math.min(i * 0.08, 0.6);
        final end   = math.min(start + 0.4, 1.0);

        final opacity = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _listAnim, curve: Interval(start, end, curve: Curves.easeOut)),
        );
        final slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(parent: _listAnim, curve: Interval(start, end, curve: Curves.easeOutCubic)),
        );

        return FadeTransition(
          opacity: opacity,
          child: SlideTransition(
            position: slide,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AlertCard(
                alert: items[i],
                onResolve: items[i].isResolved
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        _data.resolveAlert(items[i].id);
                      },
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Empty State ──────────────────────────────────────────

  Widget _buildEmptyState() {
    final isFiltered = _filter != _Filter.all;
    return Center(
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _DS.green.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_rounded, color: _DS.green, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No Results' : 'All Clear',
              style: _DS.display(24),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'No alerts match this filter'
                  : 'No anomalies detected in the network',
              style: _DS.body(14),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: 20),
              _TextButton(
                label: 'Show All Alerts',
                onTap: () => _setFilter(_Filter.all),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Confirm Resolve All ──────────────────────────────────

  void _confirmResolveAll() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        title: 'Resolve All Alerts',
        subtitle: 'Mark all $_activeCount active alert${_activeCount > 1 ? "s" : ""} as resolved?',
        confirmLabel: 'Resolve All',
        confirmColor: _DS.amber,
        icon: Icons.done_all_rounded,
        onConfirm: () {
          Navigator.pop(context);
          for (final a in _data.alerts.where((a) => !a.isResolved)) {
            _data.resolveAlert(a.id);
          }
          HapticFeedback.mediumImpact();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ALERT CARD
// ─────────────────────────────────────────────────────────────

class _AlertCard extends StatefulWidget {
  final AlertModel alert;
  final VoidCallback? onResolve;

  const _AlertCard({required this.alert, this.onResolve});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final a       = widget.alert;
    final color   = a.isResolved ? _DS.textMuted : _DS.severityColor(a.severity);
    final isHigh  = a.severity == AlertSeverity.high && !a.isResolved;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _expanded = !_expanded);
      },
      child: AnimatedContainer(
        duration: _DS.normal,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _DS.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: a.isResolved
                ? _DS.border
                : color.withValues(alpha: isHigh ? 0.45 : 0.25),
            width: isHigh ? 1.5 : 1,
          ),
          boxShadow: a.isResolved
              ? []
              : [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // Main row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: a.isResolved ? 0.06 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_DS.severityIcon(a.severity),
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                a.typeLabel,
                                style: _DS.body(15,
                                    weight: FontWeight.w600,
                                    color: a.isResolved
                                        ? _DS.textSecondary
                                        : _DS.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _SeverityBadge(
                              label: a.isResolved
                                  ? 'RESOLVED'
                                  : _DS.severityLabel(a.severity),
                              color: a.isResolved ? _DS.green : color,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.message,
                          style: _DS.body(13),
                          maxLines: _expanded ? null : 1,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Meta row
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 12, color: _DS.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(a.timestamp),
                              style: _DS.mono(10, color: _DS.textMuted),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.sensors_rounded,
                                size: 12, color: _DS.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              a.nodeId,
                              style: _DS.mono(10, color: _DS.textMuted),
                            ),
                            if (a.hasBeenDispatched) ...[
                              const SizedBox(width: 12),
                              Flexible(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentDetailScreen()));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _DS.amber.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.flash_on_rounded, size: 10, color: _DS.amber),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text('AGENT NOTIFIED', 
                                            style: _DS.mono(9, color: _DS.amber).copyWith(fontWeight: FontWeight.w700),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand chevron
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 2),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: _DS.normal,
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: _DS.textMuted, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Expanded actions
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildActions(a, color),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: _DS.normal,
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(AlertModel a, Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _DS.border)),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          // Additional info pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _DS.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: _DS.textMuted),
                const SizedBox(width: 5),
                Text('Alert #${a.id.substring(0, math.min(6, a.id.length)).toUpperCase()}',
                    style: _DS.mono(10)),
              ],
            ),
          ),
          const Spacer(),
          if (widget.onResolve != null)
            _ResolveButton(onTap: widget.onResolve!),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now  = DateTime.now();
    final diff = now.difference(t);

    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inHours   < 1)  return '${diff.inMinutes}m ago';
    if (diff.inDays    < 1)  return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';

    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${t.day} ${months[t.month - 1]}';
  }
}

// ─────────────────────────────────────────────────────────────
//  SMALL COMPONENTS
// ─────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _StatChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: _DS.display(22).copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: _DS.mono(10, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final _Filter value;
  final _Filter group;
  final Function(_Filter) onTap;
  final int count;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.group,
    required this.onTap,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final active = group == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: _DS.normal,
          curve: Curves.easeOutCubic,
          height: 42,
          decoration: BoxDecoration(
            color: active ? _DS.cyan.withValues(alpha: 0.12) : _DS.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: active ? _DS.cyan.withValues(alpha: 0.5) : _DS.border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: _DS.body(13,
                    weight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? _DS.cyan : _DS.textSecondary),
              ),
              const SizedBox(width: 5),
              AnimatedContainer(
                duration: _DS.normal,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? _DS.cyan.withValues(alpha: 0.2)
                      : _DS.textMuted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: _DS.mono(9,
                      color: active ? _DS.cyan : _DS.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SeverityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: _DS.mono(9, color: color)),
    );
  }
}

class _ResolveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ResolveButton({required this.onTap});

  @override
  State<_ResolveButton> createState() => _ResolveButtonState();
}

class _ResolveButtonState extends State<_ResolveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: _DS.fast,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _DS.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _DS.green.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, color: _DS.green, size: 15),
              const SizedBox(width: 6),
              Text('Resolve',
                  style: _DS.body(13, weight: FontWeight.w600, color: _DS.green)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResolveAllButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ResolveAllButton({required this.onTap});

  @override
  State<_ResolveAllButton> createState() => _ResolveAllButtonState();
}

class _ResolveAllButtonState extends State<_ResolveAllButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: _DS.fast,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: _DS.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _DS.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.done_all_rounded, color: _DS.amber, size: 16),
              const SizedBox(width: 6),
              Text('Resolve All',
                  style: _DS.body(12, weight: FontWeight.w600, color: _DS.amber)),
            ],
          ),
        ),
      ),
    );
  }
}

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
          width: 40,
          height: 40,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _DS.border),
          ),
          child: Icon(widget.icon, color: _DS.textSecondary, size: 17),
        ),
      ),
    );
  }
}

class _TextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: _DS.cyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _DS.cyan.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: _DS.body(14, weight: FontWeight.w600, color: _DS.cyan)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CONFIRM BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _ConfirmSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String confirmLabel;
  final Color confirmColor;
  final IconData icon;
  final VoidCallback onConfirm;

  const _ConfirmSheet({
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.confirmColor,
    required this.icon,
    required this.onConfirm,
  });

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
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: _DS.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: confirmColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: confirmColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title, style: _DS.display(22)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(subtitle,
                style: _DS.body(14), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _DS.border),
                      foregroundColor: _DS.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Cancel',
                        style: _DS.body(15, weight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(confirmLabel,
                        style: _DS.body(15,
                            weight: FontWeight.w700, color: Colors.white)),
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
