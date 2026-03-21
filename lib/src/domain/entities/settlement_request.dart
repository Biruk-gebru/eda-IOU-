class SettlementRequest {
  final String id;
  final String initiatorId;
  final String payerId;
  final String receiverId;
  final double amount;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SettlementRequest({
    required this.id,
    required this.initiatorId,
    required this.payerId,
    required this.receiverId,
    required this.amount,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory SettlementRequest.fromJson(Map<String, dynamic> json) {
    return SettlementRequest(
      id: json['id'] as String,
      initiatorId: json['initiator_id'] as String,
      payerId: json['payer_id'] as String,
      receiverId: json['receiver_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'initiator_id': initiatorId,
        'payer_id': payerId,
        'receiver_id': receiverId,
        'amount': amount,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
