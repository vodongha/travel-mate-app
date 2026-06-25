import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_mate_app/src/core/api_client.dart';
import 'package:travel_mate_app/src/core/token_storage.dart';
import 'package:travel_mate_app/src/features/auth/application/auth_controller.dart';
import 'package:travel_mate_app/src/features/auth/data/auth_repository.dart';
import 'package:travel_mate_app/src/features/auth/domain/auth_user.dart';

/// In-memory TokenStorage (the real one wraps FlutterSecureStorage, which needs a platform).
class _FakeStorage extends TokenStorage {
  _FakeStorage() : super(const FlutterSecureStorage());
  final Map<String, String> _m = {};
  @override
  Future<String?> readAccess() async => _m['a'];
  @override
  Future<String?> readRefresh() async => _m['r'];
  @override
  Future<String?> readCachedUser() async => _m['u'];
  @override
  Future<void> cacheUser(String json) async => _m['u'] = json;
  @override
  Future<void> save({required String access, required String refresh}) async {
    _m['a'] = access;
    _m['r'] = refresh;
  }

  @override
  Future<void> clear() async => _m.clear();
}

class _FakeRepo extends AuthRepository {
  _FakeRepo(this._onMe) : super(Dio());
  final Future<AuthUser> Function() _onMe;
  @override
  Future<AuthUser> me() => _onMe();
}

AuthUser _user() => const AuthUser(
      rid: 'r1', email: 'a@x.com', name: 'Aki', timezone: 'Asia/Ho_Chi_Minh',
      defaultCurrency: 'VND', emailVerified: true, provider: 'LOCAL', hasPassword: true);

ProviderContainer _container(_FakeStorage storage, _FakeRepo repo) => ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );

void main() {
  test('no token → signed out', () async {
    final c = _container(_FakeStorage(), _FakeRepo(() async => _user()));
    expect(await c.read(authControllerProvider.future), isNull);
  });

  test('a transient /users/me failure keeps the session via the cached user', () async {
    final storage = _FakeStorage();
    await storage.save(access: 'tok', refresh: 'ref');
    await storage.cacheUser('{"rid":"r1","email":"a@x.com","name":"Aki",'
        '"timezone":"Asia/Ho_Chi_Minh","defaultCurrency":"VND",'
        '"emailVerified":true,"provider":"LOCAL","hasPassword":true}');
    final c = _container(storage,
        _FakeRepo(() async => throw ApiException('offline', isConnection: true)));

    final AuthUser? user = await c.read(authControllerProvider.future);
    expect(user, isNotNull);
    expect(user!.email, 'a@x.com');
    expect(await storage.readAccess(), 'tok'); // tokens NOT cleared
  });

  test('a 401 clears the session', () async {
    final storage = _FakeStorage();
    await storage.save(access: 'tok', refresh: 'ref');
    await storage.cacheUser('{"email":"a@x.com","name":"Aki"}');
    final c = _container(storage,
        _FakeRepo(() async => throw ApiException('unauth', statusCode: 401)));

    expect(await c.read(authControllerProvider.future), isNull);
    expect(await storage.readAccess(), isNull); // tokens cleared
  });
}
