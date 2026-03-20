import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_city_monitor/ui/theme/app_theme.dart';
import 'package:smart_city_monitor/ui/theme/design_tokens.dart';
import 'package:smart_city_monitor/core/services/data_service.dart';
import 'package:smart_city_monitor/ui/screens/dashboard_screen.dart';
import 'package:smart_city_monitor/ui/screens/alerts_screen.dart';
import 'package:smart_city_monitor/ui/screens/history_screen.dart';
import 'package:smart_city_monitor/ui/screens/profile_screen.dart';
import 'package:smart_city_monitor/ui/screens/connection_error_screen.dart';
import 'package:smart_city_monitor/ui/screens/auth_screen.dart';

void main() {
  runApp(const SmartCityApp());
}

class SmartCityApp extends StatefulWidget {
  const SmartCityApp({super.key});

  @override
  State<SmartCityApp> createState() => _SmartCityAppState();
}

class _SmartCityAppState extends State<SmartCityApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoggedIn = false;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _login() => setState(() => _isLoggedIn = true);
  void _logout() => setState(() => _isLoggedIn = false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey(_isLoggedIn),
      title: 'Smart City Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: _isLoggedIn 
        ? MainShell(
            onToggleTheme: _toggleTheme,
            themeMode: _themeMode,
            onLogout: _logout,
          )
        : AuthScreen(onLoginSuccess: _login),
    );
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final VoidCallback onLogout;
  const MainShell({super.key, required this.onToggleTheme, required this.themeMode, required this.onLogout});

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
    
    _notificationSub = DataService().notifications.listen((msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, 
              style: GoogleFonts.outfit(
                fontSize: 14, 
                fontWeight: FontWeight.w500,
                color: DesignTokens.textPrimary(context),
              ),
            ),
            backgroundColor: DesignTokens.surface(context),
            behavior: SnackBarBehavior.floating,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: DesignTokens.border(context)),
            ),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: DesignTokens.primary(context),
              onPressed: () {
                if (mounted) {
                  setState(() => _currentIndex = 1);
                }
              },
            ),
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
    await Future.delayed(const Duration(seconds: 1)); // Reduced delay
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return ConnectionErrorScreen(onRetry: () => setState(() => _hasError = false));
    if (_isLoading) return _buildLoadingSplash();

    final List<Widget> screens = [
      const DashboardScreen(),
      const AlertsScreen(),
      const HistoryScreen(),
      ProfileScreen(
        onToggleTheme: widget.onToggleTheme, 
        themeMode: widget.themeMode,
        onLogout: widget.onLogout,
        onSimulateDisconnect: () => setState(() => _hasError = true),
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: DesignTokens.normal,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.sensors_rounded), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.analytics_rounded), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildLoadingSplash() {
    return Scaffold(
      backgroundColor: DesignTokens.bg(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security_rounded, color: DesignTokens.primary(context), size: 48),
            const SizedBox(height: 24),
            Text('SMART CITY MONITOR',
              style: GoogleFonts.outfit(
                color: DesignTokens.textPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                backgroundColor: DesignTokens.border(context),
                valueColor: AlwaysStoppedAnimation(DesignTokens.primary(context)),
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
