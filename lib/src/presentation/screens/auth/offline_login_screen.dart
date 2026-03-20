import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../providers/auth_providers.dart';

class OfflineLoginScreen extends ConsumerWidget {
  const OfflineLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FScaffold(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FCard(
            title: const Text('You are offline'),
            subtitle: const Text(
              'We cannot log you in while you are offline. '
              'Please check your internet connection and try again.',
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FButton(
                onPress: () => ref.refresh(authSessionProvider),
                prefix: const Icon(FIcons.refreshCw),
                child: const Text('Retry Connection'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
