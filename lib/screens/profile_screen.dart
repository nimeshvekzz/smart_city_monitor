import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: DesignTokens.primary.withAlpha((255 * 0.1).toInt()),
                  child: Icon(Icons.person_outline_rounded, size: 40, color: DesignTokens.primary),
                ),
                const SizedBox(height: 16),
                Text('Operator', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
                Text('System Administrator', style: GoogleFonts.outfit(fontSize: 14, color: DesignTokens.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _sectionHeader('System Status'),
          Card(
            child: Column(
              children: [
                _infoTile(Icons.dns_outlined, 'Active Nodes', '${data.nodes.length}'),
                _divider(),
                _infoTile(Icons.speed_rounded, 'Network Latency', '14ms'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Preferences'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: Text('Dark Mode', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500)),
                  value: isDark,
                  onChanged: (_) => onToggleTheme(),
                ),
                _divider(),
                ListTile(
                  leading: const Icon(Icons.wifi_off_rounded),
                  title: Text('Simulate Disconnect', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500)),
                  onTap: onSimulateDisconnect,
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                _divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: Text('Help & Support', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500)),
                  onTap: () {},
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: DesignTokens.textSecondary)),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: DesignTokens.primary)),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56);
}
