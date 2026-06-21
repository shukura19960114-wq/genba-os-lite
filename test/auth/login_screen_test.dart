import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/core/config/app_config_provider.dart';
import 'package:genba_os_lite/features/auth/data/auth_repository.dart';
import 'package:genba_os_lite/features/auth/presentation/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';

void main() {
  Widget wrap(AuthRepository repo) => ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(testAppConfig),
          authRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: LoginScreen()),
      );

  group('LoginScreen', () {
    testWidgets('空入力で送信するとバリデーションエラーを表示', (tester) async {
      await tester.pumpWidget(wrap(FakeAuthRepository()));

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
      expect(find.text('パスワードを入力してください'), findsOneWidget);
    });

    testWidgets('ログイン失敗でエラーバナーを表示', (tester) async {
      final fake = FakeAuthRepository(
        failWith: const AuthException('Invalid login credentials'),
      );
      await tester.pumpWidget(wrap(fake));

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'wrongpass',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump(); // loading
      await tester.pump(const Duration(milliseconds: 50)); // error 反映

      expect(fake.signInCalled, isTrue);
      expect(find.text('メールアドレスまたはパスワードが違います。'), findsOneWidget);
    });
  });
}
