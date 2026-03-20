import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alert_model.dart';
import '../services/data_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/alert_card.dart';

enum _Filter { all, active, resolved }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final DataService _data = DataService();
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _data.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _data.removeListener(_onDataChange);
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  List<AlertModel> get _filtered {
    switch (_filter) {
      case _Filter.all:      return _data.alerts;
      case _Filter.active:   return _data.alerts.where((a) => !a.isResolved).toList();
      case _Filter.resolved: return _data.alerts.where((a) => a.isResolved).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('Incident Logs'),
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _FilterBtn(label: 'All', value: _Filter.all, group: _filter, 
                  onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _FilterBtn(label: 'Active', value: _Filter.active, group: _filter,
                  onTap: (v) => setState(() => _filter = v)),
                const SizedBox(width: 8),
                _FilterBtn(label: 'Resolved', value: _Filter.resolved, group: _filter,
                  onTap: (v) => setState(() => _filter = v)),
              ],
            ),
          ),

          // List
          Expanded(
            child: _filtered.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) => AlertCard(
                      alert: _filtered[index],
                      onResolve: () => _data.resolveAlert(_filtered[index].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 64, color: DesignTokens.textMuted.withAlpha((255 * 0.5).toInt())),
          const SizedBox(height: 16),
          Text(
            'All Systems Normal',
            style: GoogleFonts.outfit(
              color: DesignTokens.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No active anomalies detected',
            style: GoogleFonts.outfit(color: DesignTokens.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final _Filter value;
  final _Filter group;
  final Function(_Filter) onTap;

  const _FilterBtn({required this.label, required this.value, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = group == value;
    return Expanded(
      child: ActionChip(
        label: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: active ? Colors.white : DesignTokens.textSecondary,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        onPressed: () => onTap(value),
        backgroundColor: active ? DesignTokens.primary : DesignTokens.surface,
        side: BorderSide(
          color: active ? DesignTokens.primary : DesignTokens.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
