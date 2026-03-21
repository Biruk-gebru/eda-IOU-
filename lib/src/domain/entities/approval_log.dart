class ApprovalLog {
  final String id;
  final String transactionId;
  final String userId;
  final String action;
  final DateTime? createdAt;

  const ApprovalLog({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.action,
    this.createdAt,
  });

  factory ApprovalLog.fromJson(Map<String, dynamic> json) => ApprovalLog(
        id: json['id'] as String,
        transactionId: json['transaction_id'] as String,
        userId: json['user_id'] as String,
        action: json['action'] as String,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_id': transactionId,
        'user_id': userId,
        'action': action,
        'created_at': createdAt?.toIso8601String(),
      };
}
