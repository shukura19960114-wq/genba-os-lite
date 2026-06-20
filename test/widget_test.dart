// Phase 1.0（基盤）のテスト。
// 既定の counter テストは廃止。Supabase 初期化やプラグインに依存しない
// 純粋なユニット/ウィジェットのみを対象にし、CI（接続なし）で常に緑になるようにする。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/core/config/app_env.dart';
import 'package:genba_os_lite/core/supabase/supabase_health_check.dart';
import 'package:genba_os_lite/features/foundation/presentation/widgets/connection_status_card.dart';

void main() {
  group('AppEnv', () {
    test('envFileName が環境ごとに正しい', () {
      expect(AppEnv.dev.envFileName, '.env.dev');
      expect(AppEnv.prod.envFileName, '.env.prod');
    });

    test('label / isDev / isProd', () {
      expect(AppEnv.dev.label, 'dev');
      expect(AppEnv.prod.label, 'prod');
      expect(AppEnv.dev.isDev, isTrue);
      expect(AppEnv.dev.isProd, isFalse);
      expect(AppEnv.prod.isProd, isTrue);
    });

    test('enum name は Flavor 名（dev/prod）と一致する', () {
      expect(AppEnv.dev.name, 'dev');
      expect(AppEnv.prod.name, 'prod');
    });
  });

  group('ConnectionStatusCard', () {
    Widget wrap(AsyncValue<ConnectionStatus> status) => MaterialApp(
          home: Scaffold(body: ConnectionStatusCard(statusAsync: status)),
        );

    testWidgets('OK のとき「Supabase接続：OK」を表示', (tester) async {
      await tester.pumpWidget(wrap(const AsyncData(ConnectionStatus.ok())));
      expect(find.text('Supabase接続：OK'), findsOneWidget);
    });

    testWidgets('NG のとき「Supabase接続：NG」とエラー内容を表示', (tester) async {
      await tester.pumpWidget(
        wrap(const AsyncData(ConnectionStatus.ng('テスト用エラー'))),
      );
      expect(find.text('Supabase接続：NG'), findsOneWidget);
      expect(find.text('テスト用エラー'), findsOneWidget);
    });

    testWidgets('loading のとき「確認中…」を表示', (tester) async {
      await tester.pumpWidget(
        wrap(const AsyncLoading<ConnectionStatus>()),
      );
      expect(find.textContaining('確認中'), findsOneWidget);
    });
  });
}
