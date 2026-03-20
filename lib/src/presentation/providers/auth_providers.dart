import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authSessionProvider = StreamProvider<Session?>((ref) {
  final client = ref.watch(supabaseClientProvider);

  return Stream<Session?>.multi((controller) {
    // Try to recover the persisted session before emitting.
    // currentSession may be null momentarily on cold start while the SDK
    // restores & refreshes the token from local storage.
    () async {
      try {
        final currentSession = client.auth.currentSession;
        if (currentSession != null && currentSession.isExpired) {
          // Token expired — ask the SDK to refresh it using the refresh token.
          final response = await client.auth.refreshSession();
          controller.add(response.session);
        } else {
          controller.add(currentSession);
        }
      } catch (e) {
        // Refresh failed (e.g. refresh token also expired) — emit null
        // so the user is sent to the sign-in screen.
        debugPrint('Session recovery failed: $e');
        controller.add(null);
      }
    }();

    final sub = client.auth.onAuthStateChange.listen(
      (authState) => controller.add(authState.session),
      onError: controller.addError,
    );

    controller.onCancel = () => sub.cancel();
  });
});
