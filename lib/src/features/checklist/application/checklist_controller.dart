import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/checklist_repository.dart';

/// Checklist items for one trip (by rid). Mutations reload the list.
class ChecklistController
    extends FamilyAsyncNotifier<List<ChecklistItem>, String> {
  ChecklistRepository get _repo => ref.read(checklistRepositoryProvider);

  @override
  Future<List<ChecklistItem>> build(String tripRid) => _repo.list(tripRid);

  Future<void> add(String title) async {
    await _repo.create(arg, title);
    ref.invalidateSelf();
    await future;
  }

  Future<void> toggle(String itemRid, bool completed) async {
    await _repo.setCompleted(arg, itemRid, completed);
    ref.invalidateSelf();
    await future;
  }
}

final checklistControllerProvider = AsyncNotifierProvider.family<
    ChecklistController, List<ChecklistItem>, String>(
  ChecklistController.new,
);
