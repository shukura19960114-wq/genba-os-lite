import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/application/current_profile_provider.dart';
import '../data/org_repository.dart';

/// 会社への参加（招待コード）／会社の新規作成を実行し、進行状態を保持する。
/// autoDispose: 参加画面を離れると状態をリセットする。
final joinControllerProvider =
    AsyncNotifierProvider.autoDispose<JoinController, void>(
  JoinController.new,
);

class JoinController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// 招待コードで会社に参加する。成功で true。
  Future<bool> joinWithCode(String code) async {
    return _run(() => ref.read(orgRepositoryProvider).redeemInvite(code));
  }

  /// 会社を新規作成して owner になる。成功で true。
  Future<bool> createCompany(String name) async {
    return _run(() => ref.read(orgRepositoryProvider).createCompany(name));
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(action);
    state = result;
    if (result.hasError) return false;
    // プロフィール（会社・ロール）が変わったので関連を再取得。
    ref.invalidate(currentProfileProvider);
    ref.invalidate(homeProfileProvider);
    return true;
  }
}
