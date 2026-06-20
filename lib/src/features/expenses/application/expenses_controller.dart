import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/data/dashboard_repository.dart';
import '../../report/data/report_repository.dart';
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
    _invalidateDerived();
    await future;
  }

  /// Edits an expense's metadata (title/category/type). Money + split are immutable
  /// on the backend, so they are not part of this call.
  Future<void> edit({
    required String expenseRid,
    required String title,
    required String category,
    required String expenseType,
  }) async {
    await _repo.update(
      arg,
      expenseRid,
      title: title,
      category: category,
      expenseType: expenseType,
    );
    _invalidateDerived();
    await future;
  }

  Future<void> remove(String expenseRid) async {
    await _repo.delete(arg, expenseRid);
    _invalidateDerived();
    await future;
  }

  /// Expenses feed the settlement, dashboard and report views, so refresh all of them.
  void _invalidateDerived() {
    ref.invalidateSelf();
    ref.invalidate(settlementProvider(arg));
    ref.invalidate(dashboardProvider(arg));
    ref.invalidate(reportProvider(arg));
  }
}

final expensesControllerProvider =
    AsyncNotifierProvider.family<ExpensesController, List<ExpenseItem>, String>(
  ExpensesController.new,
);
