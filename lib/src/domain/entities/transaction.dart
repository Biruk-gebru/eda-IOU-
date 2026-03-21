class Transaction {
  final String id;
  final String? groupId;
  final String? description;
  final String creatorId;
  final String payerId;
  final double totalAmount;
  final String currency;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? timeoutAt;
  final String status;

  const Transaction({
    required this.id,
    this.groupId,
    this.description,
    required this.creatorId,
    required this.payerId,
    required this.totalAmount,
    this.currency = 'ETB',
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.timeoutAt,
    this.status = 'pending',
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        groupId: json['group_id'] as String?,
        description: json['description'] as String?,
        creatorId: json['creator_id'] as String,
        payerId: json['payer_id'] as String,
        totalAmount: (json['total_amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'ETB',
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        timeoutAt: json['timeout_at'] != null
            ? DateTime.parse(json['timeout_at'] as String)
            : null,
        status: json['status'] as String? ?? 'pending',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'description': description,
        'creator_id': creatorId,
        'payer_id': payerId,
        'total_amount': totalAmount,
        'currency': currency,
        'metadata': metadata,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'timeout_at': timeoutAt?.toIso8601String(),
        'status': status,
      };
}
