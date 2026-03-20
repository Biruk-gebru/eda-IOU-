import 'package:freezed_annotation/freezed_annotation.dart';
import 'banking_info.dart';

part 'user.freezed.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String displayName,
    required String email,
    String? avatarUrl,
    String? preferredPaymentMethod,
    Map<String, dynamic>? paymentDetails,
    BankingInfo? bankingInfo,
    required DateTime createdAt,
  }) = _User;

  const User._();
}
