import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';

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

    return FScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // ── Brand header ──────────────────────────────────────────────
              Column(
                children: [
                  // Logo circle
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border, width: 1.5),
                    ),
                    child: Icon(
                      FIcons.handCoins,
                      size: 30,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'eda',
                    style: GoogleFonts.outfit(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: colors.foreground,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track who owes whom, simply.',
                    style: typo.sm.copyWith(color: colors.mutedForeground),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // ── Toggle Sign in / Sign up ──────────────────────────────────
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    _tab('Sign in', !_isSignUp, () => setState(() => _isSignUp = false), colors, typo),
                    _tab('Sign up', _isSignUp, () => setState(() => _isSignUp = true), colors, typo),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Error alert ───────────────────────────────────────────────
              if (_errorMessage != null) ...[
                FAlert(
                  variant: FAlertVariant.destructive,
                  icon: const Icon(FIcons.circleAlert),
                  title: const Text('Error'),
                  subtitle: Text(_errorMessage!),
                ),
                const SizedBox(height: 16),
              ],

              // ── Full name (sign-up only) ───────────────────────────────────
              if (_isSignUp) ...[
                FTextField(
                  control: FTextFieldControl.managed(controller: _fullNameController),
                  label: const Text('Full name'),
                  hint: 'Your full name',
                  textInputAction: TextInputAction.next,
                  prefixBuilder: (context, style, variants) =>
                      FTextField.prefixIconBuilder(context, style, variants, const Icon(FIcons.user)),
                ),
                const SizedBox(height: 14),
              ],

              // ── Email ─────────────────────────────────────────────────────
              FTextField.email(
                control: FTextFieldControl.managed(controller: _emailController),
                hint: 'you@example.com',
                prefixBuilder: (context, style, variants) =>
                    FTextField.prefixIconBuilder(context, style, variants, const Icon(FIcons.mail)),
              ),
              const SizedBox(height: 14),

              // ── Password ──────────────────────────────────────────────────
              FTextField.password(
                control: FTextFieldControl.managed(controller: _passwordController),
                hint: '••••••••',
                textInputAction: _isSignUp ? TextInputAction.next : TextInputAction.done,
                prefixBuilder: (context, style, obscure, variants) =>
                    FTextField.prefixIconBuilder(context, style, variants, const Icon(FIcons.lock)),
                onSubmit: _isSignUp ? null : (_) => _handleEmailAction(),
              ),

              // ── Confirm password (sign-up) ────────────────────────────────
              if (_isSignUp) ...[
                const SizedBox(height: 14),
                FTextField.password(
                  control: FTextFieldControl.managed(controller: _confirmPasswordController),
                  label: const Text('Confirm password'),
                  hint: '••••••••',
                  textInputAction: TextInputAction.done,
                  prefixBuilder: (context, style, obscure, variants) =>
                      FTextField.prefixIconBuilder(context, style, variants, const Icon(FIcons.lock)),
                  onSubmit: (_) => _handleEmailAction(),
                ),
              ],

              const SizedBox(height: 28),

              // ── Submit ────────────────────────────────────────────────────
              FButton(
                variant: FButtonVariant.primary,
                onPress: _isEmailLoading ? null : _handleEmailAction,
                prefix: _isEmailLoading
                    ? const SizedBox(width: 16, height: 16, child: FCircularProgress())
                    : Icon(_isSignUp ? FIcons.userPlus : FIcons.logIn),
                child: Text(_isSignUp ? 'Create account' : 'Sign in'),
              ),

              const SizedBox(height: 10),

              // ── Google ────────────────────────────────────────────────────
              FButton(
                variant: FButtonVariant.outline,
                onPress: _isGoogleLoading ? null : _handleGoogleSignIn,
                prefix: _isGoogleLoading
                    ? const SizedBox(width: 16, height: 16, child: FCircularProgress())
                    : const Icon(FIcons.globe),
                child: Text(_isGoogleLoading ? 'Launching Google…' : 'Continue with Google'),
              ),

              const SizedBox(height: 10),

              // ── Apple ─────────────────────────────────────────────────────
              FButton(
                variant: FButtonVariant.outline,
                onPress: () => _showComingSoon('Apple Sign-In'),
                prefix: const Icon(FIcons.apple),
                child: const Text('Continue with Apple'),
              ),

              const SizedBox(height: 20),

              // ── Terms ─────────────────────────────────────────────────────
              Text(
                'By continuing you agree to our Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: typo.xs.copyWith(color: colors.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap, FColors colors, FTypography typo) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? colors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 1))]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: typo.sm.copyWith(
              color: selected ? colors.foreground : colors.mutedForeground,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
