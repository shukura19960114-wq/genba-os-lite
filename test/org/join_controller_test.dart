import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/org/application/join_controller.dart';
import 'package:genba_os_lite/features/org/data/org_repository.dart';

/// テスト用 [OrgRepository] フェイク。
class FakeOrgRepository implements OrgRepository {
  FakeOrgRepository({this.failWith});

  final Object? failWith;
  String? lastCode;
  String? lastCompanyName;

  @override
  Future<void> redeemInvite(String code) async {
    lastCode = code;
    if (failWith != null) throw failWith!;
  }

  @override
  Future<void> createCompany(String name) async {
    lastCompanyName = name;
    if (failWith != null) throw failWith!;
  }
}

ProviderContainer _container(FakeOrgRepository repo) {
  final container = ProviderContainer(
    overrides: [orgRepositoryProvider.overrideWithValue(repo)],
  );
  container.listen(joinControllerProvider, (_, _) {}, fireImmediately: true);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('JoinController.joinWithCode', () {
    test('成功 → true・リポジトリにコードを渡す・state エラーなし', () async {
      final repo = FakeOrgRepository();
      final container = _container(repo);

      final ok = await container
          .read(joinControllerProvider.notifier)
          .joinWithCode('ABC123');

      expect(ok, isTrue);
      expect(repo.lastCode, 'ABC123');
      expect(container.read(joinControllerProvider).hasError, isFalse);
    });

    test('無効コード → false・state はエラー', () async {
      final repo = FakeOrgRepository(failWith: Exception('invalid_code'));
      final container = _container(repo);

      final ok = await container
          .read(joinControllerProvider.notifier)
          .joinWithCode('BAD');

      expect(ok, isFalse);
      expect(container.read(joinControllerProvider).hasError, isTrue);
    });
  });

  group('JoinController.createCompany', () {
    test('成功 → true・会社名を渡す', () async {
      final repo = FakeOrgRepository();
      final container = _container(repo);

      final ok = await container
          .read(joinControllerProvider.notifier)
          .createCompany('デモ建設');

      expect(ok, isTrue);
      expect(repo.lastCompanyName, 'デモ建設');
      expect(container.read(joinControllerProvider).hasError, isFalse);
    });

    test('失敗 → false・state はエラー', () async {
      final repo = FakeOrgRepository(failWith: Exception('empty_name'));
      final container = _container(repo);

      final ok = await container
          .read(joinControllerProvider.notifier)
          .createCompany('');

      expect(ok, isFalse);
      expect(container.read(joinControllerProvider).hasError, isTrue);
    });
  });

  group('orgErrorMessage', () {
    test('invalid_code を日本語化', () {
      expect(orgErrorMessage(Exception('invalid_code')), contains('招待コード'));
    });
    test('already_in_company を日本語化', () {
      expect(orgErrorMessage(Exception('already_in_company')), contains('所属'));
    });
  });
}
