import 'package:freezed_annotation/freezed_annotation.dart';

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
    required DateTime createdAt,
  }) = _User;
  
  const User._();
}