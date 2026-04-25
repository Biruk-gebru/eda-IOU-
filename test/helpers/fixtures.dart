import 'package:eda/src/domain/entities/group.dart';
import 'package:eda/src/domain/entities/group_member.dart';
import 'package:eda/src/domain/entities/net_balance.dart';
import 'package:eda/src/domain/entities/notification.dart';
import 'package:eda/src/domain/entities/transaction.dart';
import 'package:eda/src/domain/entities/transaction_participant.dart';

// Fixed test user IDs — alphabetical order determines net_balance convention.
const kUserA = 'aaaaaaaa-0000-0000-0000-000000000001'; // "Alice"
const kUserB = 'bbbbbbbb-0000-0000-0000-000000000002'; // "Bob"
const kUserC = 'cccccccc-0000-0000-0000-000000000003'; // "Carol"

final kCreatedAt = DateTime.utc(2024, 1, 1, 12);
final kTimeoutAt = kCreatedAt.add(const Duration(hours: 48));

// ---------- Transaction ----------

Map<String, dynamic> txJson({
  String id = 'tx-1',
  String? groupId,
  String description = 'Dinner',
  String creatorId = kUserA,
  String payerId = kUserA,
  double totalAmount = 300.0,
  String currency = 'ETB',
  String status = 'pending',
}) =>
    {
      'id': id,
      'group_id': groupId,
      'description': description,
      'creator_id': creatorId,
      'payer_id': payerId,
      'total_amount': totalAmount,
      'currency': currency,
      'metadata': null,
      'created_at': kCreatedAt.toIso8601String(),
      'updated_at': null,
      'timeout_at': kTimeoutAt.toIso8601String(),
      'status': status,
    };

Transaction makeTransaction({
  String id = 'tx-1',
  String? groupId,
  String description = 'Dinner',
  String creatorId = kUserA,
  String payerId = kUserA,
  double totalAmount = 300.0,
  String status = 'pending',
}) =>
    Transaction(
      id: id,
      groupId: groupId,
      description: description,
      creatorId: creatorId,
      payerId: payerId,
      totalAmount: totalAmount,
      createdAt: kCreatedAt,
      timeoutAt: kTimeoutAt,
      status: status,
    );

// ---------- TransactionParticipant ----------

Map<String, dynamic> participantJson({
  String id = 'part-1',
  String transactionId = 'tx-1',
  String userId = kUserB,
  double amountDue = 100.0,
  bool? approved,
}) =>
    {
      'id': id,
      'transaction_id': transactionId,
      'user_id': userId,
      'amount_due': amountDue,
      'approved': approved,
      'approved_at': null,
      'created_at': kCreatedAt.toIso8601String(),
    };

TransactionParticipant makeParticipant({
  String id = 'part-1',
  String transactionId = 'tx-1',
  String userId = kUserB,
  double amountDue = 100.0,
  bool? approved,
}) =>
    TransactionParticipant(
      id: id,
      transactionId: transactionId,
      userId: userId,
      amountDue: amountDue,
      approved: approved,
      createdAt: kCreatedAt,
    );

// ---------- Group ----------

Map<String, dynamic> groupJson({
  String id = 'group-1',
  String name = 'Housemates',
  String creatorId = kUserA,
  String joinMode = 'invite',
}) =>
    {
      'id': id,
      'name': name,
      'description': null,
      'creator_id': creatorId,
      'join_mode': joinMode,
      'created_at': kCreatedAt.toIso8601String(),
      'updated_at': null,
    };

Group makeGroup({
  String id = 'group-1',
  String name = 'Housemates',
  String creatorId = kUserA,
}) =>
    Group(
      id: id,
      name: name,
      creatorId: creatorId,
      createdAt: kCreatedAt,
    );

// ---------- GroupMember ----------

Map<String, dynamic> groupMemberJson({
  String id = 'mem-1',
  String groupId = 'group-1',
  String userId = kUserB,
  String role = 'member',
  String status = 'active',
  String? invitedBy,
  String? joinedAt,
}) =>
    {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'status': status,
      'invited_by': invitedBy,
      'joined_at': joinedAt,
    };

GroupMember makeGroupMember({
  String id = 'mem-1',
  String groupId = 'group-1',
  String userId = kUserB,
  String role = 'member',
  String status = 'active',
  String? invitedBy,
}) =>
    GroupMember(
      id: id,
      groupId: groupId,
      userId: userId,
      role: role,
      status: status,
      invitedBy: invitedBy,
    );

// ---------- NetBalance ----------

// Convention: positive netAmount means userA owes userB.
Map<String, dynamic> balanceJson({
  String id = 'bal-1',
  String userA = kUserA,
  String userB = kUserB,
  double netAmount = 100.0,
}) =>
    {
      'id': id,
      'user_a': userA,
      'user_b': userB,
      'net_amount': netAmount,
      'last_updated': kCreatedAt.toIso8601String(),
    };

NetBalance makeBalance({
  String id = 'bal-1',
  String userA = kUserA,
  String userB = kUserB,
  double netAmount = 100.0,
}) =>
    NetBalance(
      id: id,
      userA: userA,
      userB: userB,
      netAmount: netAmount,
      lastUpdated: kCreatedAt,
    );

// ---------- PaymentRequest ----------

Map<String, dynamic> paymentRequestJson({
  String id = 'pay-1',
  String payerId = kUserA,
  String receiverId = kUserB,
  double amount = 100.0,
  String status = 'pending',
  String? note,
}) =>
    {
      'id': id,
      'payer_id': payerId,
      'receiver_id': receiverId,
      'amount': amount,
      'related_transaction_id': null,
      'group_id': null,
      'status': status,
      'method': 'direct',
      'note': note,
      'created_at': kCreatedAt.toIso8601String(),
      'confirmed_at': null,
      'timeout_at': null,
    };

// ---------- AppNotification ----------

Map<String, dynamic> notificationJson({
  String id = 'notif-1',
  String userId = kUserA,
  String type = 'transaction_approved',
  bool read = false,
}) =>
    {
      'id': id,
      'user_id': userId,
      'type': type,
      'payload': {'transaction_id': 'tx-1'},
      'read': read,
      'created_at': kCreatedAt.toIso8601String(),
    };

AppNotification makeNotification({
  String id = 'notif-1',
  String userId = kUserA,
  String type = 'transaction_approved',
  bool read = false,
}) =>
    AppNotification(
      id: id,
      userId: userId,
      type: type,
      payload: {'transaction_id': 'tx-1'},
      read: read,
      createdAt: kCreatedAt,
    );

// ---------- SettlementRequest ----------

Map<String, dynamic> settlementJson({
  String id = 'settle-1',
  String initiatorId = kUserA,
  String payerId = kUserA,
  String receiverId = kUserB,
  double amount = 100.0,
  String status = 'pending',
}) =>
    {
      'id': id,
      'initiator_id': initiatorId,
      'payer_id': payerId,
      'receiver_id': receiverId,
      'amount': amount,
      'status': status,
      'created_at': kCreatedAt.toIso8601String(),
      'updated_at': null,
    };
