import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    @JsonKey(name: 'display_name') String? displayName,
    String? email,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'preferred_payment_method') String? preferredPaymentMethod,
    @JsonKey(name: 'payment_details') Map<String, dynamic>? paymentDetails,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'account_name') String? accountName,
    @JsonKey(name: 'account_number') String? accountNumber,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  const User._();
}
