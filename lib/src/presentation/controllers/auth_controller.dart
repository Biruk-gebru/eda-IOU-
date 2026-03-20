import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_config.dart';
import '../providers/auth_providers.dart';

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ref),
);

class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  SupabaseClient get _client => _ref.read(supabaseClientProvider);

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e, s) {
      Error.safeToString(s);
      throw AuthControllerException(e.message);
    } catch (e) {
      throw AuthControllerException('Unable to sign in. Please try again.');
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: fullName?.isNotEmpty == true ? {'full_name': fullName} : null,
      );
    } on AuthException catch (e) {
      throw AuthControllerException(e.message);
    } catch (_) {
      throw AuthControllerException('Unable to sign up. Please try again.');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.oauthRedirectUrl.isEmpty
            ? null
            : SupabaseConfig.oauthRedirectUrl,
      );
    } on AuthException catch (e) {
      throw AuthControllerException(e.message);
    } catch (_) {
      throw AuthControllerException(
        'Unable to start Google sign-in. Check your OAuth settings.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthControllerException(e.message);
    } catch (_) {
      throw AuthControllerException('Unable to sign out right now.');
    }
  }
}

class AuthControllerException implements Exception {
  const AuthControllerException(this.message);

  final String message;

  @override
  String toString() => 'AuthControllerException: $message';
}
