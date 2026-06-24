import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/auth/data/profile.dart';
import 'package:genba_os_lite/features/org/application/member_controller.dart';
import 'package:genba_os_lite/features/org/application/members_providers.dart';
import 'package:genba_os_lite/features/org/data/member_repository.dart';

class FakeMemberRepository implements MemberRepository {
  FakeMemberRepository({this.failOnSetRole = false});

  final bool failOnSetRole;
  String? lastTargetId;
  String? lastRole;

  @override
  Future<List<Profile>> listMembers() async => const [];

  @override
  Future<void> setMemberRole({
    required String targetId,
    required String role,
  }) async {
    lastTargetId = targetId;
    lastRole = role;
    if (failOnSetRole) throw Exception('forbidden');
  }
}

ProviderContainer _container(FakeMemberRepository repo) {
  final container = ProviderContainer(overrides: [
    memberRepositoryProvider.overrideWithValue(repo),
    membersProvider.overrideWith((ref) async => const <Profile>[]),
  ]);
  container.listen(memberControllerProvider, (_, _) {}, fireImmediately: true);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('MemberController.changeRole', () {
    test('成功 → true・RPCに target/role を渡す', () async {
      final repo = FakeMemberRepository();
      final container = _container(repo);

      final ok = await container
          .read(memberControllerProvider.notifier)
          .changeRole(targetId: 'u2', role: 'admin');

      expect(ok, isTrue);
      expect(repo.lastTargetId, 'u2');
      expect(repo.lastRole, 'admin');
      expect(container.read(memberControllerProvider).hasError, isFalse);
    });

    test('権限なし等で失敗 → false・state はエラー', () async {
      final repo = FakeMemberRepository(failOnSetRole: true);
      final container = _container(repo);

      final ok = await container
          .read(memberControllerProvider.notifier)
          .changeRole(targetId: 'u2', role: 'admin');

      expect(ok, isFalse);
      expect(container.read(memberControllerProvider).hasError, isTrue);
    });
  });
}
