import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/sites/application/site_create_controller.dart';
import 'package:genba_os_lite/features/sites/application/sites_providers.dart';
import 'package:genba_os_lite/features/sites/data/site_repository.dart';

import 'fakes.dart';

void main() {
  group('SiteCreateController', () {
    test('create 成功 → true を返し、一覧に反映される', () async {
      final fake = FakeSiteRepository();
      final container = ProviderContainer(
        overrides: [siteRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final ok = await container
          .read(siteCreateControllerProvider.notifier)
          .create(name: 'テスト現場', address: '住所A');

      expect(ok, isTrue);
      expect(fake.createCalled, isTrue);
      expect(fake.lastCreatedName, 'テスト現場');
      expect(container.read(siteCreateControllerProvider).hasError, isFalse);

      final sites = await container.read(sitesListProvider.future);
      expect(sites.any((s) => s.name == 'テスト現場'), isTrue);
    });

    test('create 失敗 → false を返し state はエラー', () async {
      final fake = FakeSiteRepository(failOnCreate: true);
      final container = ProviderContainer(
        overrides: [siteRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final ok = await container
          .read(siteCreateControllerProvider.notifier)
          .create(name: 'NG現場');

      expect(ok, isFalse);
      expect(container.read(siteCreateControllerProvider).hasError, isTrue);
    });
  });
}
