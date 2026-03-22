import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';
import '../setup/bank_info_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  bool _isSubmitting = false;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      return;
    }
    if (name.length < 2) {
      setState(() => _nameError = 'At least 2 characters');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _nameError = null;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Check if name is already taken
      final existing = await client
          .from('profiles')
          .select('id')
          .ilike('display_name', name)
          .neq('id', userId)
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          setState(() {
            _nameError = 'This name is already taken';
            _isSubmitting = false;
          });
        }
        return;
      }

      // Save name to profiles
      await client.from('profiles').upsert({
        'id': userId,
        'display_name': name,
        'updated_at': DateTime.now().toIso8601String(),
      });

      ref.invalidate(currentUserProvider);

      if (mounted) {
        // Go to banking info (skippable)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BankInfoScreen()),
        );
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
      header: const FHeader(title: Text('Set up your profile')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
              style:
                  typo.sm.copyWith(color: colors.mutedForeground, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            FTextField(
              control: FTextFieldControl.managed(controller: _nameController),
              label: const Text('Your name'),
              hint: 'e.g. Alex',
              description: _nameError != null
                  ? Text(_nameError!,
                      style: typo.xs.copyWith(color: colors.destructive))
                  : const Text('2-30 characters'),
              enabled: !_isSubmitting,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [LengthLimitingTextInputFormatter(30)],
              prefixBuilder: (context, style, variants) =>
                  FTextField.prefixIconBuilder(
                      context, style, variants, const Icon(FIcons.user)),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: _isSubmitting ? null : _next,
                prefix: _isSubmitting
                    ? const SizedBox(
                        width: 18, height: 18, child: FCircularProgress())
                    : const Icon(FIcons.arrowRight),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
