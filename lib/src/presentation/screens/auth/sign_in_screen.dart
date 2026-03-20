import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(context),
              const SizedBox(height: 32),
              Text(
                _isSignUp ? 'Create your account' : 'Welcome back',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'Sign up to start tracking IOUs with approvals.'
                    : 'Sign in to keep your groups and balances in sync.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _buildModeToggle(colorScheme),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _fullNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: _isSignUp
                          ? TextInputAction.next
                          : TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_person_outlined),
                        ),
                        validator: (value) {
                          if (!_isSignUp) return null;
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: Icon(
                          _isSignUp ? Icons.person_add_alt : Icons.login,
                        ),
                        label: Text(
                          _isSignUp ? 'Create account' : 'Sign in with email',
                        ),
                        onPressed: _isEmailLoading ? null : _handleEmailAction,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: _GoogleLogo(isLoading: _isGoogleLoading),
                        label: Text(
                          _isGoogleLoading
                              ? 'Launching Google...'
                              : 'Continue with Google',
                        ),
                        onPressed: _isGoogleLoading
                            ? null
                            : () => _handleGoogleSignIn(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.apple),
                        label: const Text('Continue with Apple'),
                        onPressed: () =>
                            _showComingSoon(context, 'Apple Sign-In'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'By continuing you agree to our Terms of Service and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle(ColorScheme colorScheme) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: false, label: Text('Sign in')),
        ButtonSegment(value: true, label: Text('Sign up')),
      ],
      selected: {_isSignUp},
      style: SegmentedButton.styleFrom(
        backgroundColor: colorScheme.surfaceVariant,
        selectedBackgroundColor: colorScheme.primary.withValues(alpha: 0.15),
        selectedForegroundColor: colorScheme.primary,
      ),
      onSelectionChanged: (selection) {
        setState(() {
          _isSignUp = selection.first;
        });
      },
    );
  }

  Widget _buildHero(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Track and settle balances',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Requests • Approvals • Payments',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEmailAction() async {
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isEmailLoading = true);
    final controller = ref.read(authControllerProvider);

    try {
      if (_isSignUp) {
        await controller.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
        );
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Check your inbox to confirm your email.'),
          ),
        );
        setState(() {
          _isSignUp = false;
          _confirmPasswordController.clear();
        });
      } else {
        await controller.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on AuthControllerException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _isEmailLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isGoogleLoading = true);

    final controller = ref.read(authControllerProvider);
    try {
      await controller.signInWithGoogle();
    } on AuthControllerException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label flow coming soon')));
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Image.network(
        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata),
      ),
    );
  }
}
