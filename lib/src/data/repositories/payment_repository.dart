import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/payment_request.dart';

class PaymentRepository {
  PaymentRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  /// Calls the Supabase RPC to expire any pending payment requests whose
  /// timeout_at has passed. Returns the number of expired requests.
  Future<int> checkAndExpirePayments() async {
    try {
      final result =
          await _client.rpc('auto_expire_payment_requests');
      return (result as int?) ?? 0;
    } catch (e) {
      // Non-critical — don't block the fetch if cleanup fails
      return 0;
    }
  }

  Future<List<PaymentRequest>> getPaymentRequests() async {
    // Expire timed-out payment requests before fetching
    await checkAndExpirePayments();

    final data = await _client
        .from('payment_requests')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => PaymentRequest.fromJson(e)).toList();
  }

  Stream<List<PaymentRequest>> watchPaymentRequests() {
    return _client
        .from('payment_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => PaymentRequest.fromJson(e)).toList());
  }

  Future<PaymentRequest> createPaymentRequest({
    required String receiverId,
    required double amount,
    String? payerId,
    String? relatedTransactionId,
    String? groupId,
    String? method,
    String? note,
  }) async {
    final data = await _client.from('payment_requests').insert({
      'payer_id': payerId ?? _userId,
      'receiver_id': receiverId,
      'amount': amount,
      'related_transaction_id': relatedTransactionId,
      'group_id': groupId,
      'method': method,
      'note': note,
    }).select().single();
    return PaymentRequest.fromJson(data);
  }

  Future<List<PaymentRequest>> getGroupPaymentRequests(String groupId) async {
    final data = await _client
        .from('payment_requests')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => PaymentRequest.fromJson(e)).toList();
  }

  Future<void> confirmPayment(String paymentRequestId) async {
    await _client.from('payment_requests').update({
      'status': 'confirmed',
      'confirmed_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentRequestId);

    await _client.rpc('apply_payment', params: {
      'p_payment_request_id': paymentRequestId,
    });
  }

  Future<void> rejectPayment(String paymentRequestId) async {
    await _client.from('payment_requests').update({
      'status': 'rejected',
    }).eq('id', paymentRequestId);
  }
}
