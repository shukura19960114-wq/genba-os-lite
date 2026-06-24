import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

/// サインイン/サインアウトの実行と、その進行状態（loading/error）を保持するコントローラ。
///
/// 画面はこの `state`（`AsyncValue<void>`）を watch して、ボタンのローディングや
/// エラー表示を行う。実際の遷移は go_router の認証ガードが認証状態の変化を見て行う。
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // 初期状態は「待機（データ無し）」。
  }

  /// Email + Password でサインイン。
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .signInWithPassword(email: email, password: password);
    });
  }

  /// Email + Password で新規登録。成功で true（state はエラーなし）。
  /// 成功後の遷移は go_router の認証ガードに任せる（会社未所属ならホームで参加画面）。
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password);
    });
    return !state.hasError;
  }

  /// サインアウト。
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
    });
  }
}

/// [AuthController] を提供する Provider。
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
