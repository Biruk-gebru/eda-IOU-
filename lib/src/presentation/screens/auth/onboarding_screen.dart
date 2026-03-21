import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/user.dart' as domain;
import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your display name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final repository = ref.read(userRepositoryProvider);
      await repository.updateUser(domain.User(id: userId, displayName: name));

      ref.invalidate(authSessionProvider);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    return FScaffold(
      header: const FHeader(title: Text('Complete your profile')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border, width: 1.5),
              ),
              child: Icon(FIcons.user, size: 34, color: colors.foreground),
            ),
            const SizedBox(height: 24),

            // Heading
            Text(
              'What should we call you?',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This name is shown to others when you create\nor approve transactions.',
              style: typo.sm.copyWith(color: colors.mutedForeground, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            // Name field
            FTextField(
              control: FTextFieldControl.managed(controller: _nameController),
              label: const Text('Display name'),
              hint: 'e.g. Alex',
              enabled: !_isSubmitting,
              textCapitalization: TextCapitalization.words,
              prefixBuilder: (context, style, variants) => FTextField.prefixIconBuilder(
                context, style, variants, const Icon(FIcons.user),
              ),
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: _isSubmitting ? null : _submit,
                prefix: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: FCircularProgress())
                    : const Icon(FIcons.arrowRight),
                child: const Text('Save and continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
