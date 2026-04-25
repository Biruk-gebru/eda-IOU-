/// Pure, stateless split-calculation functions used by the transaction
/// creation flow and directly exercised by unit tests.
library;

/// Calculates how much each non-payer participant owes for an equal split.
///
/// [totalAmount]       – the full transaction amount.
/// [totalParticipants] – everyone included in the split (payer + others).
/// [otherUserIds]      – user IDs of non-payer participants, in order.
///
/// Returns a list of `{'user_id': ..., 'amount_due': ...}` maps ready to
/// insert into `transaction_participants`. Floating-point remainder is
/// assigned to the last participant so all shares sum exactly to
/// `totalAmount - payerShare`.
List<Map<String, dynamic>> equalSplit({
  required double totalAmount,
  required int totalParticipants,
  required List<String> otherUserIds,
}) {
  assert(totalParticipants >= 2, 'Need at least payer + 1 other');
  assert(otherUserIds.isNotEmpty, 'Need at least one non-payer participant');

  final perPerson = (totalAmount / totalParticipants * 100).round() / 100;
  final maps = <Map<String, dynamic>>[];
  double assigned = 0;

  for (int i = 0; i < otherUserIds.length; i++) {
    final isLast = i == otherUserIds.length - 1;
    final amount = isLast
        ? double.parse(
            (totalAmount - perPerson - assigned).toStringAsFixed(2))
        : perPerson;
    maps.add({'user_id': otherUserIds[i], 'amount_due': amount});
    assigned += perPerson;
  }
  return maps;
}

/// Validates a custom split and returns the participant rows.
///
/// Throws [ArgumentError] if any amount is ≤ 0 or the sum differs from
/// [totalAmount] by more than 0.01.
List<Map<String, dynamic>> customSplit({
  required double totalAmount,
  required Map<String, double> amountByUserId,
}) {
  double sum = 0;
  for (final entry in amountByUserId.entries) {
    if (entry.value <= 0) {
      throw ArgumentError('Amount for ${entry.key} must be > 0');
    }
    sum += entry.value;
  }
  if ((sum - totalAmount).abs() > 0.01) {
    throw ArgumentError(
      'Split amounts (${sum.toStringAsFixed(2)}) must equal '
      'total (${totalAmount.toStringAsFixed(2)})',
    );
  }
  return amountByUserId.entries
      .map((e) => {'user_id': e.key, 'amount_due': e.value})
      .toList();
}

/// Pure balance helpers — no dependency on SupabaseClient.
double totalOwedByUser(List<({String userA, String userB, double netAmount})> balances, String userId) {
  double total = 0;
  for (final b in balances) {
    if (b.userA == userId && b.netAmount > 0) total += b.netAmount;
    if (b.userB == userId && b.netAmount < 0) total += b.netAmount.abs();
  }
  return total;
}

double totalOwedToUser(List<({String userA, String userB, double netAmount})> balances, String userId) {
  double total = 0;
  for (final b in balances) {
    if (b.userA == userId && b.netAmount < 0) total += b.netAmount.abs();
    if (b.userB == userId && b.netAmount > 0) total += b.netAmount;
  }
  return total;
}
