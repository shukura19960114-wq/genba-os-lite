import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/site_member_repository.dart';

/// 現場の担当メンバー一覧（現場ごと）。割当/解除の成功で invalidate。
final siteMembersProvider =
    FutureProvider.family<List<AssignedMember>, String>(
  (ref, siteId) => ref.watch(siteMemberRepositoryProvider).listForSite(siteId),
);

/// 担当メンバーの割当/解除を実行し、進行状態を保持する。
final siteMemberControllerProvider =
    AsyncNotifierProvider.autoDispose<SiteMemberController, void>(
  SiteMemberController.new,
);

class SiteMemberController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// メンバーを現場に割り当てる。成功で true。
  Future<bool> assign({
    required String siteId,
    required String profileId,
  }) async {
    return _run(siteId,
        () => ref.read(siteMemberRepositoryProvider).assign(siteId: siteId, profileId: profileId));
  }

  /// 担当を解除する。成功で true。
  Future<bool> unassign({
    required String siteId,
    required String profileId,
  }) async {
    return _run(siteId,
        () => ref.read(siteMemberRepositoryProvider).unassign(siteId: siteId, profileId: profileId));
  }

  Future<bool> _run(String siteId, Future<void> Function() action) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(action);
    state = result;
    if (result.hasError) return false;
    ref.invalidate(siteMembersProvider(siteId));
    return true;
  }
}
