import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_config.dart';
import '../providers/auth_providers.dart';
import '../providers/balance_providers.dart';
import '../providers/group_providers.dart';
import '../providers/transaction_providers.dart';
import '../providers/user_providers.dart';

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
    } on AuthException catch (e) {
      throw AuthControllerException(_friendly(e.message));
    } catch (e) {
      throw AuthControllerException(_friendly(e.toString()));
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
      throw AuthControllerException(_friendly(e.message));
    } catch (e) {
      throw AuthControllerException(_friendly(e.toString()));
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
      throw AuthControllerException(_friendly(e.message));
    } catch (e) {
      throw AuthControllerException(_friendly(e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();

      // Clear all cached data from previous session
      await _clearAllCaches();

      // Invalidate all providers so they don't hold stale data
      _ref.invalidate(currentUserProvider);
      _ref.invalidate(transactionListProvider);
      _ref.invalidate(groupListProvider);
      _ref.invalidate(balancesProvider);
    } on AuthException catch (e) {
      throw AuthControllerException(e.message);
    } catch (_) {
      throw AuthControllerException('Unable to sign out right now.');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw AuthControllerException('Not signed in');

      // Delete profile (cascades to banking_accounts, group_members, etc.)
      await _client.from('profiles').delete().eq('id', userId);

      await _client.auth.signOut();
      await _clearAllCaches();

      _ref.invalidate(currentUserProvider);
      _ref.invalidate(transactionListProvider);
      _ref.invalidate(groupListProvider);
      _ref.invalidate(balancesProvider);
    } on AuthException catch (e) {
      throw AuthControllerException(e.message);
    } catch (e) {
      throw AuthControllerException('Unable to delete account: $e');
    }
  }

  Future<void> _clearAllCaches() async {
    try {
      final boxes = ['user_profile', 'transactions', 'groups_cache', 'balances_cache'];
      for (final name in boxes) {
        if (Hive.isBoxOpen(name)) {
          await Hive.box<String>(name).clear();
        } else {
          final box = await Hive.openBox<String>(name);
          await box.clear();
        }
      }
    } catch (_) {
      // Non-critical — don't block sign out
    }
  }
}

class AuthControllerException implements Exception {
  const AuthControllerException(this.message);

  final String message;

  @override
  String toString() => 'AuthControllerException: $message';
}

String _friendly(String raw) {
  final s = raw.toLowerCase();
  if (s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('no address') ||
      s.contains('clientexception') ||
      s.contains('errno')) {
    return 'No internet connection. Check your Wi-Fi or mobile data and try again.';
  }
  if (s.contains('invalid login credentials') ||
      s.contains('invalid email or password') ||
      s.contains('wrong password')) {
    return 'Incorrect email or password.';
  }
  if (s.contains('email not confirmed')) {
    return 'Please verify your email before signing in.';
  }
  if (s.contains('user already registered')) {
    return 'An account with this email already exists. Try signing in.';
  }
  if (s.contains('password should be at least') ||
      s.contains('weak password')) {
    return 'Password is too weak — use at least 8 characters.';
  }
  if (s.contains('rate limit') || s.contains('too many requests')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  return raw;
}
