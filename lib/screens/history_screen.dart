import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/alert_model.dart';
import '../models/history_entry.dart';
import '../services/data_service.dart';
import '../theme/design_tokens.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final DataService _data = DataService();
  late TabController _tabController;
  
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: DesignTokens.primary,
              surface: DesignTokens.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter history based on search query, date range and selected node (if any)
    var history = _data.history.where((h) {
      // Date range filter
      if (_selectedDateRange != null) {
        if (h.timestamp.isBefore(_selectedDateRange!.start) || 
            h.timestamp.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      
      // Node/Sensor Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!h.nodeId.toLowerCase().contains(q)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('Sensor History'),
        actions: [
          IconButton(
            icon: Icon(_selectedDateRange == null ? Icons.calendar_today_rounded : Icons.calendar_month_rounded, 
              color: _selectedDateRange == null ? DesignTokens.textPrimary : DesignTokens.primary),
            onPressed: () => _selectDateRange(context),
          ),
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded, color: DesignTokens.alert),
              onPressed: () => setState(() => _selectedDateRange = null),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by Node ID...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: DesignTokens.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DesignTokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DesignTokens.border),
                ),
              ),
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: 'Water'),
              Tab(text: 'Fire'),
              Tab(text: 'LDR'),
              Tab(text: 'MQ2'),
              Tab(text: 'HC-SR04'),
            ],
          ),

          // Content
          Expanded(
            child: history.isEmpty
                ? _buildEmptyState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildChartPage(history, AlertType.water, 'cm', 'Water Level', Colors.blue),
                      _buildChartPage(history, AlertType.fire, '°C', 'Temperature', DesignTokens.alert),
                      _buildChartPage(history, AlertType.light, 'lux', 'Luminosity', Colors.purple),
                      _buildChartPage(history, AlertType.gas, 'ppm', 'Gas Level', DesignTokens.warning),
                      _buildChartPage(history, AlertType.distance, 'cm', 'Distance', Colors.teal),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: DesignTokens.textMuted),
          const SizedBox(height: 16),
          Text(
            'No history data available',
            style: GoogleFonts.outfit(color: DesignTokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPage(List<HistoryEntry> history, AlertType type, String unit, String label, Color color) {
    final values = history.map((h) {
      switch (type) {
        case AlertType.fire:     return h.fire;
        case AlertType.gas:      return h.gas;
        case AlertType.water:    return h.water;
        case AlertType.light:    return h.light;
        case AlertType.distance: return h.hcSr04;
        default: return 0.0;
      }
    }).toList();

    if (values.isEmpty) return _buildEmptyState();

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    
    // Reverse values for the chart because history is newest to oldest, but chart usually goes oldest -> newest
    final chartValues = values.reversed.toList();
    final spots = chartValues.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statTile('Current', '${values.last.toStringAsFixed(1)}$unit', color),
              const SizedBox(width: 8),
              _statTile('Min', '${minVal.toStringAsFixed(1)}$unit', DesignTokens.textSecondary),
              const SizedBox(width: 8),
              _statTile('Max', '${maxVal.toStringAsFixed(1)}$unit', DesignTokens.textSecondary),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 300,
            padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
            decoration: BoxDecoration(
              color: DesignTokens.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DesignTokens.border),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: DesignTokens.border.withAlpha((255 * 0.5).toInt()),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= chartValues.length || idx % 5 != 0) return const SizedBox();
                        // chartValues is reversed (oldest to newest), so we need the corresponding timestamp
                        // from the filtered history (which was newest to oldest)
                        final t = history[history.length - 1 - idx].timestamp;
                        return Text('${t.hour}:${t.minute.toString().padLeft(2, "0")}',
                          style: GoogleFonts.outfit(fontSize: 10, color: DesignTokens.textMuted));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                        style: GoogleFonts.outfit(fontSize: 10, color: DesignTokens.textMuted)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
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
                      color: color.withAlpha((255 * 0.1).toInt()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 11, color: DesignTokens.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
