import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/budget_repository.dart';

/// Budgets for one trip (by rid). Mutations reload the list.
class BudgetController extends FamilyAsyncNotifier<List<Budget>, String> {
  BudgetRepository get _repo => ref.read(budgetRepositoryProvider);

  @override
  Future<List<Budget>> build(String tripRid) => _repo.list(tripRid);

  Future<void> add(String category, num plannedAmount) async {
    await _repo.create(arg, category, plannedAmount);
    ref.invalidateSelf();
    await future;
  }

  Future<void> edit(String budgetRid, num plannedAmount) async {
    await _repo.update(arg, budgetRid, plannedAmount);
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String budgetRid) async {
    await _repo.delete(arg, budgetRid);
    ref.invalidateSelf();
    await future;
  }
}

final budgetControllerProvider =
    AsyncNotifierProvider.family<BudgetController, List<Budget>, String>(
  BudgetController.new,
);
