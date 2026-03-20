import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_city_monitor/core/models/alert_model.dart';
import 'package:smart_city_monitor/core/models/history_entry.dart';
import 'package:smart_city_monitor/core/services/data_service.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN SYSTEM  –  mirrors dashboard_screen.dart tokens
// ─────────────────────────────────────────────────────────────

class _DS {
  static const bg        = Color(0xFF0A0D14);
  static const surface   = Color(0xFF121720);
  static const card      = Color(0xFF171E2B);

  static const cyan      = Color(0xFF00E5FF);
  static const red       = Color(0xFFFF5252);

  static const textPrimary   = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8892A4);
  static const textMuted     = Color(0xFF4A5568);
  static const border        = Color(0xFF1E2A3C);

  // Per-sensor palette (must mirror dashboard)
  static const sensorMeta = [
    _SensorMeta(AlertType.water,    'Water',     Icons.water_drop_rounded,              Color(0xFF29B6F6), 'cm',  'Water Level'),
    _SensorMeta(AlertType.fire,     'Fire',      Icons.local_fire_department_rounded,   Color(0xFFFF7043), '°C',  'Temperature'),
    _SensorMeta(AlertType.light,    'Light',     Icons.light_mode_rounded,              Color(0xFFFFD740), 'lux', 'Luminosity'),
    _SensorMeta(AlertType.gas,      'Gas',       Icons.air_rounded,                     Color(0xFF66BB6A), 'ppm', 'Gas Level'),
    _SensorMeta(AlertType.distance, 'Proximity', Icons.sensors_rounded,                 Color(0xFF7E57C2), 'cm',  'Distance'),
  ];

  // Typography
  static TextStyle display(double size, {FontWeight w = FontWeight.w700, Color? color}) =>
      GoogleFonts.rajdhani(fontSize: size, fontWeight: w, color: color ?? textPrimary, letterSpacing: -0.3);

  static TextStyle mono(double size, {Color? color}) =>
      GoogleFonts.spaceMono(fontSize: size, color: color ?? textSecondary, letterSpacing: 0.5);

  static TextStyle body(double size, {FontWeight w = FontWeight.w500, Color? color}) =>
      GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color ?? textSecondary);

  static const fast   = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 280);
}

class _SensorMeta {
  final AlertType type;
  final String label;
  final IconData icon;
  final Color color;
  final String unit;
  final String chartLabel;
  const _SensorMeta(this.type, this.label, this.icon, this.color, this.unit, this.chartLabel);
}

