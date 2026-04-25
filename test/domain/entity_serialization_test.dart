import 'package:flutter_test/flutter_test.dart';
import 'package:eda/src/domain/entities/group.dart';
import 'package:eda/src/domain/entities/group_member.dart';
import 'package:eda/src/domain/entities/net_balance.dart';
import 'package:eda/src/domain/entities/notification.dart';
import 'package:eda/src/domain/entities/payment_request.dart';
import 'package:eda/src/domain/entities/settlement_request.dart';
import 'package:eda/src/domain/entities/transaction.dart';
import 'package:eda/src/domain/entities/transaction_participant.dart';
import '../helpers/fixtures.dart';

void main() {
  // ─── Transaction ──────────────────────────────────────────────────────────

  group('Transaction.fromJson', () {
    test('parses all fields', () {
      final t = Transaction.fromJson(txJson());
      expect(t.id, 'tx-1');
      expect(t.groupId, isNull);
      expect(t.description, 'Dinner');
      expect(t.creatorId, kUserA);
      expect(t.payerId, kUserA);
      expect(t.totalAmount, 300.0);
      expect(t.currency, 'ETB');
      expect(t.status, 'pending');
      expect(t.createdAt, kCreatedAt);
    });

    test('defaults currency to ETB when null', () {
      final t = Transaction.fromJson({...txJson(), 'currency': null});
      expect(t.currency, 'ETB');
    });

    test('defaults status to pending when absent', () {
      final json = Map<String, dynamic>.from(txJson())..remove('status');
      final t = Transaction.fromJson(json);
      expect(t.status, 'pending');
    });

    test('parses numeric total_amount from int', () {
      final t = Transaction.fromJson({...txJson(), 'total_amount': 300});
      expect(t.totalAmount, 300.0);
      expect(t.totalAmount, isA<double>());
    });

    test('round-trip toJson preserves all values', () {
      final original = Transaction.fromJson(txJson());
      final json = original.toJson();
      expect(json['id'], original.id);
      expect(json['total_amount'], original.totalAmount);
      expect(json['status'], original.status);
      expect(json['creator_id'], original.creatorId);
    });
  });

  // ─── TransactionParticipant ───────────────────────────────────────────────

  group('TransactionParticipant.fromJson', () {
    test('parses all fields', () {
      final p = TransactionParticipant.fromJson(participantJson());
      expect(p.id, 'part-1');
      expect(p.transactionId, 'tx-1');
      expect(p.userId, kUserB);
      expect(p.amountDue, 100.0);
      expect(p.approved, isNull);
    });

    test('parses approved=true', () {
      final p = TransactionParticipant.fromJson(
          participantJson(approved: true));
      expect(p.approved, isTrue);
    });

    test('parses numeric amount_due from int', () {
      final p = TransactionParticipant.fromJson(
          {...participantJson(), 'amount_due': 50});
      expect(p.amountDue, 50.0);
    });

    test('round-trip toJson preserves all values', () {
      final p = TransactionParticipant.fromJson(participantJson());
      final json = p.toJson();
      expect(json['id'], p.id);
      expect(json['transaction_id'], p.transactionId);
      expect(json['user_id'], p.userId);
      expect(json['amount_due'], p.amountDue);
    });
  });

  // ─── Group ────────────────────────────────────────────────────────────────

  group('Group.fromJson', () {
    test('parses all fields', () {
      final g = Group.fromJson(groupJson());
      expect(g.id, 'group-1');
      expect(g.name, 'Housemates');
      expect(g.description, isNull);
      expect(g.creatorId, kUserA);
      expect(g.joinMode, 'invite');
    });

    test('defaults joinMode to invite when absent', () {
      final json = Map<String, dynamic>.from(groupJson())..remove('join_mode');
      final g = Group.fromJson(json);
      expect(g.joinMode, 'invite');
    });

    test('round-trip toJson', () {
      final g = Group.fromJson(groupJson());
      final json = g.toJson();
      expect(json['id'], g.id);
      expect(json['name'], g.name);
      expect(json['creator_id'], g.creatorId);
    });
  });

  // ─── NetBalance ───────────────────────────────────────────────────────────

  group('NetBalance.fromJson', () {
    test('parses all fields', () {
      final b = NetBalance.fromJson(balanceJson());
      expect(b.id, 'bal-1');
      expect(b.userA, kUserA);
      expect(b.userB, kUserB);
      expect(b.netAmount, 100.0);
      expect(b.lastUpdated, kCreatedAt);
    });

    test('parses negative netAmount', () {
      final b = NetBalance.fromJson(balanceJson(netAmount: -50.0));
      expect(b.netAmount, -50.0);
    });

    test('parses numeric net_amount from int', () {
      final b = NetBalance.fromJson({...balanceJson(), 'net_amount': 200});
      expect(b.netAmount, 200.0);
      expect(b.netAmount, isA<double>());
    });

    test('round-trip toJson', () {
      final b = NetBalance.fromJson(balanceJson());
      final json = b.toJson();
      expect(json['user_a'], b.userA);
      expect(json['user_b'], b.userB);
      expect(json['net_amount'], b.netAmount);
    });
  });

  // ─── PaymentRequest ───────────────────────────────────────────────────────

  group('PaymentRequest.fromJson', () {
    test('parses all fields', () {
      final p = PaymentRequest.fromJson(paymentRequestJson());
      expect(p.id, 'pay-1');
      expect(p.payerId, kUserA);
      expect(p.receiverId, kUserB);
      expect(p.amount, 100.0);
      expect(p.status, 'pending');
      expect(p.method, 'direct');
      expect(p.note, isNull);
    });

    test('defaults status to pending when absent', () {
      final json = Map<String, dynamic>.from(paymentRequestJson())
        ..remove('status');
      final p = PaymentRequest.fromJson(json);
      expect(p.status, 'pending');
    });

    test('parses confirmed status', () {
      final p = PaymentRequest.fromJson(
          paymentRequestJson(status: 'confirmed'));
      expect(p.status, 'confirmed');
    });

    test('round-trip toJson', () {
      final p = PaymentRequest.fromJson(paymentRequestJson());
      final json = p.toJson();
      expect(json['payer_id'], p.payerId);
      expect(json['receiver_id'], p.receiverId);
      expect(json['amount'], p.amount);
    });
  });

  // ─── AppNotification ──────────────────────────────────────────────────────

  group('AppNotification.fromJson', () {
    test('parses all fields', () {
      final n = AppNotification.fromJson(notificationJson());
      expect(n.id, 'notif-1');
      expect(n.userId, kUserA);
      expect(n.type, 'transaction_approved');
      expect(n.read, isFalse);
      expect(n.payload, {'transaction_id': 'tx-1'});
    });

    test('defaults read to false when absent', () {
      final json = Map<String, dynamic>.from(notificationJson())
        ..remove('read');
      final n = AppNotification.fromJson(json);
      expect(n.read, isFalse);
    });

    test('parses read=true', () {
      final n = AppNotification.fromJson(notificationJson(read: true));
      expect(n.read, isTrue);
    });

    test('round-trip toJson', () {
      final n = AppNotification.fromJson(notificationJson());
      final json = n.toJson();
      expect(json['user_id'], n.userId);
      expect(json['type'], n.type);
      expect(json['read'], n.read);
    });
  });

  // ─── GroupMember ──────────────────────────────────────────────────────────

  group('GroupMember.fromJson', () {
    test('parses active member with all fields', () {
      final m = GroupMember.fromJson(groupMemberJson());
      expect(m.id, 'mem-1');
      expect(m.groupId, 'group-1');
      expect(m.userId, kUserB);
      expect(m.role, 'member');
      expect(m.status, 'active');
      expect(m.invitedBy, isNull);
      expect(m.joinedAt, isNull);
    });

    test('parses pending member with invitedBy', () {
      final m = GroupMember.fromJson(groupMemberJson(
        status: 'pending',
        invitedBy: kUserA,
      ));
      expect(m.status, 'pending');
      expect(m.invitedBy, kUserA);
    });

    test('defaults status to active when absent', () {
      final json = Map<String, dynamic>.from(groupMemberJson())
        ..remove('status');
      expect(GroupMember.fromJson(json).status, 'active');
    });

    test('defaults role to member when absent', () {
      final json = Map<String, dynamic>.from(groupMemberJson())
        ..remove('role');
      expect(GroupMember.fromJson(json).role, 'member');
    });

    test('parses joinedAt when present', () {
      final m = GroupMember.fromJson(groupMemberJson(
        joinedAt: kCreatedAt.toIso8601String(),
      ));
      expect(m.joinedAt, kCreatedAt);
    });

    test('round-trip toJson preserves status and invitedBy', () {
      final original = GroupMember.fromJson(groupMemberJson(
        status: 'pending',
        invitedBy: kUserA,
      ));
      final json = original.toJson();
      expect(json['status'], 'pending');
      expect(json['invited_by'], kUserA);
      expect(json['group_id'], original.groupId);
      expect(json['user_id'], original.userId);
    });

    test('toJson serialises null invitedBy as null', () {
      final json = makeGroupMember().toJson();
      expect(json.containsKey('invited_by'), isTrue);
      expect(json['invited_by'], isNull);
    });
  });

  // ─── SettlementRequest ────────────────────────────────────────────────────

  group('SettlementRequest.fromJson', () {
    test('parses all fields', () {
      final s = SettlementRequest.fromJson(settlementJson());
      expect(s.id, 'settle-1');
      expect(s.initiatorId, kUserA);
      expect(s.payerId, kUserA);
      expect(s.receiverId, kUserB);
      expect(s.amount, 100.0);
      expect(s.status, 'pending');
    });

    test('defaults status to pending when absent', () {
      final json = Map<String, dynamic>.from(settlementJson())
        ..remove('status');
      final s = SettlementRequest.fromJson(json);
      expect(s.status, 'pending');
    });

    test('round-trip toJson', () {
      final s = SettlementRequest.fromJson(settlementJson());
      final json = s.toJson();
      expect(json['initiator_id'], s.initiatorId);
      expect(json['payer_id'], s.payerId);
      expect(json['receiver_id'], s.receiverId);
      expect(json['amount'], s.amount);
    });
  });
}
