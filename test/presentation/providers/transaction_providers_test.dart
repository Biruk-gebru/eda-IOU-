import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eda/src/data/repositories/transaction_repository.dart';
import 'package:eda/src/presentation/providers/transaction_providers.dart';
import '../../helpers/fixtures.dart';

class MockTransactionRepository extends Mock
    implements TransactionRepository {}

void main() {
  late MockTransactionRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockTransactionRepository();
    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  // ─── transactionListProvider ───────────────────────────────────────────────

  group('transactionListProvider', () {
    test('returns list from repository', () async {
      final txList = [makeTransaction(), makeTransaction(id: 'tx-2')];
      when(() => mockRepo.watchTransactions())
          .thenAnswer((_) => Stream.value(txList));

      final result = await container.read(transactionListProvider.future);

      expect(result, txList);
      verify(() => mockRepo.watchTransactions()).called(1);
    });

    test('returns empty list when repository returns empty', () async {
      when(() => mockRepo.watchTransactions())
          .thenAnswer((_) => Stream.value([]));

      final result = await container.read(transactionListProvider.future);

      expect(result, isEmpty);
    });

    test('propagates repository exceptions', () async {
      when(() => mockRepo.watchTransactions())
          .thenAnswer((_) => Stream.error(Exception('network error')));

      expect(
        container.read(transactionListProvider.future),
        throwsException,
      );
    });
  });

  // ─── transactionDetailProvider ────────────────────────────────────────────

  group('transactionDetailProvider', () {
    test('returns correct transaction for given id', () async {
      const txId = 'tx-1';
      final tx = makeTransaction(id: txId, description: 'Dinner');
      when(() => mockRepo.getTransaction(txId)).thenAnswer((_) async => tx);

      final result =
          await container.read(transactionDetailProvider(txId).future);

      expect(result.id, txId);
      expect(result.description, 'Dinner');
      verify(() => mockRepo.getTransaction(txId)).called(1);
    });

    test('different ids call repository separately', () async {
      final tx1 = makeTransaction(id: 'tx-1');
      final tx2 = makeTransaction(id: 'tx-2');
      when(() => mockRepo.getTransaction('tx-1')).thenAnswer((_) async => tx1);
      when(() => mockRepo.getTransaction('tx-2')).thenAnswer((_) async => tx2);

      final r1 = await container.read(transactionDetailProvider('tx-1').future);
      final r2 = await container.read(transactionDetailProvider('tx-2').future);

      expect(r1.id, 'tx-1');
      expect(r2.id, 'tx-2');
    });
  });

  // ─── transactionParticipantsProvider ──────────────────────────────────────

  group('transactionParticipantsProvider', () {
    test('returns participants for given transactionId', () async {
      const txId = 'tx-1';
      final parts = [
        makeParticipant(id: 'part-1', transactionId: txId, userId: kUserB),
        makeParticipant(id: 'part-2', transactionId: txId, userId: kUserC),
      ];
      when(() => mockRepo.getParticipants(txId))
          .thenAnswer((_) async => parts);

      final result =
          await container.read(transactionParticipantsProvider(txId).future);

      expect(result.length, 2);
      expect(result[0].userId, kUserB);
      expect(result[1].userId, kUserC);
    });

    test('returns empty list when no participants', () async {
      when(() => mockRepo.getParticipants(any()))
          .thenAnswer((_) async => []);

      final result = await container
          .read(transactionParticipantsProvider('tx-none').future);

      expect(result, isEmpty);
    });
  });

  // ─── multi-user scenario ──────────────────────────────────────────────────

  group('multi-user transaction scenario', () {
    // Simulate: Alice creates a 300 ETB dinner transaction.
    // Bob and Carol are participants, each owing 100 ETB.
    test('creator sees own transaction in list', () async {
      final aliceTx = makeTransaction(
        id: 'tx-dinner',
        creatorId: kUserA,
        payerId: kUserA,
        totalAmount: 300,
        description: 'Dinner',
      );
      when(() => mockRepo.watchTransactions())
          .thenAnswer((_) => Stream.value([aliceTx]));

      final result = await container.read(transactionListProvider.future);

      expect(result.length, 1);
      expect(result[0].creatorId, kUserA);
      expect(result[0].totalAmount, 300.0);
    });

    test('participants are correctly split 3 ways', () async {
      const txId = 'tx-dinner';
      final parts = [
        makeParticipant(
            id: 'p-b', transactionId: txId, userId: kUserB, amountDue: 100.0),
        makeParticipant(
            id: 'p-c', transactionId: txId, userId: kUserC, amountDue: 100.0),
      ];
      when(() => mockRepo.getParticipants(txId))
          .thenAnswer((_) async => parts);

      final result =
          await container.read(transactionParticipantsProvider(txId).future);

      final totalOwed =
          result.fold(0.0, (acc, p) => acc + p.amountDue);
      expect(totalOwed, 200.0); // Payer's own share (100) is implicit
      for (final p in result) {
        expect(p.amountDue, closeTo(100.0, 0.01));
      }
    });

    test('approved transaction shows correct participant states', () async {
      const txId = 'tx-dinner';
      final parts = [
        makeParticipant(
            id: 'p-b',
            transactionId: txId,
            userId: kUserB,
            amountDue: 100.0,
            approved: true),
        makeParticipant(
            id: 'p-c',
            transactionId: txId,
            userId: kUserC,
            amountDue: 100.0,
            approved: null), // not yet voted
      ];
      when(() => mockRepo.getParticipants(txId))
          .thenAnswer((_) async => parts);

      final result =
          await container.read(transactionParticipantsProvider(txId).future);

      final approvedCount = result.where((p) => p.approved == true).length;
      final pendingCount = result.where((p) => p.approved == null).length;
      expect(approvedCount, 1);
      expect(pendingCount, 1);
    });
  });
}
