import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/site_repository.dart';
import 'sites_providers.dart';

/// 現場の編集（名称・住所・ステータス）を実行し、進行状態を保持するコントローラ。
/// autoDispose: 編集画面を離れると状態をリセットする。
final siteEditControllerProvider =
    AsyncNotifierProvider.autoDispose<SiteEditController, void>(
  SiteEditController.new,
);

class SiteEditController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// 現場を更新する。成功したら true を返し、一覧と詳細を再取得させる。
  /// （メソッド名 `update` は AsyncNotifier の予約名のため `submit` とする）
  Future<bool> submit({
    required String id,
    required String name,
    String? address,
    required String status,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      await ref.read(siteRepositoryProvider).updateSite(
            id: id,
            name: name,
            address: address,
            status: status,
          );
    });
    state = result;
    if (result.hasError) return false;
    ref.invalidate(sitesListProvider);
    ref.invalidate(siteDetailProvider(id));
    return true;
  }
}
