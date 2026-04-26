import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
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

    return Scaffold(
      backgroundColor: colors.background, // Paper
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.foreground, width: 1.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Set up your profile',
                      style: typo.xl2.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                        letterSpacing: -0.24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        border: Border.all(color: colors.foreground, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: colors.foreground,
                            offset: const Offset(4, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'What should we call you?',
                      style: typo.xl3.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                        letterSpacing: -0.64,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This name is shown to others when you create\nor approve transactions.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colors.mutedForeground,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR NAME',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          enabled: !_isSubmitting,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [LengthLimitingTextInputFormatter(30)],
                          style: typo.sm.copyWith(fontWeight: FontWeight.w500, color: colors.foreground),
                          decoration: InputDecoration(
                            hintText: 'e.g. Alex',
                            hintStyle: typo.sm.copyWith(color: colors.mutedForeground.withValues(alpha: 0.5)),
                            prefixIcon: Icon(FIcons.user, size: 18, color: colors.mutedForeground),
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
                        ),
                        if (_nameError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _nameError!,
                            style: GoogleFonts.inter(fontSize: 12, color: colors.destructive),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Text(
                            '2-30 characters',
                            style: GoogleFonts.inter(fontSize: 12, color: colors.mutedForeground),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 48),

                    GestureDetector(
                      onTap: _isSubmitting ? null : _next,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
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
                        child: _isSubmitting
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colors.foreground, strokeWidth: 2.5))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Next',
                                    style: typo.lg.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: colors.foreground,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(FIcons.arrowRight, size: 20, color: colors.foreground),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
