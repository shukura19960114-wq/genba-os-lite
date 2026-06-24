import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/invite_repository.dart';
import 'members_providers.dart';

/// 招待コードの発行・失効を実行し、進行状態を保持する。
final inviteControllerProvider =
    AsyncNotifierProvider.autoDispose<InviteController, void>(
  InviteController.new,
);

class InviteController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// 招待コードを発行する（role: 'member' | 'admin'）。成功で true。
  Future<bool> create({
    required String companyId,
    required String role,
  }) async {
    return _run(() => ref
        .read(inviteRepositoryProvider)
        .createInvite(companyId: companyId, role: role));
  }

  /// 招待コードを失効する。成功で true。
  Future<bool> revoke(String id) async {
    return _run(() => ref.read(inviteRepositoryProvider).revokeInvite(id));
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(action);
    state = result;
    if (result.hasError) return false;
    ref.invalidate(invitesProvider);
    return true;
  }
}