// ─────────────────────────────────────────────────────────────
//  HISTORY SCREEN
// ─────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final DataService _data = DataService();
  late final TabController _tabController;

  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  bool _searchExpanded = false;
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _DS.sensorMeta.length, vsync: this);
    _data.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _data.removeListener(_onDataChange);
    _searchFocus.dispose();
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  List<HistoryEntry> get _filtered => _data.history.where((h) {
    if (_selectedDateRange != null) {
      if (h.timestamp.isBefore(_selectedDateRange!.start) ||
          h.timestamp.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
        return false;
      }
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      if (!h.nodeId.toLowerCase().contains(q) &&
          !h.nodeLocation.toLowerCase().contains(q)) {
        return false;
      }
    }
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _DS.bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildSearchBar(),
              _buildTabBar(),
              const SizedBox(height: 4),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────

  Widget _buildTopBar() {
    final hasRange = _selectedDateRange != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sensor History', style: _DS.display(22)),
                Text(
                  hasRange
                      ? '${_fmtDate(_selectedDateRange!.start)} – ${_fmtDate(_selectedDateRange!.end)}'
                      : 'All recorded readings',
                  style: _DS.mono(10,
                      color: hasRange ? _DS.cyan : _DS.textMuted),
                ),
              ],
            ),
          ),
          // Search toggle
          _IconBtn(
            icon: _searchExpanded
                ? Icons.search_off_rounded
                : Icons.search_rounded,
            active: _searchExpanded,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _searchExpanded = !_searchExpanded;
                if (!_searchExpanded) {
                  _searchQuery = '';
                  _searchFocus.unfocus();
                } else {
                  Future.delayed(_DS.normal, _searchFocus.requestFocus);
                }
              });
            },
          ),
          const SizedBox(width: 4),
          // Calendar
          _IconBtn(
            icon: hasRange
                ? Icons.calendar_month_rounded
                : Icons.calendar_today_rounded,
            active: hasRange,
            activeColor: _DS.cyan,
            onTap: () => _pickDateRange(),
          ),
          if (hasRange) ...[
            const SizedBox(width: 4),
            _IconBtn(
              icon: Icons.close_rounded,
              activeColor: _DS.red,
              active: true,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedDateRange = null);
              },
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────

  Widget _buildSearchBar() {
    return AnimatedSize(
      duration: _DS.normal,
      curve: Curves.easeOutCubic,
      child: _searchExpanded
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                decoration: BoxDecoration(
                  color: _DS.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _searchQuery.isNotEmpty
                        ? _DS.cyan.withValues(alpha: 0.4)
                        : _DS.border,
                  ),
                ),
                child: TextField(
                  focusNode: _searchFocus,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: _DS.body(14, color: _DS.textPrimary),
                  cursorColor: _DS.cyan,
                  decoration: InputDecoration(
                    hintText: 'Search Node ID or Location…',
                    hintStyle: _DS.body(14, color: _DS.textMuted),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: _DS.cyan, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: _DS.textMuted, size: 18),
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _DS.sensorMeta.length,
          itemBuilder: (context, i) {
            return AnimatedBuilder(
              animation: _tabController.animation!,
              builder: (_, unusedChild) {
                final selected = _tabController.index == i;
                final meta = _DS.sensorMeta[i];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _tabController.animateTo(i);
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: _DS.normal,
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    decoration: BoxDecoration(
                      color: selected
                          ? meta.color.withValues(alpha: 0.15)
                          : _DS.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? meta.color.withValues(alpha: 0.5)
                            : _DS.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(meta.icon,
                            size: 15,
                            color: selected ? meta.color : _DS.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          meta.label,
                          style: _DS.body(13,
                              w: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? meta.color : _DS.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ── Tab Content ───────────────────────────────────────────

  Widget _buildTabContent() {
    final history = _filtered;
    if (history.isEmpty) return _buildEmptyState();

    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(),
      children: _DS.sensorMeta.map((meta) {
        return _ChartPage(
          key: ValueKey(meta.type),
          history: history,
          meta: meta,
        );
      }).toList(),
    );
  }

  // ── Empty State ───────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _DS.card,
              shape: BoxShape.circle,
              border: Border.all(color: _DS.border),
            ),
            child: const Icon(Icons.analytics_outlined,
                size: 36, color: _DS.textMuted),
          ),
          const SizedBox(height: 20),
          Text('No Data Found', style: _DS.display(20)),
          const SizedBox(height: 6),
          Text('Try adjusting your filters or date range',
              style: _DS.body(13)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() {
              _selectedDateRange = null;
              _searchQuery = '';
            }),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _DS.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _DS.cyan.withValues(alpha: 0.3)),
              ),
              child: Text('Clear Filters',
                  style: _DS.body(13, color: _DS.cyan, w: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]}';
  }

  Future<void> _pickDateRange() async {
    HapticFeedback.selectionClick();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _DS.cyan,
            surface: _DS.card,
            onSurface: _DS.textPrimary,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: _DS.card),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }
}

// ─────────────────────────────────────────────────────────────
//  CHART PAGE
// ─────────────────────────────────────────────────────────────

class _ChartPage extends StatefulWidget {
  final List<HistoryEntry> history;
  final _SensorMeta meta;

  const _ChartPage({super.key, required this.history, required this.meta});

  @override
  State<_ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<_ChartPage>
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

