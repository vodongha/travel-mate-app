import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/member_repository.dart';
import '../domain/member.dart';

/// The members of one trip (keyed by trip rid). Mutations reload the list from the server.
class MembersController extends FamilyAsyncNotifier<List<Member>, String> {
  MemberRepository get _repo => ref.read(memberRepositoryProvider);

  @override
  Future<List<Member>> build(String tripRid) => _repo.list(tripRid);

  Future<void> addGhost(String displayName, String role) async {
    await _repo.addGhost(arg, displayName, role);
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String memberRid) async {
    await _repo.remove(arg, memberRid);
    ref.invalidateSelf();
    await future;
  }

  Future<void> changeRole(String memberRid, String role) async {
    await _repo.updateRole(arg, memberRid, role);
    ref.invalidateSelf();
    await future;
  }
}

final membersControllerProvider =
    AsyncNotifierProvider.family<MembersController, List<Member>, String>(
  MembersController.new,
);
