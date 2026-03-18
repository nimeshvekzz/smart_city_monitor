import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/data_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/alert_card.dart';
import '../widgets/city_background.dart';

enum _Filter { all, active, resolved }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with TickerProviderStateMixin {
  final DataService _data = DataService();
  _Filter _filter = _Filter.all;

  late final AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _data.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _listCtrl.dispose();
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
    final activeCount = _data.alerts.where((a) => !a.isResolved).length;

    return Scaffold(
      backgroundColor: Colors.transparent, // Global background handled by MainShell
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(activeCount),
          
          // Technical Filter Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  _FilterBtn(label: 'ALL LOGS', value: _Filter.all, group: _filter, 
                    onTap: (v) => setState(() => _filter = v)),
                  const SizedBox(width: 8),
                  _FilterBtn(label: 'ACTIVE', value: _Filter.active, group: _filter,
                    onTap: (v) => setState(() => _filter = v)),
                  const SizedBox(width: 8),
                  _FilterBtn(label: 'RESOLVED', value: _Filter.resolved, group: _filter,
                    onTap: (v) => setState(() => _filter = v)),
                ],
              ),
            ),
          ),

          // List
          if (_filtered.isEmpty)
            SliverFillRemaining(child: _emptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _listCtrl,
                      curve: Interval(i * 0.1 > 1.0 ? 0.0 : i * 0.1, 1.0, curve: Curves.easeOut),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                        .animate(CurvedAnimation(
                          parent: _listCtrl,
                          curve: Interval(i * 0.1 > 1.0 ? 0.0 : i * 0.1, 1.0, curve: Curves.easeOutCubic),
                        )),
                      child: AlertCard(
                        alert: _filtered[i],
                        onResolve: () => _data.resolveAlert(_filtered[i].id),
                      ),
                    ),
                  ),
                  childCount: _filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(int activeCount) {
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
                      Text('INCIDENT LOGS',
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: 16 + pct * 4,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                      if (pct > 0.5)
                        Opacity(
                          opacity: (pct - 0.5) * 2,
                          child: Text('SYSTEM STATUS: ${activeCount > 0 ? "CRITICAL" : "OPTIMAL"}',
                            style: TextStyle(
                              color: activeCount > 0 ? DesignTokens.alert : DesignTokens.safe,
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
                
                // Alert Counter Badge (Top Right)
                if (activeCount > 0)
                  Positioned(
                    right: 20, bottom: 16,
                    child: FadeTransition(
                      opacity: AlwaysStoppedAnimation(pct),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: DesignTokens.alert.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: DesignTokens.alert.withValues(alpha: 0.4), width: 1),
                          boxShadow: [
                            BoxShadow(color: DesignTokens.alert.withValues(alpha: 0.1), blurRadius: 10),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: DesignTokens.alert, size: 12),
                            const SizedBox(width: 6),
                            Text('$activeCount ACTIVE',
                              style: const TextStyle(
                                color: DesignTokens.alert, 
                                fontSize: 9, 
                                fontWeight: FontWeight.w900,
                                fontFamily: 'RobotoMono',
                              ),
                            ),
                          ],
                        ),
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: DesignTokens.safe.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: DesignTokens.safe.withValues(alpha: 0.2)),
            ),
            child: Icon(Icons.shield_rounded, size: 40, color: DesignTokens.safe.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          const Text('ALL SYSTEMS NOMINAL',
            style: TextStyle(
              color: DesignTokens.safe,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(height: 8),
          Text('NO ACTIVE ANOMALIES DETECTED',
            style: TextStyle(color: DesignTokens.textMuted, fontSize: 10, letterSpacing: 1),
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
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? DesignTokens.cyan.withValues(alpha: 0.12) : DesignTokens.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? DesignTokens.cyan.withValues(alpha: 0.5) : DesignTokens.border.withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              if (active)
                BoxShadow(color: DesignTokens.cyan.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: -2),
            ],
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? DesignTokens.cyan : DesignTokens.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontFamily: 'RobotoMono',
            ),
          ),
        ),
      ),
    );
  }
}
