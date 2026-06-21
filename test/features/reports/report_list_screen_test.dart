import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/reports/application/report_providers.dart';
import 'package:genba_os_lite/features/reports/data/report.dart';
import 'package:genba_os_lite/features/reports/presentation/report_list_screen.dart';

const _siteId = 's1';

Report _report(String id, DateTime date, String content) => Report(
      id: id,
      companyId: 'c',
      siteId: _siteId,
      reportDate: date,
      weather: 'sunny',
      workContent: content,
      createdAt: date,
      updatedAt: date,
    );

void main() {
  group('ReportListScreen', () {
    testWidgets('loading: スピナー表示', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          reportsBySiteProvider(_siteId)
              .overrideWith((ref) => Completer<List<Report>>().future),
        ],
        child: const MaterialApp(home: ReportListScreen(siteId: _siteId)),
      ));
      await tester.pump(); // settle しない（ロード中）
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('data(2件): 新しい順に ListTile・作業日・天候ラベル', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          reportsBySiteProvider(_siteId).overrideWith((ref) => [
                _report('1', DateTime(2026, 6, 21), '基礎配筋'),
                _report('2', DateTime(2026, 6, 20), '型枠'),
              ]),
        ],
        child: const MaterialApp(home: ReportListScreen(siteId: _siteId)),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('2026/06/21'), findsOneWidget);
      expect(find.text('2026/06/20'), findsOneWidget);
      expect(find.textContaining('晴れ'), findsWidgets);
    });

    testWidgets('empty: 「日報がまだありません」', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          reportsBySiteProvider(_siteId).overrideWith((ref) => <Report>[]),
        ],
        child: const MaterialApp(home: ReportListScreen(siteId: _siteId)),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('日報がまだありません'), findsOneWidget);
    });

    testWidgets('error: 「日報の取得に失敗しました」+ 再読み込み', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          reportsBySiteProvider(_siteId)
              .overrideWith((ref) => Future<List<Report>>.error(Exception('x'))),
        ],
        child: const MaterialApp(home: ReportListScreen(siteId: _siteId)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('日報の取得に失敗しました'), findsOneWidget);
      expect(find.text('再読み込み'), findsOneWidget);
    });
  });
}
