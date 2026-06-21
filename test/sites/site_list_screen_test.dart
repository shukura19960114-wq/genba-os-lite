import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/sites/data/site.dart';
import 'package:genba_os_lite/features/sites/data/site_repository.dart';
import 'package:genba_os_lite/features/sites/presentation/site_list_screen.dart';

import 'fakes.dart';

void main() {
  Widget wrap(SiteRepository repo) => ProviderScope(
        overrides: [siteRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: SiteListScreen()),
      );

  group('SiteListScreen', () {
    testWidgets('現場があれば名称・住所を一覧表示', (tester) async {
      final fake = FakeSiteRepository(initial: const [
        Site(id: '1', name: 'A現場', address: '東京都港区', status: 'active'),
        Site(id: '2', name: 'B現場', address: '大阪市北区', status: 'completed'),
      ]);
      await tester.pumpWidget(wrap(fake));
      await tester.pump(); // FutureProvider 解決
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('A現場'), findsOneWidget);
      expect(find.text('B現場'), findsOneWidget);
      expect(find.text('東京都港区'), findsOneWidget);
      expect(find.text('進行中'), findsOneWidget);
      expect(find.text('完了'), findsOneWidget);
    });

    testWidgets('現場が無ければ空メッセージを表示', (tester) async {
      await tester.pumpWidget(wrap(FakeSiteRepository()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('現場がまだありません'), findsOneWidget);
    });
  });
}
