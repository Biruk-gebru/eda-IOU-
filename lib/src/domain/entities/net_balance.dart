class NetBalance {
  final String id;
  final String userA;
  final String userB;
  final double netAmount;
  final DateTime? lastUpdated;

  const NetBalance({
    required this.id,
    required this.userA,
    required this.userB,
    required this.netAmount,
    this.lastUpdated,
  });

  factory NetBalance.fromJson(Map<String, dynamic> json) => NetBalance(
        id: json['id'] as String,
        userA: json['user_a'] as String,
        userB: json['user_b'] as String,
        netAmount: (json['net_amount'] as num).toDouble(),
        lastUpdated: json['last_updated'] != null
            ? DateTime.parse(json['last_updated'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_a': userA,
        'user_b': userB,
        'net_amount': netAmount,
        'last_updated': lastUpdated?.toIso8601String(),
      };
}
