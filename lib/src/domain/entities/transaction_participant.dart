class TransactionParticipant {
  final String id;
  final String transactionId;
  final String userId;
  final double amountDue;
  final bool? approved;
  final DateTime? approvedAt;
  final DateTime? createdAt;

  const TransactionParticipant({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.amountDue,
    this.approved,
    this.approvedAt,
    this.createdAt,
  });

  factory TransactionParticipant.fromJson(Map<String, dynamic> json) =>
      TransactionParticipant(
        id: json['id'] as String,
        transactionId: json['transaction_id'] as String,
        userId: json['user_id'] as String,
        amountDue: (json['amount_due'] as num).toDouble(),
        approved: json['approved'] as bool?,
        approvedAt: json['approved_at'] != null
            ? DateTime.parse(json['approved_at'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_id': transactionId,
        'user_id': userId,
        'amount_due': amountDue,
        'approved': approved,
        'approved_at': approvedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };
}
