import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/auth/application/auth_controller.dart';
import 'package:genba_os_lite/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';

void main() {
  group('AuthController', () {
    test('signIn 成功 → state はデータ（エラーなし）', () async {
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@b.com', password: 'pass');

      final state = container.read(authControllerProvider);
      expect(state.hasError, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('signIn 失敗 → state はエラー、メッセージを日本語化', () async {
      final fake = FakeAuthRepository(
        failWith: const AuthException('Invalid login credentials'),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@b.com', password: 'wrong');

      final state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
      expect(authErrorMessage(state.error!), 'メールアドレスまたはパスワードが違います。');
    });

    test('signOut はリポジトリの signOut を呼ぶ', () async {
      final fake = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).signOut();

      expect(fake.signOutCalled, isTrue);
    });
  });
}
