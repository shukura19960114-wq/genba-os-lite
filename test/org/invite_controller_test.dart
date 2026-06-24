import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/org/application/invite_controller.dart';
import 'package:genba_os_lite/features/org/application/members_providers.dart';
import 'package:genba_os_lite/features/org/data/invite.dart';
import 'package:genba_os_lite/features/org/data/invite_repository.dart';

class FakeInviteRepository implements InviteRepository {
  FakeInviteRepository({this.failWith});

  final Object? failWith;
  String? lastCreateRole;
  String? lastRevokedId;
  int createCount = 0;

  @override
  Future<List<Invite>> listInvites() async => const [];

  @override
  Future<Invite> createInvite({
    required String companyId,
    required String role,
  }) async {
    createCount++;
    lastCreateRole = role;
    if (failWith != null) throw failWith!;
    return Invite(id: 'i1', companyId: companyId, code: 'ABCD2345', role: role);
  }

  @override
  Future<void> revokeInvite(String id) async {
    lastRevokedId = id;
    if (failWith != null) throw failWith!;
  }
}

ProviderContainer _container(FakeInviteRepository repo) {
  final container = ProviderContainer(overrides: [
    inviteRepositoryProvider.overrideWithValue(repo),
    invitesProvider.overrideWith((ref) async => const <Invite>[]),
  ]);
  container.listen(inviteControllerProvider, (_, _) {}, fireImmediately: true);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('InviteController', () {
    test('create 成功 → true・role を渡して発行', () async {
      final repo = FakeInviteRepository();
      final container = _container(repo);

      final ok = await container
          .read(inviteControllerProvider.notifier)
          .create(companyId: 'c1', role: 'admin');

      expect(ok, isTrue);
      expect(repo.createCount, 1);
      expect(repo.lastCreateRole, 'admin');
      expect(container.read(inviteControllerProvider).hasError, isFalse);
    });

    test('create 失敗 → false・state はエラー', () async {
      final repo = FakeInviteRepository(failWith: Exception('boom'));
      final container = _container(repo);

      final ok = await container
          .read(inviteControllerProvider.notifier)
          .create(companyId: 'c1', role: 'member');

      expect(ok, isFalse);
      expect(container.read(inviteControllerProvider).hasError, isTrue);
    });

    test('revoke 成功 → true・対象IDを渡す', () async {
      final repo = FakeInviteRepository();
      final container = _container(repo);

      final ok =
          await container.read(inviteControllerProvider.notifier).revoke('i9');

      expect(ok, isTrue);
      expect(repo.lastRevokedId, 'i9');
    });
  });

  group('Invite.isActive', () {
    test('失効済みは非アクティブ', () {
      const inv = Invite(id: 'i', companyId: 'c', code: 'X', revoked: true);
      expect(inv.isActive, isFalse);
    });
    test('期限なし・未失効はアクティブ', () {
      const inv = Invite(id: 'i', companyId: 'c', code: 'X');
      expect(inv.isActive, isTrue);
    });
  });
}
