import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/group_repository.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';
import 'auth_providers.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GroupRepository(client);
});

final groupListProvider = StreamProvider<List<Group>>((ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.watchGroups();
});

final groupDetailProvider =
    FutureProvider.family<Group, String>((ref, groupId) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroup(groupId);
});

final groupMembersProvider =
    FutureProvider.family<List<GroupMember>, String>((ref, groupId) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getMembers(groupId);
});

final pendingInvitationsProvider =
    StreamProvider<List<({GroupMember member, String groupName})>>((ref) async* {
  final repo = ref.watch(groupRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);

  await for (final members in repo.watchPendingInvitations()) {
    if (members.isEmpty) {
      yield [];
      continue;
    }
    final withNames = await Future.wait(members.map((m) async {
      try {
        final data = await client
            .from('groups')
            .select('name')
            .eq('id', m.groupId)
            .single();
        return (member: m, groupName: data['name'] as String? ?? 'Unknown group');
      } catch (_) {
        return (member: m, groupName: 'Unknown group');
      }
    }));
    yield withNames;
  }
});
