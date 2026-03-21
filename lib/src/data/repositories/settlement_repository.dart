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

  Future<SettlementRequest> createSettlementRequest({
    required String payerId,
    required String receiverId,
    required double amount,
  }) async {
    final data = await _client.from('settlement_requests').insert({
      'initiator_id': _userId,
      'payer_id': payerId,
      'receiver_id': receiverId,
      'amount': amount,
    }).select().single();
    return SettlementRequest.fromJson(data);
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

  Future<void> rejectSettlement(String settlementRequestId) async {
    await _client.from('settlement_requests').update({
      'status': 'rejected',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', settlementRequestId);
  }
}
