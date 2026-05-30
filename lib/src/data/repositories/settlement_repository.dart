import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/settlement_request.dart';

class SettlementRepository {
  SettlementRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<SettlementRequest>> getSettlementRequests() async {
    final data = await _client
        .from('settlement_requests')
        .select()
        .or('initiator_id.eq.$_userId,payer_id.eq.$_userId,receiver_id.eq.$_userId')
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => SettlementRequest.fromJson(e))
        .toList();
  }

  Stream<List<SettlementRequest>> watchSettlementRequests() {
    return _client
        .from('settlement_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((e) => SettlementRequest.fromJson(e)).toList());
  }

  /// Returns IDs of users who share an active group with the current user,
  /// excluding the current user themselves.
  Future<List<Map<String, dynamic>>> getGroupContacts() async {
    // Step 1 — groups the current user is actively in.
    final myMemberships = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', _userId)
        .eq('status', 'active');
    final myGroupIds =
        (myMemberships as List).map((e) => e['group_id'] as String).toList();
    if (myGroupIds.isEmpty) return [];

    // Step 2 — all active members in those groups, excluding self.
    final rows = await _client
        .from('group_members')
        .select('user_id')
        .inFilter('group_id', myGroupIds)
        .eq('status', 'active')
        .neq('user_id', _userId);
    final uniqueIds =
        (rows as List).map((e) => e['user_id'] as String).toSet().toList();
    if (uniqueIds.isEmpty) return [];

    // Step 3 — fetch display names.
    final profiles = await _client
        .from('profiles')
        .select('id, display_name')
        .inFilter('id', uniqueIds);
    return List<Map<String, dynamic>>.from(profiles);
  }

  /// Creates a settlement request.
  /// Throws if the initiator, payer, and receiver do not all share an active group —
  /// settlement routing is intentionally restricted to known group members.
  Future<SettlementRequest> createSettlementRequest({
    required String payerId,
    required String receiverId,
    required double amount,
  }) async {
    final sharedGroup = await _sharedGroupId(_userId, payerId, receiverId);
    if (sharedGroup == null) {
      throw Exception(
        'Settlement routing requires all three parties to share a group.',
      );
    }

    final data = await _client.from('settlement_requests').insert({
      'initiator_id': _userId,
      'payer_id': payerId,
      'receiver_id': receiverId,
      'amount': amount,
    }).select().single();
    return SettlementRequest.fromJson(data);
  }

  Future<String?> _sharedGroupId(String a, String b, String c) async {
    Future<Set<String>> activeGroups(String userId) async {
      final rows = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId)
          .eq('status', 'active');
      return (rows as List).map((e) => e['group_id'] as String).toSet();
    }

    final groupsA = await activeGroups(a);
    final groupsB = await activeGroups(b);
    final groupsC = await activeGroups(c);
    final shared = groupsA.intersection(groupsB).intersection(groupsC);
    return shared.isEmpty ? null : shared.first;
  }

  Future<void> approveSettlement(String settlementRequestId) async {
    await _client.from('settlement_requests').update({
      'status': 'approved',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', settlementRequestId);

    // Fetch the settlement to create a direct payment request A -> C
    final settlement = await _client
        .from('settlement_requests')
        .select()
        .eq('id', settlementRequestId)
        .single();
    final req = SettlementRequest.fromJson(settlement);

    // Create payment request from payer (A) to receiver (C)
    await _client.from('payment_requests').insert({
      'payer_id': req.payerId,
      'receiver_id': req.receiverId,
      'amount': req.amount,
      'method': 'Settlement redirect',
      'note': 'Settlement payment via redirect',
    });

    // Apply settlement to update net_balances
    await _client.rpc('apply_settlement', params: {
      'p_settlement_request_id': settlementRequestId,
    });
  }

  /// Applies debt routing along an arbitrary chain of edges, each reduced by
  /// [amount]. Every person's total obligation stays the same — only who they
  /// owe changes. Changes are immediate and atomic (SECURITY DEFINER RPC).
  ///
  /// [chain] is an ordered list of {debtor_id, creditor_id} maps, e.g.:
  ///   1-hop  C→Me→B : [{C,Me}, {Me,B}]
  ///   2-hop D→C→Me→B: [{D,C}, {C,Me}, {Me,B}]
  Future<void> applyDebtRoutingChain({
    required List<Map<String, dynamic>> chain,
    required double amount,
  }) async {
    await _client.rpc('apply_debt_routing_chain', params: {
      'p_edges': chain,
      'p_amount': amount,
    });
  }

  Future<void> rejectSettlement(String settlementRequestId) async {
    await _client.from('settlement_requests').update({
      'status': 'rejected',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', settlementRequestId);
  }

  /// Returns all non-zero debt edges between active members of [groupId].
  /// Each entry is normalized to debtor → creditor form with display names.
  Future<List<Map<String, dynamic>>> getGroupNetBalances(String groupId) async {
    final membersRaw = await _client
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId)
        .eq('status', 'active');
    final memberIds =
        (membersRaw as List).map((e) => e['user_id'] as String).toList();
    if (memberIds.length < 2) return [];

    final balancesRaw = await _client
        .from('net_balances')
        .select('user_a, user_b, net_amount')
        .inFilter('user_a', memberIds)
        .inFilter('user_b', memberIds)
        .neq('net_amount', 0);

    final profilesRaw = await _client
        .from('profiles')
        .select('id, display_name')
        .inFilter('id', memberIds);
    final nameMap = {
      for (final p in profilesRaw as List)
        p['id'] as String: p['display_name'] as String? ?? 'Unknown',
    };

    return (balancesRaw as List).map((b) {
      final userA = b['user_a'] as String;
      final userB = b['user_b'] as String;
      final net = (b['net_amount'] as num).toDouble();
      final debtorId = net > 0 ? userA : userB;
      final creditorId = net > 0 ? userB : userA;
      return {
        'debtor_id': debtorId,
        'debtor_name': nameMap[debtorId] ?? 'Unknown',
        'creditor_id': creditorId,
        'creditor_name': nameMap[creditorId] ?? 'Unknown',
        'amount': net.abs(),
      };
    }).toList();
  }
}
