import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

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
    return FScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Hero section
              FCard(
                title: Text(
                  _isSignUp ? 'Create your account' : 'Welcome back',
                ),
                subtitle: Text(
                  _isSignUp
                      ? 'Sign up to start tracking IOUs with approvals.'
                      : 'Sign in to keep your groups and balances in sync.',
                ),
              ),
              const SizedBox(height: 24),

              // Error alert
              if (_errorMessage != null) ...[
                FAlert(
                  variant: FAlertVariant.destructive,
                  icon: const Icon(FIcons.circleAlert),
                  title: const Text('Error'),
                  subtitle: Text(_errorMessage!),
                ),
                const SizedBox(height: 16),
              ],

              // Mode toggle buttons
              Row(
                children: [
                  Expanded(
                    child: FButton(
                      variant: _isSignUp
                          ? FButtonVariant.ghost
                          : FButtonVariant.primary,
                      onPress: () => setState(() => _isSignUp = false),
                      child: const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FButton(
                      variant: _isSignUp
                          ? FButtonVariant.primary
                          : FButtonVariant.ghost,
                      onPress: () => setState(() => _isSignUp = true),
                      child: const Text('Sign up'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Full name field (sign-up only)
              if (_isSignUp) ...[
                FTextField(
                  control: FTextFieldControl.managed(
                    controller: _fullNameController,
                  ),
                  label: const Text('Full name'),
                  hint: 'Enter your full name',
                  textInputAction: TextInputAction.next,
                  prefixBuilder: (context, style, variants) =>
                      FTextField.prefixIconBuilder(
                    context,
                    style,
                    variants,
                    const Icon(FIcons.user),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Email field
              FTextField.email(
                control: FTextFieldControl.managed(
                  controller: _emailController,
                ),
                hint: 'Enter your email',
                prefixBuilder: (context, style, variants) =>
                    FTextField.prefixIconBuilder(
                  context,
                  style,
                  variants,
                  const Icon(FIcons.mail),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              FTextField.password(
                control: FTextFieldControl.managed(
                  controller: _passwordController,
                ),
                hint: 'Enter your password',
                textInputAction:
                    _isSignUp ? TextInputAction.next : TextInputAction.done,
                prefixBuilder: (context, style, obscure, variants) =>
                    FTextField.prefixIconBuilder(
                  context,
                  style,
                  variants,
                  const Icon(FIcons.lock),
                ),
                onSubmit: _isSignUp ? null : (_) => _handleEmailAction(),
              ),

              // Confirm password field (sign-up only)
              if (_isSignUp) ...[
                const SizedBox(height: 16),
                FTextField.password(
                  control: FTextFieldControl.managed(
                    controller: _confirmPasswordController,
                  ),
                  label: const Text('Confirm password'),
                  hint: 'Re-enter your password',
                  textInputAction: TextInputAction.done,
                  prefixBuilder: (context, style, obscure, variants) =>
                      FTextField.prefixIconBuilder(
                    context,
                    style,
                    variants,
                    const Icon(FIcons.lock),
                  ),
                  onSubmit: (_) => _handleEmailAction(),
                ),
              ],

              const SizedBox(height: 24),

              // Submit button
              FButton(
                variant: FButtonVariant.primary,
                onPress: _isEmailLoading ? null : _handleEmailAction,
                prefix: _isEmailLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: FCircularProgress(),
                      )
                    : Icon(_isSignUp ? FIcons.userPlus : FIcons.logIn),
                child: Text(
                  _isSignUp ? 'Create account' : 'Sign in with email',
                ),
              ),
              const SizedBox(height: 12),

              // Google sign-in button
              FButton(
                variant: FButtonVariant.outline,
                onPress: _isGoogleLoading ? null : _handleGoogleSignIn,
                prefix: _isGoogleLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: FCircularProgress(),
                      )
                    : const Icon(FIcons.globe),
                child: Text(
                  _isGoogleLoading
                      ? 'Launching Google...'
                      : 'Continue with Google',
                ),
              ),
              const SizedBox(height: 12),

              // Apple sign-in button
              FButton(
                variant: FButtonVariant.outline,
                onPress: () => _showComingSoon('Apple Sign-In'),
                prefix: const Icon(FIcons.apple),
                child: const Text('Continue with Apple'),
              ),
              const SizedBox(height: 16),

              // Terms text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'By continuing you agree to our Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: context.theme.typography.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEmailAction() async {
    FocusManager.instance.primaryFocus?.unfocus();

    // Validate fields
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email is required.');
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Enter a valid email.');
      return;
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Password is required.');
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = 'Use at least 8 characters for the password.');
      return;
    }

    if (_isSignUp) {
      final confirm = _confirmPasswordController.text;
      if (confirm.isEmpty) {
        setState(() => _errorMessage = 'Please confirm your password.');
        return;
      }
      if (confirm != password) {
        setState(() => _errorMessage = 'Passwords do not match.');
        return;
      }
    }

    setState(() {
      _isEmailLoading = true;
      _errorMessage = null;
    });

    final controller = ref.read(authControllerProvider);

    try {
      if (_isSignUp) {
        await controller.signUpWithEmail(
          email: email,
          password: password,
          fullName: _fullNameController.text.trim(),
        );
        setState(() {
          _isSignUp = false;
          _confirmPasswordController.clear();
          _errorMessage = null;
        });
      } else {
        await controller.signInWithEmail(
          email: email,
          password: password,
        );
      }
    } on AuthControllerException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _isEmailLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    final controller = ref.read(authControllerProvider);
    try {
      await controller.signInWithGoogle();
    } on AuthControllerException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _showComingSoon(String label) {
    setState(() => _errorMessage = '$label flow coming soon.');
  }
}
