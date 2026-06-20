import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/data/dashboard_repository.dart';
import '../../settlement/data/settlement_repository.dart';
import '../data/expense_repository.dart';

/// Expenses for one trip (by rid). Creating one also invalidates the derived views (settlement +
/// dashboard) so they reflect the new spend.
class ExpensesController
    extends FamilyAsyncNotifier<List<ExpenseItem>, String> {
  ExpenseRepository get _repo => ref.read(expenseRepositoryProvider);

  @override
  Future<List<ExpenseItem>> build(String tripRid) => _repo.list(tripRid);

  Future<void> create({
    required String title,
    required String category,
    required String expenseType,
    required String currency,
    required num amount,
    required String payerRid,
    required String splitType,
    required List<ParticipantInput> participants,
    required String spentAtIso,
  }) async {
    await _repo.create(
      arg,
      title: title,
      category: category,
      expenseType: expenseType,
      currency: currency,
      amount: amount,
      payerRid: payerRid,
      splitType: splitType,
      participants: participants,
      spentAtIso: spentAtIso,
    );
    ref.invalidateSelf();
    ref.invalidate(settlementProvider(arg));
    ref.invalidate(dashboardProvider(arg));
    await future;
  }
}

final expensesControllerProvider =
    AsyncNotifierProvider.family<ExpensesController, List<ExpenseItem>, String>(
  ExpensesController.new,
);
