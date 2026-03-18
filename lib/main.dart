import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'theme/design_tokens.dart';
import 'services/data_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';

import 'widgets/city_background.dart';
import 'widgets/connection_error_screen.dart';

void main() {
  runApp(const SmartCityApp());
}

class SmartCityApp extends StatefulWidget {
  const SmartCityApp({super.key});

  @override
  State<SmartCityApp> createState() => _SmartCityAppState();
}

class _SmartCityAppState extends State<SmartCityApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      DesignTokens.isDark = _themeMode == ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart City Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: MainShell(
        onToggleTheme: _toggleTheme,
        themeMode: _themeMode,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  const MainShell({super.key, required this.onToggleTheme, required this.themeMode});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;
  StreamSubscription<String>? _notificationSub;

  @override
  void initState() {
    super.initState();
    
    // Listen for real-time notifications from DataService
    _notificationSub = DataService().notifications.listen((msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: DesignTokens.alert, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(msg, 
                    style: TextStyle(
                      fontFamily: 'RobotoMono', 
                      fontSize: 12, 
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    setState(() => _currentIndex = 1); // Go to Alerts
                  },
                  child: const Text('VIEW', style: TextStyle(color: DesignTokens.cyan, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            backgroundColor: DesignTokens.surface.withValues(alpha: 0.95),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 90),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: DesignTokens.alert.withValues(alpha: 0.5), width: 1),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    _simulateStartup();
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  Future<void> _simulateStartup() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return ConnectionErrorScreen(onRetry: () => setState(() => _hasError = false));
    if (_isLoading) return _buildLoadingSplash();

    // Rebuild screen list on every build to stay reactive to themeMode changes
    final List<Widget> screens = [
      DashboardScreen(),
      const AlertsScreen(),
      const HistoryScreen(),
      ProfileScreen(
        onToggleTheme: widget.onToggleTheme, 
        themeMode: widget.themeMode,
        onSimulateDisconnect: () => setState(() => _hasError = true),
      ),
    ];

    return Scaffold(
      backgroundColor: DesignTokens.bg,
      body: Stack(
        children: [
          // Global animated city background
          Positioned.fill(
            child: CityBackground(nodes: DataService().nodes), // Assuming DataService().nodes is available
          ),
          IndexedStack(
            index: _currentIndex, // Changed from _selectedIndex to _currentIndex to match existing state
            children: screens,
          ),
          Positioned(
            left: 20, right: 20, bottom: 20,
            child: _buildHUDNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSplash() {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security_rounded, color: DesignTokens.cyan, size: 64),
            const SizedBox(height: 24),
            Text('INITIALIZING SYSTEM',
              style: GoogleFonts.robotoMono(
                color: DesignTokens.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: DesignTokens.border,
                valueColor: const AlwaysStoppedAnimation(DesignTokens.cyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHUDNav() {
    bool isDark = widget.themeMode == ThemeMode.dark;
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: DesignTokens.surface.withValues(alpha: 0.85),
        borderRadius: DesignTokens.r24,
        border: Border.all(color: DesignTokens.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: DesignTokens.r24,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(0, Icons.grid_view_rounded, 'DASHBOARD'),
              _navItem(1, Icons.sensors_rounded, 'ALERTS'),
              _navItem(2, Icons.analytics_rounded, 'HISTORY'),
              _navItem(3, Icons.person_rounded, 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, 
            color: isSelected ? DesignTokens.cyan : DesignTokens.textMuted,
            size: isSelected ? 28 : 24,
          ),
          const SizedBox(height: 4),
          Text(label, 
            style: GoogleFonts.robotoMono(
              color: isSelected ? DesignTokens.cyan : DesignTokens.textMuted,
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
