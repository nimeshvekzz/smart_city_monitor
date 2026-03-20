import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_city_monitor/core/services/dispatch_service.dart';

// ─────────────────────── ──────────────────────────────────────
//  DESIGN SYSTEM (Shared)
// ─────────────────────────────────────────────────────────────
class _DS {
  static const bg      = Color(0xFF0A0D14);
  static const surface = Color(0xFF121720);
  static const card    = Color(0xFF171E2B);

  static const amber   = Color(0xFFFFAB40);
  static const red     = Color(0xFFFF5252);

  static const textPrimary   = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8892A4);
  static const textMuted     = Color(0xFF4A5568);
  static const border        = Color(0xFF1E2A3C);

  static TextStyle display(double size, {FontWeight w = FontWeight.w700, Color? color}) =>
      GoogleFonts.rajdhani(fontSize: size, fontWeight: w, color: color ?? textPrimary, letterSpacing: -0.3);

  static TextStyle mono(double size, {Color? color}) =>
      GoogleFonts.spaceMono(fontSize: size, color: color ?? textSecondary, letterSpacing: 0.5);

  static TextStyle body(double size, {FontWeight w = FontWeight.w500, Color? color}) =>
      GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color ?? textSecondary);
}

// ─────────────────────────────────────────────────────────────
//  AGENT DETAIL SCREEN
// ─────────────────────────────────────────────────────────────
class AgentDetailScreen extends StatefulWidget {
  const AgentDetailScreen({super.key});

  @override
  State<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends State<AgentDetailScreen> {
  final DispatchService _dispatchService = DispatchService();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _DS.bg,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              _buildAgentProfile(),
              _buildSectionHeader('Dispatch History'),
              _buildDispatchHistory(),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 16),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _DS.textSecondary, size: 20),
            ),
            const SizedBox(width: 8),
            Text('Emergency Contact', style: _DS.display(22)),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentProfile() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _DS.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _DS.border),
            gradient: LinearGradient(
              colors: [_DS.amber.withValues(alpha: 0.08), Colors.transparent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_DS.amber, _DS.red],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: _DS.amber.withValues(alpha: 0.25), blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DispatchService.agentName, style: _DS.display(20)),
                    const SizedBox(height: 4),
                    Text('Government Emergency Response', style: _DS.body(13, color: _DS.amber)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 14, color: _DS.textMuted),
                        const SizedBox(width: 6),
                        Text(DispatchService.agentPhone, style: _DS.mono(11, color: _DS.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.email_rounded, size: 14, color: _DS.textMuted),
                        const SizedBox(width: 6),
                        Text(DispatchService.agentEmail, style: _DS.mono(11, color: _DS.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 0, 16),
        child: Text(
          title.toUpperCase(),
          style: _DS.mono(10, color: _DS.textMuted),
        ),
      ),
    );
  }

  Widget _buildDispatchHistory() {
    return StreamBuilder<DispatchLog>(
      stream: _dispatchService.dispatchLogs,
      builder: (context, snapshot) {
        final history = _dispatchService.history;

        if (history.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history_rounded, color: _DS.textMuted.withValues(alpha: 0.5), size: 48),
                    const SizedBox(height: 16),
                    Text('No emergency dispatches yet.', style: _DS.body(14, color: _DS.textMuted)),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final log = history[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _DS.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _DS.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _DS.amber.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: _DS.amber, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Dispatch Triggered', style: _DS.body(15, w: FontWeight.w600, color: _DS.textPrimary)),
                                Text(_formatTime(log.timestamp), style: _DS.mono(10, color: _DS.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Alert ID: ${log.alertId}', style: _DS.mono(12, color: _DS.textSecondary)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: log.channels.map((c) => _buildChannelChip(c)).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: history.length,
          ),
        );
      },
    );
  }

  Widget _buildChannelChip(String channel) {
    IconData icon;
    if (channel == 'SMS') {
      icon = Icons.sms_rounded;
    } else if (channel == 'VOICE') {
      icon = Icons.phone_rounded;
    } else {
      icon = Icons.email_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _DS.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _DS.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: _DS.textSecondary),
          const SizedBox(width: 4),
          Text(channel, style: _DS.mono(9, color: _DS.textSecondary)),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
