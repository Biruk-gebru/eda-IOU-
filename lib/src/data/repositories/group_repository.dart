import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';

class GroupRepository {
  GroupRepository(this._client);

  final SupabaseClient _client;
  static const _boxName = 'groups_cache';

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<Group>> getGroups() async {
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.contains(ConnectivityResult.none);

    if (isOffline) return _getCachedGroups();

    try {
      // Only return groups where the current user has an active membership.
      // Pending invitees must accept before the group appears in their list.
      final data = await _client
          .from('group_members')
          .select('groups(*)')
          .eq('user_id', _userId!)
          .eq('status', 'active')
          .order('created_at', ascending: false);
      final groups = (data as List)
          .map((e) => Group.fromJson(e['groups'] as Map<String, dynamic>))
          .toList();
      await _cacheGroups(groups);
      return groups;
    } catch (e) {
      return _getCachedGroups();
    }
  }

  Stream<List<Group>> watchGroups() {
    return _client
        .from('groups')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      final groups = data.map((e) => Group.fromJson(e)).toList();
      _cacheGroups(groups);
      return groups;
    }).handleError((_) {});
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
    await _client.from('group_members').insert({
      'group_id': data['id'],
      'user_id': _userId,
      'role': 'creator',
      'status': 'active',
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

  Future<List<GroupMember>> getMembers(String groupId) async {
    final data = await _client
        .from('group_members')
        .select()
        .eq('group_id', groupId)
        .order('joined_at');
    return (data as List).map((e) => GroupMember.fromJson(e)).toList();
  }

  /// Sends a pending invitation to [userId]. Creates a `group_members` row
  /// with status='pending' and inserts a notification for the invitee.
  Future<void> inviteMember(
      String groupId, String userId, String groupName) async {
    await _client.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'member',
      'status': 'pending',
      'invited_by': _userId,
    });
    await _client.from('notifications').insert({
      'user_id': userId,
      'type': 'group_invitation',
      'payload': {
        'group_id': groupId,
        'group_name': groupName,
        'invited_by': _userId,
      },
    });
  }

  /// Accepts a pending invitation for the current user.
  Future<void> acceptInvitation(String groupId) async {
    await _client
        .from('group_members')
        .update({'status': 'active'})
        .eq('group_id', groupId)
        .eq('user_id', _userId!);
  }

  /// Declines (deletes) a pending invitation for the current user.
  Future<void> declineInvitation(String groupId) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', _userId!);
  }

  /// Returns all groups where the current user has a pending invitation,
  /// including the group name via PostgREST FK embedding.
  Future<List<({GroupMember member, String groupName})>>
      getPendingInvitations() async {
    final data = await _client
        .from('group_members')
        .select('*, groups(name)')
        .eq('user_id', _userId!)
        .eq('status', 'pending');
    return (data as List).map((e) {
      final member = GroupMember.fromJson(e);
      final groupName =
          (e['groups'] as Map?)?['name'] as String? ?? 'Unknown group';
      return (member: member, groupName: groupName);
    }).toList();
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  // Caching
  Future<List<Group>> _getCachedGroups() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final List<Group> groups = [];
      for (var i = 0; i < box.length; i++) {
        final json = box.getAt(i);
        if (json != null) {
          try {
            groups.add(Group.fromJson(jsonDecode(json)));
          } catch (_) {}
        }
      }
      return groups;
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheGroups(List<Group> groups) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.clear();
      for (var i = 0; i < groups.length; i++) {
        await box.put(i, jsonEncode(groups[i].toJson()));
      }
    } catch (_) {}
  }
}
