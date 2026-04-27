import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../widgets/neo_button.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    return Scaffold(
      backgroundColor: colors.background, // Paper background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Brand header ──────────────────────────────────────────────
              Column(
                children: [
                  // Logo square (Brutalist style)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      border: Border.all(color: colors.foreground, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: colors.foreground,
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      FIcons.handCoins,
                      size: 32,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'eda',
                    style: typo.xl4.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: colors.foreground,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track who owes whom, simply.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // ── Toggle Sign in / Sign up ──────────────────────────────────
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: colors.card,
                  border: Border.all(color: colors.foreground, width: 1.5),
                ),
                child: Row(
                  children: [
                    _tab('Sign in', !_isSignUp, () => setState(() => _isSignUp = false), colors, typo),
                    Container(width: 1.5, color: colors.foreground),
                    _tab('Sign up', _isSignUp, () => setState(() => _isSignUp = true), colors, typo),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Error alert ───────────────────────────────────────────────
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.destructive,
                    border: Border.all(color: colors.foreground, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: colors.foreground,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(FIcons.circleAlert, color: colors.foreground),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: typo.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Full name (sign-up only) ───────────────────────────────────
              if (_isSignUp) ...[
                _buildLabel('FULL NAME', colors),
                _buildTextField(
                  controller: _fullNameController,
                  hint: 'Your full name',
                  icon: FIcons.user,
                  colors: colors,
                  typo: typo,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 20),
              ],

              // ── Email ─────────────────────────────────────────────────────
              _buildLabel('EMAIL', colors),
              _buildTextField(
                controller: _emailController,
                hint: 'you@example.com',
                icon: FIcons.mail,
                colors: colors,
                typo: typo,
                action: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // ── Password ──────────────────────────────────────────────────
              _buildLabel('PASSWORD', colors),
              _buildTextField(
                controller: _passwordController,
                hint: '••••••••',
                icon: FIcons.lock,
                colors: colors,
                typo: typo,
                obscure: true,
                action: _isSignUp ? TextInputAction.next : TextInputAction.done,
                onSubmit: _isSignUp ? null : (_) => _handleEmailAction(),
              ),

              // ── Confirm password (sign-up) ────────────────────────────────
              if (_isSignUp) ...[
                const SizedBox(height: 20),
                _buildLabel('CONFIRM PASSWORD', colors),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hint: '••••••••',
                  icon: FIcons.lock,
                  colors: colors,
                  typo: typo,
                  obscure: true,
                  action: TextInputAction.done,
                  onSubmit: (_) => _handleEmailAction(),
                ),
              ],

              const SizedBox(height: 36),

              // ── Submit ────────────────────────────────────────────────────
              NeoButton(
                onTap: _isEmailLoading ? null : _handleEmailAction,
                backgroundColor: colors.primary,
                borderColor: colors.foreground,
                shadowOffset: 4.0,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: _isEmailLoading
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colors.foreground, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isSignUp ? FIcons.userPlus : FIcons.logIn, size: 20, color: colors.foreground),
                          const SizedBox(width: 10),
                          Text(
                            _isSignUp ? 'Create account' : 'Sign in',
                            style: typo.lg.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              // ── Google ────────────────────────────────────────────────────
              NeoButton(
                onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
                backgroundColor: colors.card,
                borderColor: colors.foreground,
                shadowOffset: 4.0,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: _isGoogleLoading
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colors.foreground, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FIcons.globe, size: 20, color: colors.foreground),
                          const SizedBox(width: 10),
                          Text(
                            'Continue with Google',
                            style: typo.lg.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              // ── Apple ─────────────────────────────────────────────────────
              NeoButton(
                onTap: () => _showComingSoon('Apple Sign-In'),
                backgroundColor: colors.card,
                borderColor: colors.foreground,
                shadowOffset: 4.0,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FIcons.apple, size: 20, color: colors.foreground),
                    const SizedBox(width: 10),
                    Text(
                      'Continue with Apple',
                      style: typo.lg.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── Terms ─────────────────────────────────────────────────────
              Text(
                'By continuing you agree to our Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, FColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: colors.mutedForeground,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FColors colors,
    required FTypography typo,
    bool obscure = false,
    TextInputAction action = TextInputAction.done,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onSubmit,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      keyboardType: keyboardType,
      onSubmitted: onSubmit,
      style: typo.sm.copyWith(fontWeight: FontWeight.w500, color: colors.foreground),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: typo.sm.copyWith(color: colors.mutedForeground.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, size: 18, color: colors.mutedForeground),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: colors.foreground, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: colors.foreground, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: colors.foreground, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap, FColors colors, FTypography typo) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: selected ? colors.primary : Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colors.foreground,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleEmailAction() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) { setState(() => _errorMessage = 'Email is required.'); return; }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) { setState(() => _errorMessage = 'Enter a valid email.'); return; }
    if (password.isEmpty) { setState(() => _errorMessage = 'Password is required.'); return; }
    if (password.length < 8) { setState(() => _errorMessage = 'Use at least 8 characters.'); return; }

    if (_isSignUp) {
      final confirm = _confirmPasswordController.text;
      if (confirm.isEmpty) { setState(() => _errorMessage = 'Please confirm your password.'); return; }
      if (confirm != password) { setState(() => _errorMessage = 'Passwords do not match.'); return; }
    }

    setState(() { _isEmailLoading = true; _errorMessage = null; });

    final controller = ref.read(authControllerProvider);
    try {
      if (_isSignUp) {
        await controller.signUpWithEmail(email: email, password: password, fullName: _fullNameController.text.trim());
        setState(() { _isSignUp = false; _confirmPasswordController.clear(); _errorMessage = null; });
      } else {
        await controller.signInWithEmail(email: email, password: password);
      }
    } on AuthControllerException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { _isGoogleLoading = true; _errorMessage = null; });
    final controller = ref.read(authControllerProvider);
    try {
      await controller.signInWithGoogle();
    } on AuthControllerException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showComingSoon(String label) => setState(() => _errorMessage = '$label coming soon.');
}
