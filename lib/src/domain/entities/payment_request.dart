class PaymentRequest {
  final String id;
  final String payerId;
  final String receiverId;
  final double amount;
  final String? relatedTransactionId;
  final String? groupId;
  final String status;
  final String? method;
  final String? note;
  final DateTime? createdAt;
  final DateTime? confirmedAt;
  final DateTime? timeoutAt;

  const PaymentRequest({
    required this.id,
    required this.payerId,
    required this.receiverId,
    required this.amount,
    this.relatedTransactionId,
    this.groupId,
    this.status = 'pending',
    this.method,
    this.note,
    this.createdAt,
    this.confirmedAt,
    this.timeoutAt,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) => PaymentRequest(
        id: json['id'] as String,
        payerId: json['payer_id'] as String,
        receiverId: json['receiver_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        relatedTransactionId: json['related_transaction_id'] as String?,
        groupId: json['group_id'] as String?,
        status: json['status'] as String? ?? 'pending',
        method: json['method'] as String?,
        note: json['note'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        confirmedAt: json['confirmed_at'] != null
            ? DateTime.parse(json['confirmed_at'] as String)
            : null,
        timeoutAt: json['timeout_at'] != null
            ? DateTime.parse(json['timeout_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'payer_id': payerId,
        'receiver_id': receiverId,
        'amount': amount,
        'related_transaction_id': relatedTransactionId,
        'group_id': groupId,
        'status': status,
        'method': method,
        'note': note,
        'created_at': createdAt?.toIso8601String(),
        'confirmed_at': confirmedAt?.toIso8601String(),
        'timeout_at': timeoutAt?.toIso8601String(),
      };
}
