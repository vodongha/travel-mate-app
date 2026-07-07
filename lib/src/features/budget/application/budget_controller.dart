import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/budget_repository.dart';

/// Budgets for one trip (by rid). Mutations reload the list.
class BudgetController extends AsyncNotifier<List<Budget>> {
  BudgetController(this._tripRid);
  final String _tripRid;

  BudgetRepository get _repo => ref.read(budgetRepositoryProvider);

  @override
  Future<List<Budget>> build() => _repo.list(_tripRid);

  Future<void> add(String category, num plannedAmount) async {
    await _repo.create(_tripRid, category, plannedAmount);
    ref.invalidateSelf();
    await future;
  }

  Future<void> edit(String budgetRid, num plannedAmount) async {
    await _repo.update(_tripRid, budgetRid, plannedAmount);
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String budgetRid) async {
    await _repo.delete(_tripRid, budgetRid);
    ref.invalidateSelf();
    await future;
  }
}

final budgetControllerProvider =
    AsyncNotifierProvider.family<BudgetController, List<Budget>, String>(
  BudgetController.new,
);
