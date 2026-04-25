import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/user_repository.dart';
import '../../domain/entities/user.dart' as domain;
import 'auth_providers.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return UserRepository(client);
});

final currentUserProvider = FutureProvider<domain.User?>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getCurrentUser();
});

/// In-session cache for profile display names.
/// Call [prefetch] with a list of IDs to batch-load names in a single query,
/// then read names synchronously from [state].
class ProfileNameCache extends StateNotifier<Map<String, String>> {
  ProfileNameCache(this._client) : super({});

  final SupabaseClient _client;

  Future<void> prefetch(List<String> ids) async {
    final currentId = _client.auth.currentUser?.id;
    final missing = ids.where((id) => !state.containsKey(id)).toList();
    if (missing.isEmpty) return;

    final updates = <String, String>{};
    if (currentId != null && missing.contains(currentId)) {
      updates[currentId] = 'You';
    }
    final toFetch = missing.where((id) => id != currentId).toList();
    if (toFetch.isNotEmpty) {
      final rows = await _client
          .from('profiles')
          .select('id, display_name')
          .inFilter('id', toFetch);
      for (final r in rows as List) {
        updates[r['id'] as String] = r['display_name'] as String? ?? 'Unknown';
      }
    }
    state = {...state, ...updates};
  }

  String resolve(String id) => state[id] ?? '...';
}

final profileNameCacheProvider =
    StateNotifierProvider<ProfileNameCache, Map<String, String>>(
  (ref) => ProfileNameCache(ref.watch(supabaseClientProvider)),
);