  double _getValue(HistoryEntry h) => switch (widget.meta.type) {
    AlertType.fire     => h.fire,
    AlertType.gas      => h.gas,
    AlertType.water    => h.water,
    AlertType.light    => h.light,
    AlertType.distance => h.hcSr04,
    _ => 0.0,
  };

  @override
  Widget build(BuildContext context) {
    final values = widget.history.map(_getValue).toList();
    if (values.isEmpty) return const SizedBox();

    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final avgVal = values.reduce((a, b) => a + b) / values.length;
    final lastVal = values.last;

    final reversed = values.reversed.toList();
    final spots = reversed.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final color = widget.meta.color;
    final unit  = widget.meta.unit;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Stat Row ──────────────────────────────────────
          Row(children: [
            _StatCard(
              label: 'CURRENT',
              value: '${lastVal.toStringAsFixed(1)}$unit',
              color: color,
              highlight: true,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'MIN',
              value: '${minVal.toStringAsFixed(1)}$unit',
              color: _DS.textSecondary,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'MAX',
              value: '${maxVal.toStringAsFixed(1)}$unit',
              color: _DS.textSecondary,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'AVG',
              value: '${avgVal.toStringAsFixed(1)}$unit',
              color: _DS.textSecondary,
            ),
          ]),

          const SizedBox(height: 24),

          // ── Chart Label ───────────────────────────────────
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${widget.meta.chartLabel} Trend',
                style: _DS.display(17),
              ),
              const Spacer(),
              Text(
                '${widget.history.length} READINGS',
                style: _DS.mono(9, color: _DS.textMuted),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Line Chart ────────────────────────────────────
          Container(
            height: 260,
            padding: const EdgeInsets.fromLTRB(0, 20, 16, 8),
            decoration: BoxDecoration(
              color: _DS.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _DS.border),
            ),
            child: LineChart(
              LineChartData(
                minY: (minVal - (maxVal - minVal) * 0.15).clamp(0, double.infinity),
                maxY: maxVal + (maxVal - minVal) * 0.15 + 1,
                clipData: const FlClipData.all(),
                lineTouchData: LineTouchData(
                  touchCallback: (event, resp) {
                    // Touch handling
                  },
                  getTouchedSpotIndicator: (_, indicators) =>
                      indicators.map((i) => TouchedSpotIndicatorData(
                        FlLine(color: color, strokeWidth: 1.5,
                            dashArray: [4, 4]),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                                radius: 5,
                                color: color,
                                strokeWidth: 2,
                                strokeColor: _DS.bg,
                              ),
                        ),
                      )).toList(),
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => _DS.surface,
                    tooltipRoundedRadius: 10,
                    tooltipBorder: BorderSide(
                        color: color.withValues(alpha: 0.4), width: 1),
                    getTooltipItems: (spots) => spots.map((s) {
                      final idx = reversed.length - 1 - s.spotIndex;
                      final t = idx >= 0 && idx < widget.history.length
                          ? widget.history[idx].timestamp
                          : null;
                      return LineTooltipItem(
                        '${s.y.toStringAsFixed(1)}$unit',
                        _DS.display(14, w: FontWeight.w700, color: color),
                        children: t != null
                            ? [
                                TextSpan(
                                  text:
                                      '\n${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                                  style: _DS.mono(9, color: _DS.textMuted),
                                )
                              ]
                            : [],
                      );
                    }).toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: _DS.border.withValues(alpha: 0.6),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(0),
                        style: _DS.mono(9, color: _DS.textMuted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 ||
                            idx >= reversed.length ||
                            idx % math.max(1, reversed.length ~/ 5) != 0) {
                          return const SizedBox();
                        }
                        final srcIdx = widget.history.length - 1 - idx;
                        if (srcIdx < 0 || srcIdx >= widget.history.length) {
                          return const SizedBox();
                        }
                        final t = widget.history[srcIdx].timestamp;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                            style: _DS.mono(8, color: _DS.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.18),
                          color.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            ),
          ),

          const SizedBox(height: 24),

