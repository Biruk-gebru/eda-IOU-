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
    () async {
      try {
        final currentSession = client.auth.currentSession;
        if (currentSession != null && currentSession.isExpired) {
          try {
            final response = await client.auth.refreshSession();
            controller.add(response.session);
          } catch (e) {
            // Refresh failed — still emit the expired session so the app
            // can work offline with cached data instead of showing error
            debugPrint('Session refresh failed: $e');
            controller.add(null);
          }
        } else {
          controller.add(currentSession);
        }
      } catch (e) {
        debugPrint('Session recovery failed: $e');
        controller.add(null);
      }
    }();

    final sub = client.auth.onAuthStateChange.listen(
      (authState) {
        controller.add(authState.session);
      },
      onError: (e) {
        // PKCE code verifier errors happen when OAuth redirect opens a
        // fresh app instance — the code verifier was stored in the
        // previous instance's local storage. Emit null to show sign-in.
        debugPrint('Auth state error: $e');
        controller.add(null);
      },
    );

    controller.onCancel = () => sub.cancel();
  });
});
