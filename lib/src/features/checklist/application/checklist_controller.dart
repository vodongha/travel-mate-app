import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/checklist_repository.dart';

/// Checklist items for one trip (by rid). Mutations reload the list.
class ChecklistController extends AsyncNotifier<List<ChecklistItem>> {
  ChecklistController(this._tripRid);
  final String _tripRid;

  ChecklistRepository get _repo => ref.read(checklistRepositoryProvider);

  @override
  Future<List<ChecklistItem>> build() => _repo.list(_tripRid);

  Future<void> add(String title) async {
    await _repo.create(_tripRid, title);
    ref.invalidateSelf();
    await future;
  }

  Future<void> toggle(String itemRid, bool completed) async {
    await _repo.setCompleted(_tripRid, itemRid, completed);
    ref.invalidateSelf();
    await future;
  }

  Future<void> rename(String itemRid, String title) async {
    await _repo.rename(_tripRid, itemRid, title);
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String itemRid) async {
    await _repo.delete(_tripRid, itemRid);
    ref.invalidateSelf();
    await future;
  }
}

final checklistControllerProvider = AsyncNotifierProvider.family<
    ChecklistController, List<ChecklistItem>, String>(
  ChecklistController.new,
);
