import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';

class GroupRepository {
  GroupRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Group>> getGroups() async {
    final data = await _client
        .from('groups')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => Group.fromJson(e)).toList();
  }

  Stream<List<Group>> watchGroups() {
    return _client
        .from('groups')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => Group.fromJson(e)).toList());
  }

  Future<Group> getGroup(String groupId) async {
    final data =
        await _client.from('groups').select().eq('id', groupId).single();
    return Group.fromJson(data);
  }

  Future<Group> createGroup({
    required String name,
    String? description,
  }) async {
    final data = await _client.from('groups').insert({
      'name': name,
      'description': description,
      'creator_id': _userId,
    }).select().single();
    // Also add creator as a member
    await _client.from('group_members').insert({
      'group_id': data['id'],
      'user_id': _userId,
      'role': 'creator',
    });
    return Group.fromJson(data);
  }

  Future<void> updateGroup(Group group) async {
    await _client.from('groups').update({
      'name': group.name,
      'description': group.description,
      'join_mode': group.joinMode,
    }).eq('id', group.id);
  }

  Future<void> deleteGroup(String groupId) async {
    await _client.from('groups').delete().eq('id', groupId);
  }

  // Members
  Future<List<GroupMember>> getMembers(String groupId) async {
    final data = await _client
        .from('group_members')
        .select()
        .eq('group_id', groupId)
        .order('joined_at');
    return (data as List).map((e) => GroupMember.fromJson(e)).toList();
  }

  Future<void> addMember(String groupId, String userId) async {
    await _client.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'member',
    });
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }
}