          // ── Distribution Bar ──────────────────────────────
          _buildDistributionSection(values, minVal, maxVal, color, unit),

          const SizedBox(height: 24),

          // ── Recent Readings List ──────────────────────────
          _buildRecentList(reversed, color, unit),

          const SizedBox(height: 20),

          // ── Info Banner ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _DS.cyan.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _DS.cyan.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: _DS.cyan, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sampled every 5 minutes from active sector nodes.',
                    style: _DS.body(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSection(
    List<double> values, double min, double max, Color color, String unit) {
    if (max == min) return const SizedBox();

    // Bucket into 5 ranges
    final buckets = List<int>.filled(5, 0);
    final range = max - min;
    for (final v in values) {
      final idx = ((v - min) / range * 4.99).floor().clamp(0, 4);
      buckets[idx]++;
    }
    final peak = buckets.reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 18,
                decoration: BoxDecoration(color: color,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text('Value Distribution', style: _DS.display(17)),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _DS.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _DS.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (i) {
              final frac = peak == 0 ? 0.0 : buckets[i] / peak;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text(
                        buckets[i].toString(),
                        style: _DS.mono(9, color: color),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 400 + i * 60),
                        curve: Curves.easeOutCubic,
                        height: 80 * frac + 4,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15 + frac * 0.35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: color.withValues(alpha: 0.3), width: 1),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (min + (range / 5) * i).toStringAsFixed(0),
                        style: _DS.mono(8, color: _DS.textMuted),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentList(List<double> reversed, Color color, String unit) {
    final count = math.min(5, reversed.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 18,
                decoration: BoxDecoration(color: color,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text('Recent Readings', style: _DS.display(17)),
            const Spacer(),
            Text('LATEST $count', style: _DS.mono(9, color: _DS.textMuted)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _DS.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _DS.border),
          ),
          child: Column(
            children: List.generate(count, (i) {
              final val = reversed[i];
              final srcIdx = widget.history.length - 1 - i;
              final entry = srcIdx >= 0 ? widget.history[srcIdx] : null;
              final isFirst = i == 0;
              final isLast = i == count - 1;

              return Container(
                decoration: BoxDecoration(
                  border: isLast ? null : const Border(
                    bottom: BorderSide(color: _DS.border, width: 1),
                  ),
                  borderRadius: isFirst
                      ? const BorderRadius.vertical(top: Radius.circular(20))
                      : isLast
                          ? const BorderRadius.vertical(bottom: Radius.circular(20))
                          : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isFirst ? color : color.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (entry != null)
                            Text(
                              entry.nodeId,
                              style: _DS.body(13, color: _DS.textPrimary,
                                  w: FontWeight.w600),
                            ),
                          if (entry != null)
                            Text(
                              entry.nodeLocation,
                              style: _DS.mono(10, color: _DS.textMuted),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${val.toStringAsFixed(2)}$unit',
                          style: _DS.display(15, color: isFirst ? color : _DS.textSecondary),
                        ),
                        if (entry != null)
                          Text(
                            '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                            style: _DS.mono(9, color: _DS.textMuted),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  STAT CARD
// ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool highlight;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: highlight ? color.withValues(alpha: 0.12) : _DS.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight ? color.withValues(alpha: 0.4) : _DS.border,
            width: highlight ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _DS.mono(8, color: highlight ? color.withValues(alpha: 0.7) : _DS.textMuted)),
            const SizedBox(height: 5),
            Text(
              value,
              style: _DS.display(14, w: FontWeight.w700,
                  color: highlight ? color : _DS.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
  final bool active;
  final Color? activeColor;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.activeColor ?? _DS.cyan;
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
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: widget.active
                ? accent.withValues(alpha: 0.12)
                : _DS.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: widget.active ? accent.withValues(alpha: 0.4) : _DS.border,
              width: widget.active ? 1.5 : 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: widget.active ? accent : _DS.textSecondary,
            size: 18,
          ),
        ),
      ),
    );
  }
}
