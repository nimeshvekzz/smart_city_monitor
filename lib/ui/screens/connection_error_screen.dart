import 'package:flutter/material.dart';
import 'package:smart_city_monitor/ui/theme/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';

class ConnectionErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const ConnectionErrorScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg(context),
      body: Stack(
        children: [
          // Cyber scanlines
          const Positioned.fill(child: _Scanlines()),
          
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glitchy-feel icon
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: DesignTokens.alert(context).withAlpha((255 * 0.1).toInt()),
                      shape: BoxShape.circle,
                      border: Border.all(color: DesignTokens.alert(context).withAlpha((255 * 0.3).toInt()), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.alert(context).withAlpha((255 * 0.25).toInt()), 
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(Icons.wifi_off_rounded, color: DesignTokens.alert(context), size: 48),
                  ),
                  const SizedBox(height: 40),
                  
                  Text('CONNECTION LOST',
                    style: GoogleFonts.outfit(
                      color: DesignTokens.alert(context),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('CRITICAL PACKET LOSS DETECTED.\nTERMINAL DISCONNECTED FROM SMART GRID.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: DesignTokens.textSecondary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 56),
                  
                  // Retry button
                  GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: DesignTokens.primaryGradient(context),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.primary(context).withAlpha((255 * 0.3).toInt()), 
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Text('RESTORE PROTOCOL',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Text('SYSTEM ATTEMPTING AUTOMATIC RECONNECT...',
                    style: GoogleFonts.outfit(
                      color: DesignTokens.textMuted(context), 
                      fontSize: 11, 
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Technical overlay info
          Positioned(
            left: 24, bottom: 24,
            child: Opacity(
              opacity: 0.4,
              child: Text('ERR_NODE_DISCONNECTED // TIMEOUT_408',
                style: GoogleFonts.outfit(
                  color: DesignTokens.alert(context), 
                  fontSize: 10, 
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Scanlines extends StatelessWidget {
  const _Scanlines();
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
