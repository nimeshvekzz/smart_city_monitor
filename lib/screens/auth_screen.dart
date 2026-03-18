import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../widgets/cyber_background.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLogin && _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ACCESS CODES DO NOT MATCH'),
          backgroundColor: DesignTokens.alert,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate authentication delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      body: Stack(
        children: [
          CyberBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 48),
                      _buildForm(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                      const SizedBox(height: 24),
                      _buildToggleButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DesignTokens.cyan.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.cyan.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.security_rounded,
            color: DesignTokens.cyan,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'SYSTEM ACCESS' : 'ENROLL NEW OPERATOR',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: DesignTokens.cyan,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            fontFamily: 'RobotoMono',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'PROCEED WITH CREDENTIALS' : 'CREATE SECURE PROFILE',
          style: TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _CustomTextField(
            controller: _emailController,
            label: 'EMAIL ADDRESS',
            hint: 'operator@city.net',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                return 'INVALID OPERATOR ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _CustomTextField(
            controller: _passwordController,
            label: 'ACCESS CODE',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'CODE TOO SHORT';
              }
              return null;
            },
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 20),
            _CustomTextField(
              controller: _confirmPasswordController,
              label: 'CONFIRM ACCESS CODE',
              hint: '••••••••',
              icon: Icons.lock_reset_rounded,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'PLEASE CONFIRM CODE';
                }
                if (value != _passwordController.text) {
                  return 'CODES DO NOT MATCH';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: _isLoading ? DesignTokens.surface : DesignTokens.cyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isLoading ? DesignTokens.border : DesignTokens.cyan.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            if (!_isLoading)
              BoxShadow(
                color: DesignTokens.cyan.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: -2,
              ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(DesignTokens.cyan),
                  ),
                )
              : Text(
                  _isLogin ? 'INITIALIZE LOGIN' : 'COMPLETE REGISTRATION',
                  style: const TextStyle(
                    color: DesignTokens.cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontFamily: 'RobotoMono',
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: _isLoading ? null : _toggleAuthMode,
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: 13,
            fontFamily: 'Roboto',
          ),
          children: [
            TextSpan(text: _isLogin ? "NEW OPERATOR? " : "ALREADY ENROLLED? "),
            TextSpan(
              text: _isLogin ? "REGISTER" : "LOGIN",
              style: const TextStyle(
                color: DesignTokens.cyan,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontFamily: 'RobotoMono',
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          cursorColor: DesignTokens.cyan,
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: 15,
            fontFamily: 'RobotoMono',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: DesignTokens.surface.withValues(alpha: 0.5),
            hintText: hint,
            hintStyle: TextStyle(
              color: DesignTokens.textMuted.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: DesignTokens.textSecondary, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: DesignTokens.border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DesignTokens.cyan, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DesignTokens.alert, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DesignTokens.alert, width: 1.5),
            ),
            errorStyle: const TextStyle(
              color: DesignTokens.alert,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
