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
