import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/data_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/node_search_delegate.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  final DataService _data = DataService();
  late TabController _tabController;
  String _selectedNode = 'NODE-01';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _data.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _data.removeListener(_onDataChange);
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final history = _data.history.where((h) => h.nodeId == _selectedNode).toList();

    return Scaffold(
      backgroundColor: Colors.transparent, // Global background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          
          // Node Selector
          SliverToBoxAdapter(
            child: _buildNodeSelector(),
          ),

          // Analysis Control Bar
          SliverToBoxAdapter(
            child: _buildTabBar(),
          ),

          // Charts
          if (history.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverFillRemaining(
              hasScrollBody: true,
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // Managed by tab bar
                children: [
                  _buildChart(history.map((h) => h.fire).toList(), '°C', 'FIRE/TEMP', DesignTokens.alert),
                  _buildChart(history.map((h) => h.gas).toList(), 'PPM', 'GAS LEVEL', DesignTokens.warning),
                  _buildChart(history.map((h) => h.water).toList(), 'CM', 'WATER LEVEL', DesignTokens.cyan),
                  _buildChart(history.map((h) => h.light).toList(), 'LUX', 'LUMINOSITY', const Color(0xFFA855F7)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (ctx, constraints) {
          final pct = ((constraints.maxHeight - kToolbarHeight) / (120 - kToolbarHeight)).clamp(0.0, 1.0);
          
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
                      bottom: BorderSide(color: DesignTokens.cyan.withValues(alpha: 0.15), width: 1),
                    ),
                  ),
                ),
                
                // Content
                FlexibleSpaceBar(
                  titlePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12 + pct * 8),
                  centerTitle: false,
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ANALYTICS ENGINE',
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: 16 + pct * 4,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                      if (pct > 0.5)
                        Opacity(
                          opacity: (pct - 0.5) * 2,
                          child: const Text('DATA RETRIEVAL: ACTIVE',
                            style: TextStyle(
                              color: DesignTokens.cyan,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Search button
                Positioned(
                  right: 12, bottom: 8,
                  child: IconButton(
                    icon: const Icon(Icons.search_rounded, color: DesignTokens.cyan, size: 22),
                    onPressed: () => showSearch(context: context, delegate: NodeSearchDelegate()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNodeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('SELECT SOURCE'),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['NODE-01', 'NODE-02', 'NODE-03', 'NODE-04'].map((id) {
                final sel = _selectedNode == id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedNode = id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? DesignTokens.cyan.withValues(alpha: 0.12) : DesignTokens.card.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? DesignTokens.cyan.withValues(alpha: 0.6) : DesignTokens.border.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Text(id,
                      style: TextStyle(
                        color: sel ? DesignTokens.cyan : DesignTokens.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'RobotoMono',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: DesignTokens.card.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.border.withValues(alpha: 0.4)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: _GlowTabIndicator(color: DesignTokens.cyan),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: DesignTokens.cyan,
        unselectedLabelColor: DesignTokens.textMuted,
        tabs: const [
          Tab(text: 'FIRE'), Tab(text: 'GAS'), Tab(text: 'WATER'), Tab(text: 'LIGHT'),
        ],
        labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'RobotoMono', letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.query_stats_rounded, size: 48, color: DesignTokens.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('WAITING FOR DATA STREAM...',
            style: TextStyle(color: DesignTokens.textMuted, fontSize: 10, fontFamily: 'RobotoMono', letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<double> values, String unit, String label, Color color) {
    if (values.isEmpty) return _buildEmptyState();

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).clamp(5.0, double.infinity);

    final spots = values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        children: [
          Row(
            children: [
              _statBox('LIVE', '${values.last.toStringAsFixed(1)}$unit', color),
              const SizedBox(width: 12),
              _statBox('MIN', '${minVal.toStringAsFixed(1)}$unit', DesignTokens.textSecondary),
              const SizedBox(width: 12),
              _statBox('MAX', '${maxVal.toStringAsFixed(1)}$unit', DesignTokens.alert),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 24, 24, 12),
              decoration: BoxDecoration(
                color: DesignTokens.card.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DesignTokens.border.withValues(alpha: 0.3)),
                boxShadow: [
                  const BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 8)),
                ],
              ),
              child: LineChart(
                LineChartData(
                  minY: minVal - range * 0.2,
                  maxY: maxVal + range * 0.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: range / 4,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: DesignTokens.border.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                          style: TextStyle(color: DesignTokens.textMuted, fontSize: 8, fontFamily: 'RobotoMono'),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx % 2 != 0 || idx < 0 || idx >= _data.history.length) return const SizedBox();
                          final t = _data.history[idx].timestamp;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('${t.hour}:${t.minute.toString().padLeft(2, "0")}',
                              style: TextStyle(color: DesignTokens.textMuted, fontSize: 8, fontFamily: 'RobotoMono'),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => DesignTokens.card,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (ts) => ts.map((t) => LineTooltipItem(
                        '${t.y.toStringAsFixed(1)}$unit',
                        TextStyle(color: color, fontWeight: FontWeight.w900, fontFamily: 'RobotoMono', fontSize: 10),
                      )).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color vColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DesignTokens.card.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.border.withValues(alpha: 0.25)),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [vColor.withValues(alpha: 0.08), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 4, height: 4, decoration: BoxDecoration(color: vColor.withValues(alpha: 0.6), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: DesignTokens.textSecondary, fontSize: 8, fontWeight: FontWeight.w800, fontFamily: 'RobotoMono', letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: vColor, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'RobotoMono')),
          ],
        ),
      ),
    );
  }
}

class _GlowTabIndicator extends Decoration {
  final Color color;
  const _GlowTabIndicator({required this.color});
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _GlowPainter(color);
}

class _GlowPainter extends BoxPainter {
  final Color color;
  _GlowPainter(this.color);
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final paint = Paint()..color = color.withValues(alpha: 0.12)..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(rect.inflate(-4), const Radius.circular(8));
    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4));
  }
}
