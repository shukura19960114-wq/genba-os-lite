import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/current_profile_provider.dart';
import '../data/member_repository.dart';
import 'members_providers.dart';

/// メンバーのロール変更を実行し、進行状態を保持する。
final memberControllerProvider =
    AsyncNotifierProvider.autoDispose<MemberController, void>(
  MemberController.new,
);

class MemberController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// 対象メンバーのロールを member⇄admin に変更する。成功で true。
  Future<bool> changeRole({
    required String targetId,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(memberRepositoryProvider)
          .setMemberRole(targetId: targetId, role: role);
    });
    state = result;
    if (result.hasError) return false;
    ref.invalidate(membersProvider);
    // 自分のロールは変えられない仕様だが、念のため最新化。
    ref.invalidate(currentProfileProvider);
    return true;
  }
}
