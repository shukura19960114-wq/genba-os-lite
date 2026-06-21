import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/site_repository.dart';
import 'sites_providers.dart';

/// 現場の新規作成を実行し、その進行状態（loading/error）を保持するコントローラ。
class SiteCreateController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// 現場を作成する。成功したら true を返し、一覧を再取得させる。
  Future<bool> create({required String name, String? address}) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(siteRepositoryProvider)
          .createSite(name: name, address: address);
    });
    state = result;
    if (result.hasError) return false;
    ref.invalidate(sitesListProvider);
    return true;
  }
}

final siteCreateControllerProvider =
    AsyncNotifierProvider<SiteCreateController, void>(SiteCreateController.new);
