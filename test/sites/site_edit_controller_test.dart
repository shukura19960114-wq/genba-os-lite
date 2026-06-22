import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/sites/application/site_edit_controller.dart';
import 'package:genba_os_lite/features/sites/data/site_repository.dart';

import 'fakes.dart';

void main() {
  ProviderContainer makeContainer(FakeSiteRepository fake) {
    final container = ProviderContainer(
      overrides: [siteRepositoryProvider.overrideWithValue(fake)],
    );
    // autoDispose を生かしたまま保持するため購読を張る。
    container.listen(siteEditControllerProvider, (_, _) {},
        fireImmediately: true);
    addTearDown(container.dispose);
    return container;
  }

  group('SiteEditController', () {
    test('update 成功 → true を返し、state はエラーなし', () async {
      final fake = FakeSiteRepository();
      final container = makeContainer(fake);

      final ok = await container
          .read(siteEditControllerProvider.notifier)
          .submit(
            id: 'site-1',
            name: '更新後の現場',
            address: '東京都港区',
            status: 'completed',
          );

      expect(ok, isTrue);
      expect(fake.lastUpdated, isNotNull);
      expect(fake.lastUpdated!.name, '更新後の現場');
      expect(fake.lastUpdated!.status, 'completed');
      expect(container.read(siteEditControllerProvider).hasError, isFalse);
    });

    test('update 失敗 → false を返し、state はエラー', () async {
      final fake = FakeSiteRepository(failOnUpdate: true);
      final container = makeContainer(fake);

      final ok = await container
          .read(siteEditControllerProvider.notifier)
          .submit(
            id: 'site-1',
            name: 'NG',
            status: 'active',
          );

      expect(ok, isFalse);
      expect(container.read(siteEditControllerProvider).hasError, isTrue);
    });
  });
}
