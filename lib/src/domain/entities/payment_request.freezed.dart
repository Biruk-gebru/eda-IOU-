// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PaymentRequest {
  String get id => throw _privateConstructorUsedError;
  String get payerId => throw _privateConstructorUsedError;
  String get receiverId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String? get relatedTransactionId => throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get method => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get confirmedAt => throw _privateConstructorUsedError;

  /// Create a copy of PaymentRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentRequestCopyWith<PaymentRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentRequestCopyWith<$Res> {
  factory $PaymentRequestCopyWith(
    PaymentRequest value,
    $Res Function(PaymentRequest) then,
  ) = _$PaymentRequestCopyWithImpl<$Res, PaymentRequest>;
  @useResult
  $Res call({
    String id,
    String payerId,
    String receiverId,
    double amount,
    String? relatedTransactionId,
    String? groupId,
    String status,
    String? method,
    String? note,
    DateTime createdAt,
    DateTime? confirmedAt,
  });
}

/// @nodoc
class _$PaymentRequestCopyWithImpl<$Res, $Val extends PaymentRequest>
    implements $PaymentRequestCopyWith<$Res> {
  _$PaymentRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? payerId = null,
    Object? receiverId = null,
    Object? amount = null,
    Object? relatedTransactionId = freezed,
    Object? groupId = freezed,
    Object? status = null,
    Object? method = freezed,
    Object? note = freezed,
    Object? createdAt = null,
    Object? confirmedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            payerId: null == payerId
                ? _value.payerId
                : payerId // ignore: cast_nullable_to_non_nullable
                      as String,
            receiverId: null == receiverId
                ? _value.receiverId
                : receiverId // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            relatedTransactionId: freezed == relatedTransactionId
                ? _value.relatedTransactionId
                : relatedTransactionId // ignore: cast_nullable_to_non_nullable
                      as String?,
            groupId: freezed == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            method: freezed == method
                ? _value.method
                : method // ignore: cast_nullable_to_non_nullable
                      as String?,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            confirmedAt: freezed == confirmedAt
                ? _value.confirmedAt
                : confirmedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaymentRequestImplCopyWith<$Res>
    implements $PaymentRequestCopyWith<$Res> {
  factory _$$PaymentRequestImplCopyWith(
    _$PaymentRequestImpl value,
    $Res Function(_$PaymentRequestImpl) then,
  ) = __$$PaymentRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String payerId,
    String receiverId,
    double amount,
    String? relatedTransactionId,
    String? groupId,
    String status,
    String? method,
    String? note,
    DateTime createdAt,
    DateTime? confirmedAt,
  });
}

/// @nodoc
class __$$PaymentRequestImplCopyWithImpl<$Res>
    extends _$PaymentRequestCopyWithImpl<$Res, _$PaymentRequestImpl>
    implements _$$PaymentRequestImplCopyWith<$Res> {
  __$$PaymentRequestImplCopyWithImpl(
    _$PaymentRequestImpl _value,
    $Res Function(_$PaymentRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PaymentRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? payerId = null,
    Object? receiverId = null,
    Object? amount = null,
    Object? relatedTransactionId = freezed,
    Object? groupId = freezed,
    Object? status = null,
    Object? method = freezed,
    Object? note = freezed,
    Object? createdAt = null,
    Object? confirmedAt = freezed,
  }) {
    return _then(
      _$PaymentRequestImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        payerId: null == payerId
            ? _value.payerId
            : payerId // ignore: cast_nullable_to_non_nullable
                  as String,
        receiverId: null == receiverId
            ? _value.receiverId
            : receiverId // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        relatedTransactionId: freezed == relatedTransactionId
            ? _value.relatedTransactionId
            : relatedTransactionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        groupId: freezed == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        method: freezed == method
            ? _value.method
            : method // ignore: cast_nullable_to_non_nullable
                  as String?,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        confirmedAt: freezed == confirmedAt
            ? _value.confirmedAt
            : confirmedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$PaymentRequestImpl extends _PaymentRequest {
  const _$PaymentRequestImpl({
    required this.id,
    required this.payerId,
    required this.receiverId,
    required this.amount,
    this.relatedTransactionId,
    this.groupId,
    required this.status,
    this.method,
    this.note,
    required this.createdAt,
    this.confirmedAt,
  }) : super._();

  @override
  final String id;
  @override
  final String payerId;
  @override
  final String receiverId;
  @override
  final double amount;
  @override
  final String? relatedTransactionId;
  @override
  final String? groupId;
  @override
  final String status;
  @override
  final String? method;
  @override
  final String? note;
  @override
  final DateTime createdAt;
  @override
  final DateTime? confirmedAt;

  @override
  String toString() {
    return 'PaymentRequest(id: $id, payerId: $payerId, receiverId: $receiverId, amount: $amount, relatedTransactionId: $relatedTransactionId, groupId: $groupId, status: $status, method: $method, note: $note, createdAt: $createdAt, confirmedAt: $confirmedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.payerId, payerId) || other.payerId == payerId) &&
            (identical(other.receiverId, receiverId) ||
                other.receiverId == receiverId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.relatedTransactionId, relatedTransactionId) ||
                other.relatedTransactionId == relatedTransactionId) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    payerId,
    receiverId,
    amount,
    relatedTransactionId,
    groupId,
    status,
    method,
    note,
    createdAt,
    confirmedAt,
  );

  /// Create a copy of PaymentRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentRequestImplCopyWith<_$PaymentRequestImpl> get copyWith =>
      __$$PaymentRequestImplCopyWithImpl<_$PaymentRequestImpl>(
        this,
        _$identity,
      );
}

abstract class _PaymentRequest extends PaymentRequest {
  const factory _PaymentRequest({
    required final String id,
    required final String payerId,
    required final String receiverId,
    required final double amount,
    final String? relatedTransactionId,
    final String? groupId,
    required final String status,
    final String? method,
    final String? note,
    required final DateTime createdAt,
    final DateTime? confirmedAt,
  }) = _$PaymentRequestImpl;
  const _PaymentRequest._() : super._();

  @override
  String get id;
  @override
  String get payerId;
  @override
  String get receiverId;
  @override
  double get amount;
  @override
  String? get relatedTransactionId;
  @override
  String? get groupId;
  @override
  String get status;
  @override
  String? get method;
  @override
  String? get note;
  @override
  DateTime get createdAt;
  @override
  DateTime? get confirmedAt;

  /// Create a copy of PaymentRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentRequestImplCopyWith<_$PaymentRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
