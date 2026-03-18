import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../services/data_service.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final VoidCallback onSimulateDisconnect;
  
  const ProfileScreen({
    super.key, 
    required this.onToggleTheme, 
    required this.themeMode,
    required this.onSimulateDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final data = DataService();
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, // Global background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 90, height: 90,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DesignTokens.cyan.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: DesignTokens.cyan.withValues(alpha: 0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(color: DesignTokens.cyan.withValues(alpha: 0.12), blurRadius: 20),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.admin_panel_settings_rounded, 
                              color: DesignTokens.cyan, 
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('COMMANDER ALPHA',
                          style: TextStyle(
                            color: DesignTokens.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                        Text('SYSTEM PRIVILEGE: ROOT_LEVEL',
                          style: TextStyle(
                            color: DesignTokens.cyan.withValues(alpha: 0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Infrastructure Info
                  _sectionLabel('TERMINAL METRICS'),
                  const SizedBox(height: 14),
                  _infoCard(
                    items: [
                      _infoRow(Icons.dns_rounded, 'Active Terminal Nodes', '${data.nodes.length} ONLINE'),
                      _infoRow(Icons.lan_rounded, 'Grid Latency', '14ms (STABLE)'),
                      _infoRow(Icons.security_rounded, 'Encryption Engine', 'AES-256 (ACTIVE)'),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Settings
                  _sectionLabel('USER INTERFACE CONFIG'),
                  const SizedBox(height: 14),
                  _infoCard(
                    children: [
                      _toggleRow(
                        Icons.dark_mode_rounded, 
                        'High Contrast Mode', 
                        isDark ? 'ENABLED' : 'DISABLED',
                        isDark,
                        (_) => onToggleTheme(),
                      ),
                      _divider(),
                      _linkRow(
                        Icons.settings_input_component_rounded, 
                        'Emergency Protocol Manual', 
                        'DOCS',
                        () => _showProtocolDialog(context),
                      ),
                      _divider(),
                      _toggleRow(
                        Icons.wifi_off_rounded, 
                        'Diagnostic Comms Failure', 
                        'SIMULATION MODE',
                        false,
                        (_) => onSimulateDisconnect(),
                      ),
                      _divider(),
                      _linkRow(
                        Icons.contact_support_rounded, 
                        'Terminal Operations Guide', 
                        'HELP',
                        () => _showManualDialog(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Footer
                  Center(
                    child: Opacity(
                      opacity: 0.4,
                      child: Text('CONNECTED // APAC-NORTH-REGION-7',
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 8,
                          letterSpacing: 2,
                          fontFamily: 'RobotoMono',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
                  title: Text('CONTROL CENTER',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 16 + pct * 4,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontFamily: 'RobotoMono',
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

  Widget _infoCard({List<Widget>? items, List<Widget>? children}) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.border.withValues(alpha: 0.35)),
        boxShadow: [
          const BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: items ?? children ?? [],
        ),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: DesignTokens.border.withValues(alpha: 0.15));

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: DesignTokens.cyan, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: DesignTokens.cyan,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontFamily: 'RobotoMono',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(IconData icon, String label, String value, bool active, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: DesignTokens.textSecondary, size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: DesignTokens.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              Text(value, style: TextStyle(color: DesignTokens.textMuted, fontSize: 9, fontFamily: 'RobotoMono', fontWeight: FontWeight.w800)),
            ],
          ),
          const Spacer(),
          Switch(
            value: active, 
            onChanged: onChanged,
            activeThumbColor: DesignTokens.cyan, activeTrackColor: DesignTokens.cyan.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _linkRow(IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: DesignTokens.textSecondary, size: 20),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(color: DesignTokens.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(value, style: const TextStyle(color: DesignTokens.cyan, fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'RobotoMono')),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, color: DesignTokens.textMuted, size: 12),
          ],
        ),
      ),
    );
  }

  void _showProtocolDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CyberDialog(
        title: 'EMERGENCY PROTOCOLS',
        content: '1. All critical alerts trigger automated visual cues.\n'
                 '2. Fire alerts auto-notify fire department via Grid-Sync.\n'
                 '3. Gas leaks trigger immediate zone isolation.\n'
                 '4. Light failures logged for maintenance dispatch.',
      ),
    );
  }

  void _showManualDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CyberDialog(
        title: 'OPERATIONAL MANUAL',
        content: 'COMMANDER OS v2.4.0\n\n'
                 '• Dashboard: Real-time sensor monitoring.\n'
                 '• Alerts: Current system incidents.\n'
                 '• History: Trend analysis for all nodes.\n'
                 '• Profile: System configuration & diagnostics.',
      ),
    );
  }
}

class _CyberDialog extends StatelessWidget {
  final String title;
  final String content;
  const _CyberDialog({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DesignTokens.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DesignTokens.cyan.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(color: DesignTokens.cyan.withValues(alpha: 0.15), blurRadius: 30),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, 
                  style: const TextStyle(
                    color: DesignTokens.cyan, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w900, 
                    fontFamily: 'RobotoMono',
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: DesignTokens.border.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(content, 
                  style: TextStyle(
                    color: DesignTokens.textPrimary.withValues(alpha: 0.9), 
                    fontSize: 13, 
                    height: 1.6,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ACKNOWLEDGE', 
                      style: TextStyle(
                        color: DesignTokens.cyan, 
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontFamily: 'RobotoMono',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
