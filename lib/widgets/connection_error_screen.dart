import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class ConnectionErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const ConnectionErrorScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      body: Stack(
        children: [
          // Cyber scanlines
          Positioned.fill(child: _Scanlines()),
          
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glitchy-feel icon
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: DesignTokens.alert.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: DesignTokens.alert.withValues(alpha: 0.3), width: 2),
                      boxShadow: [
                        BoxShadow(color: DesignTokens.alert.withValues(alpha: 0.2), blurRadius: 30),
                      ],
                    ),
                    child: const Icon(Icons.wifi_off_rounded, color: DesignTokens.alert, size: 40),
                  ),
                  const SizedBox(height: 32),
                  
                  const Text('CONNECTION LOST',
                    style: TextStyle(
                      color: DesignTokens.alert,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('CRITICAL PACKET LOSS DETECTED.\nTERMINAL DISCONNECTED FROM SMART GRID.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      letterSpacing: 1,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Retry button
                  GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: DesignTokens.r12,
                        border: Border.all(color: DesignTokens.cyan, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: DesignTokens.cyan.withValues(alpha: 0.1), blurRadius: 10),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, color: DesignTokens.cyan, size: 18),
                          SizedBox(width: 10),
                          Text('RETRY CONNECTION',
                            style: TextStyle(
                              color: DesignTokens.cyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Text('SYSTEM ATTEMPTING AUTOMATIC RECONNECT...',
                    style: TextStyle(color: DesignTokens.textMuted, fontSize: 8, fontFamily: 'RobotoMono'),
                  ),
                ],
              ),
            ),
          ),
          
          // Technical overlay info
          const Positioned(
            left: 20, bottom: 20,
            child: Opacity(
              opacity: 0.5,
              child: Text('ERR_NODE_DISCONNECTED // TIMEOUT_408',
                style: TextStyle(color: DesignTokens.alert, fontSize: 8, fontFamily: 'RobotoMono'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Scanlines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.03,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Container(
          height: 2,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white, width: 1)),
          ),
        ),
      ),
    );
  }
}
