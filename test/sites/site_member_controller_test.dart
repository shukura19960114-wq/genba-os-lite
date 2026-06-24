import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/sites/application/site_member_controller.dart';
import 'package:genba_os_lite/features/sites/data/site_member_repository.dart';

class FakeSiteMemberRepository implements SiteMemberRepository {
  FakeSiteMemberRepository({this.failWith});

  final Object? failWith;
  final List<(String, String)> assigned = [];
  final List<(String, String)> unassigned = [];

  @override
  Future<List<AssignedMember>> listForSite(String siteId) async => const [];

  @override
  Future<void> assign({required String siteId, required String profileId}) async {
    if (failWith != null) throw failWith!;
    assigned.add((siteId, profileId));
  }

  @override
  Future<void> unassign({
    required String siteId,
    required String profileId,
  }) async {
    if (failWith != null) throw failWith!;
    unassigned.add((siteId, profileId));
  }
}

ProviderContainer _container(FakeSiteMemberRepository repo) {
  final container = ProviderContainer(overrides: [
    siteMemberRepositoryProvider.overrideWithValue(repo),
  ]);
  container.listen(siteMemberControllerProvider, (_, _) {},
      fireImmediately: true);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('SiteMemberController', () {
    test('assign 成功 → true・リポジトリに渡す', () async {
      final repo = FakeSiteMemberRepository();
      final container = _container(repo);

      final ok = await container
          .read(siteMemberControllerProvider.notifier)
          .assign(siteId: 's1', profileId: 'u2');

      expect(ok, isTrue);
      expect(repo.assigned, [('s1', 'u2')]);
      expect(container.read(siteMemberControllerProvider).hasError, isFalse);
    });

    test('assign 失敗（権限なし等）→ false・state はエラー', () async {
      final repo = FakeSiteMemberRepository(failWith: Exception('forbidden'));
      final container = _container(repo);

      final ok = await container
          .read(siteMemberControllerProvider.notifier)
          .assign(siteId: 's1', profileId: 'u2');

      expect(ok, isFalse);
      expect(container.read(siteMemberControllerProvider).hasError, isTrue);
    });

    test('unassign 成功 → true・リポジトリに渡す', () async {
      final repo = FakeSiteMemberRepository();
      final container = _container(repo);

      final ok = await container
          .read(siteMemberControllerProvider.notifier)
          .unassign(siteId: 's1', profileId: 'u2');

      expect(ok, isTrue);
      expect(repo.unassigned, [('s1', 'u2')]);
    });
  });

  group('AssignedMember.fromJson', () {
    test('埋め込み profiles から email/role を読む', () {
      final m = AssignedMember.fromJson({
        'profile_id': 'u2',
        'assigned_at': '2026-06-25T00:00:00Z',
        'profiles': {'id': 'u2', 'email': 'a@b.com', 'role': 'admin'},
      });
      expect(m.profileId, 'u2');
      expect(m.email, 'a@b.com');
      expect(m.role, 'admin');
    });
  });
}
