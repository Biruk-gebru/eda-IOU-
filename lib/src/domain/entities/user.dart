class User {
  final String id;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String? preferredPaymentMethod;
  final Map<String, dynamic>? paymentDetails;
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final DateTime? createdAt;

  const User({
    required this.id,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.preferredPaymentMethod,
    this.paymentDetails,
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        displayName: json['display_name'] as String?,
        email: json['email'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        preferredPaymentMethod: json['preferred_payment_method'] as String?,
        paymentDetails: json['payment_details'] != null
            ? Map<String, dynamic>.from(json['payment_details'] as Map)
            : null,
        bankName: json['bank_name'] as String?,
        accountName: json['account_name'] as String?,
        accountNumber: json['account_number'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'email': email,
        'avatar_url': avatarUrl,
        'preferred_payment_method': preferredPaymentMethod,
        'payment_details': paymentDetails,
        'bank_name': bankName,
        'account_name': accountName,
        'account_number': accountNumber,
        'created_at': createdAt?.toIso8601String(),
      };
}
