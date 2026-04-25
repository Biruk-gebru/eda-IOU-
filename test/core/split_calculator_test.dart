import 'package:flutter_test/flutter_test.dart';
import 'package:eda/src/core/utils/split_calculator.dart';

void main() {
  // ─── equalSplit ────────────────────────────────────────────────────────────

  group('equalSplit', () {
    test('2-person: payer + 1 other — other gets half', () {
      final result = equalSplit(
        totalAmount: 300,
        totalParticipants: 2,
        otherUserIds: ['user-b'],
      );
      expect(result.length, 1);
      expect(result[0]['user_id'], 'user-b');
      expect(result[0]['amount_due'], 150.0);
    });

    test('3-person 300 ETB — each participant owes 100', () {
      final result = equalSplit(
        totalAmount: 300,
        totalParticipants: 3,
        otherUserIds: ['user-b', 'user-c'],
      );
      expect(result[0]['amount_due'], 100.0);
      expect(result[1]['amount_due'], 100.0);
    });

    test('3-person 100 ETB — remainder assigned to last', () {
      // 100 / 3 = 33.33 per person (rounded to cents)
      // payer gets 33.33; B gets 33.33; C gets remainder = 100 - 33.33 - 33.33 = 33.34
      final result = equalSplit(
        totalAmount: 100,
        totalParticipants: 3,
        otherUserIds: ['user-b', 'user-c'],
      );
      expect(result[0]['amount_due'], 33.33);
      expect(result[1]['amount_due'], 33.34);
    });

    test('4-person 10 ETB — all non-payer shares sum to 7.50', () {
      final result = equalSplit(
        totalAmount: 10,
        totalParticipants: 4,
        otherUserIds: ['user-b', 'user-c', 'user-d'],
      );
      final sum =
          result.fold(0.0, (acc, m) => acc + (m['amount_due'] as double));
      expect(sum, closeTo(7.50, 0.001));
    });

    test('preserves user_id order', () {
      final result = equalSplit(
        totalAmount: 200,
        totalParticipants: 3,
        otherUserIds: ['alice', 'bob'],
      );
      expect(result[0]['user_id'], 'alice');
      expect(result[1]['user_id'], 'bob');
    });

    test('non-payer shares + payer share sum to totalAmount', () {
      const total = 100.0;
      const n = 3;
      final perPerson = (total / n * 100).round() / 100;
      final result = equalSplit(
        totalAmount: total,
        totalParticipants: n,
        otherUserIds: ['user-b', 'user-c'],
      );
      final othersSum =
          result.fold(0.0, (acc, m) => acc + (m['amount_due'] as double));
      expect(othersSum + perPerson, closeTo(total, 0.001));
    });

    test('large group with prime total distributes remainder to last', () {
      // 101 ETB split 5 ways: 20.20 each, last gets 20.20 (101 - 20.20 - 80.80 = 20.20)
      // Actually: 101/5 = 20.2 → perPerson = 20.20
      // B=20.20, C=20.20, D=20.20, E = 101 - 20.20 - 60.60 = 20.20
      final result = equalSplit(
        totalAmount: 101,
        totalParticipants: 5,
        otherUserIds: ['b', 'c', 'd', 'e'],
      );
      final sum =
          result.fold(0.0, (acc, m) => acc + (m['amount_due'] as double));
      expect(sum, closeTo(101 * 4 / 5, 0.01));
    });
  });

  // ─── customSplit ───────────────────────────────────────────────────────────

  group('customSplit', () {
    test('valid split returns correct participant maps', () {
      final result = customSplit(
        totalAmount: 100,
        amountByUserId: {'alice': 60, 'bob': 40},
      );
      expect(result.length, 2);
      final alice = result.firstWhere((m) => m['user_id'] == 'alice');
      expect(alice['amount_due'], 60.0);
      final bob = result.firstWhere((m) => m['user_id'] == 'bob');
      expect(bob['amount_due'], 40.0);
    });

    test('throws ArgumentError when an amount is zero', () {
      expect(
        () => customSplit(
          totalAmount: 100,
          amountByUserId: {'alice': 0, 'bob': 100},
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when an amount is negative', () {
      expect(
        () => customSplit(
          totalAmount: 100,
          amountByUserId: {'alice': -10, 'bob': 110},
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when sum exceeds total by more than 0.01', () {
      expect(
        () => customSplit(
          totalAmount: 100,
          amountByUserId: {'alice': 60, 'bob': 41},
        ),
        throwsArgumentError,
      );
    });

    test('accepts sum within 0.01 tolerance (floating-point rounding)', () {
      expect(
        () => customSplit(
          totalAmount: 100,
          amountByUserId: {'alice': 60, 'bob': 40.005},
        ),
        returnsNormally,
      );
    });

    test('exact match does not throw', () {
      expect(
        () => customSplit(
          totalAmount: 150,
          amountByUserId: {'alice': 75, 'bob': 75},
        ),
        returnsNormally,
      );
    });
  });

  // ─── totalOwedByUser ───────────────────────────────────────────────────────
  // Convention:
  //   netAmount > 0  →  userA owes userB
  //   netAmount < 0  →  userB owes userA

  // net_balances convention:
  //   netAmount > 0  →  userA owes userB
  //   netAmount < 0  →  userB owes userA
  group('totalOwedByUser', () {
    final balances = [
      // alice owes bob 100  (userA=alice, positive → A owes B)
      (userA: 'alice', userB: 'bob', netAmount: 100.0),
      // carol owes alice 50  (userB=carol, negative → B owes A)
      (userA: 'alice', userB: 'carol', netAmount: -50.0),
      // bob owes carol 200  (userA=bob, positive → A owes B)
      (userA: 'bob', userB: 'carol', netAmount: 200.0),
    ];

    test('alice owes 100 (to bob)', () {
      expect(totalOwedByUser(balances, 'alice'), 100.0);
    });

    test('bob owes 200 (to carol)', () {
      expect(totalOwedByUser(balances, 'bob'), 200.0);
    });

    test('carol owes 50 (to alice)', () {
      expect(totalOwedByUser(balances, 'carol'), 50.0);
    });

    test('unknown user owes nothing', () {
      expect(totalOwedByUser(balances, 'dave'), 0.0);
    });

    test('empty balances list returns zero', () {
      expect(totalOwedByUser([], 'alice'), 0.0);
    });
  });

  // ─── totalOwedToUser ──────────────────────────────────────────────────────

  group('totalOwedToUser', () {
    final balances = [
      // alice owes bob 100  → bob is owed 100
      (userA: 'alice', userB: 'bob', netAmount: 100.0),
      // carol owes alice 50  → alice is owed 50
      (userA: 'alice', userB: 'carol', netAmount: -50.0),
      // bob owes carol 200  → carol is owed 200
      (userA: 'bob', userB: 'carol', netAmount: 200.0),
    ];

    test('alice is owed 50 (by carol)', () {
      expect(totalOwedToUser(balances, 'alice'), 50.0);
    });

    test('carol is owed 200 (by bob)', () {
      expect(totalOwedToUser(balances, 'carol'), 200.0);
    });

    test('bob is owed 100 (by alice)', () {
      expect(totalOwedToUser(balances, 'bob'), 100.0);
    });

    test('unknown user is owed nothing', () {
      expect(totalOwedToUser(balances, 'dave'), 0.0);
    });

    test('empty balances list returns zero', () {
      expect(totalOwedToUser([], 'alice'), 0.0);
    });
  });

  // ─── multi-user scenario: 3-person dinner ─────────────────────────────────

  group('3-person dinner scenario', () {
    // Alice pays 300 ETB for dinner with Bob and Carol.
    // After equal split: Bob owes Alice 100, Carol owes Alice 100.
    // In net_balances convention (user_a < user_b alphabetically):
    //   alice < bob  → row (alice, bob, netAmount=-100)  [bob owes alice = B→A = negative]
    //   alice < carol → row (alice, carol, netAmount=-100)
    final balances = [
      (userA: 'alice', userB: 'bob', netAmount: -100.0),
      (userA: 'alice', userB: 'carol', netAmount: -100.0),
    ];

    test('alice is owed 200 total', () {
      expect(totalOwedToUser(balances, 'alice'), 200.0);
    });

    test('bob owes 100', () {
      expect(totalOwedByUser(balances, 'bob'), 100.0);
    });

    test('carol owes 100', () {
      expect(totalOwedByUser(balances, 'carol'), 100.0);
    });

    test('equalSplit produces correct shares for alice-pays scenario', () {
      final shares = equalSplit(
        totalAmount: 300,
        totalParticipants: 3,
        otherUserIds: ['bob', 'carol'],
      );
      expect(shares.length, 2);
      for (final s in shares) {
        expect(s['amount_due'], closeTo(100.0, 0.01));
      }
    });
  });
}
