import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN SYSTEM
// ─────────────────────────────────────────────────────────────
class _DS {
  static const bg      = Color(0xFF0A0D14);
  static const surface = Color(0xFF121720);
  static const card    = Color(0xFF171E2B);

  static const cyan    = Color(0xFF00E5FF);
  static const blue    = Color(0xFF2979FF);
  static const red     = Color(0xFFFF5252);

  static const textPrimary   = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8892A4);
  static const textMuted     = Color(0xFF4A5568);
  static const border        = Color(0xFF1E2A3C);

  static TextStyle display(double size,
      {FontWeight w = FontWeight.w700, Color? color}) =>
      GoogleFonts.rajdhani(fontSize: size, fontWeight: w,
          color: color ?? textPrimary, letterSpacing: -0.3);

  static TextStyle mono(double size, {Color? color}) =>
      GoogleFonts.spaceMono(fontSize: size, color: color ?? textSecondary,
          letterSpacing: 0.5);

  static TextStyle body(double size,
      {FontWeight w = FontWeight.w500, Color? color}) =>
      GoogleFonts.dmSans(fontSize: size, fontWeight: w,
          color: color ?? textSecondary);

  static const fast   = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 280);
  static const slow   = Duration(milliseconds: 500);
}

// ─────────────────────────────────────────────────────────────
//  AUTH SCREEN
// ─────────────────────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  bool _isLogin = true;

  final _formKey            = GlobalKey<FormState>();
  final _emailCtrl          = TextEditingController();
  final _passwordCtrl       = TextEditingController();
  final _confirmCtrl        = TextEditingController();
  bool _isLoading           = false;
  bool _passwordVisible     = false;
  bool _confirmVisible      = false;

  late final AnimationController _bgAnim;
  late final AnimationController _formAnim;
  late final Animation<double>   _fadeIn;
  late final Animation<Offset>   _slideIn;

  @override
  void initState() {
    super.initState();

    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _formAnim = AnimationController(vsync: this, duration: _DS.slow)
      ..forward();

    _fadeIn  = CurvedAnimation(parent: _formAnim, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formAnim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _formAnim.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    HapticFeedback.selectionClick();
    setState(() => _isLogin = !_isLogin);
    _formAnim.reset();
    _formAnim.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isLogin && _passwordCtrl.text != _confirmCtrl.text) {
      _showError('ACCESS CODES DO NOT MATCH');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1600));

    if (mounted) {
      setState(() => _isLoading = false);
      widget.onLoginSuccess();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(msg, style: _DS.mono(11, color: Colors.white)),
          ],
        ),
        backgroundColor: _DS.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _DS.bg,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Animated background grid
            _AnimatedGrid(controller: _bgAnim),

            // Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideIn,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLogoSection(),
                          const SizedBox(height: 40),
                          _buildGlassCard(),
                          const SizedBox(height: 32),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logo / Header ────────────────────────────────────────
  Widget _buildLogoSection() {
    return Column(
      children: [
        // Icon
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [_DS.cyan, _DS.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _DS.cyan.withValues(alpha: 0.3),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.location_city_rounded,
              color: Colors.white, size: 34),
        ),
        const SizedBox(height: 20),
        // App name
        Text(
          'CITY\u200BMONITOR',
          style: _DS.display(28, w: FontWeight.w800).copyWith(
            letterSpacing: 4,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [_DS.cyan, _DS.blue],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isLogin ? 'OPERATOR AUTHENTICATION' : 'NEW OPERATOR REGISTRATION',
          style: _DS.mono(10, color: _DS.textMuted),
        ),
      ],
    );
  }

  // ── Glass Card ───────────────────────────────────────────
  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: _DS.card.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _DS.border.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Section label
                  Row(
                    children: [
                      Container(
                        width: 3, height: 16,
                        decoration: BoxDecoration(
                          color: _DS.cyan,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isLogin ? 'Sign In' : 'Create Account',
                        style: _DS.display(20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Email
                  _AuthField(
                    controller: _emailCtrl,
                    label: 'OPERATOR ID',
                    hint: 'operator@city.net',
                    icon: Icons.alternate_email_rounded,
                    type: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty || !v.contains('@')) {
                        return 'INVALID OPERATOR ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  _AuthField(
                    controller: _passwordCtrl,
                    label: 'ACCESS CODE',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    obscure: !_passwordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: _DS.textMuted,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) return 'CODE TOO SHORT (min 6)';
                      return null;
                    },
                  ),

                  // Confirm password (register only)
                  AnimatedSize(
                    duration: _DS.normal,
                    curve: Curves.easeOutCubic,
                    child: _isLogin
                        ? const SizedBox.shrink()
                        : Column(
                            children: [
                              const SizedBox(height: 16),
                              _AuthField(
                                controller: _confirmCtrl,
                                label: 'CONFIRM ACCESS CODE',
                                hint: '••••••••',
                                icon: Icons.lock_reset_rounded,
                                obscure: !_confirmVisible,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _confirmVisible
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: _DS.textMuted,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(
                                      () => _confirmVisible = !_confirmVisible),
                                ),
                                validator: (v) {
                                  if (v != _passwordCtrl.text) return 'CODES DO NOT MATCH';
                                  return null;
                                },
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 28),

                  // Submit button
                  _SubmitButton(
                    label: _isLogin ? 'INITIALIZE LOGIN' : 'COMPLETE REGISTRATION',
                    isLoading: _isLoading,
                    onTap: _isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Toggle footer ────────────────────────────────────────
  Widget _buildFooter() {
    return GestureDetector(
      onTap: _isLoading ? null : _toggleMode,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isLogin ? "New operator?  " : "Already enrolled?  ",
            style: _DS.body(14),
          ),
          Text(
            _isLogin ? "Register" : "Login",
            style: _DS.body(14, w: FontWeight.w700, color: _DS.cyan),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AUTH FIELD
// ─────────────────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType type;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.type    = TextInputType.text,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(label, style: _DS.mono(9, color: _DS.textMuted)),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          validator: validator,
          cursorColor: _DS.cyan,
          style: _DS.body(15, color: _DS.textPrimary, w: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _DS.body(15, color: _DS.textMuted),
            prefixIcon: Icon(icon, color: _DS.cyan.withValues(alpha: 0.6), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _DS.bg.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: _DS.border.withValues(alpha: 0.7), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: _DS.cyan, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: _DS.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: _DS.red, width: 1.5),
            ),
            errorStyle: _DS.mono(9, color: _DS.red),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SUBMIT BUTTON
// ─────────────────────────────────────────────────────────────
class _SubmitButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: _DS.fast,
        child: AnimatedContainer(
          duration: _DS.normal,
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.isLoading
                ? null
                : const LinearGradient(
                    colors: [_DS.cyan, _DS.blue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: widget.isLoading ? _DS.surface : null,
            border: widget.isLoading
                ? Border.all(color: _DS.border)
                : null,
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: _DS.cyan.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              const AlwaysStoppedAnimation(_DS.cyan),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('AUTHENTICATING…',
                          style: _DS.mono(10, color: _DS.textMuted)),
                    ],
                  )
                : Text(widget.label,
                    style: _DS.mono(12, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ANIMATED BACKGROUND GRID
// ─────────────────────────────────────────────────────────────
class _AnimatedGrid extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, unusedChild) => CustomPaint(
        painter: _GridPainter(progress: controller.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double progress;
  _GridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const gridSpacing = 48.0;
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.03)
      ..strokeWidth = 1;

    // Static grid lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Animated scan line
    final scanY = size.height * progress;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.08),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, scanY - 60, size.width, 120));

    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 60, size.width, 120),
      scanPaint,
    );


    for (double x = 0; x < size.width; x += gridSpacing) {
      for (double y = 0; y < size.height; y += gridSpacing) {
        final dist = (y - scanY).abs();
        if (dist < 80) {
          final opacity = (1 - dist / 80) * 0.2;
          canvas.drawCircle(
            Offset(x, y),
            2,
            Paint()..color = const Color(0xFF00E5FF).withValues(alpha: opacity),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.progress != progress;
}
