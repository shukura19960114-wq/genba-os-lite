import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/post_repository.dart';
import 'posts_providers.dart';

/// 現場連絡の投稿・既読化を実行し、進行状態を保持する。
final postControllerProvider =
    AsyncNotifierProvider.autoDispose<PostController, void>(
  PostController.new,
);

class PostController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// メッセージを投稿する。空文字は無視（false）。成功で true。
  Future<bool> send({required String siteId, required String body}) async {
    final text = body.trim();
    if (text.isEmpty) return false;
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      await ref.read(postRepositoryProvider).create(siteId: siteId, body: text);
    });
    state = result;
    if (result.hasError) return false;
    ref.invalidate(sitePostsProvider(siteId));
    ref.invalidate(unreadCountsProvider);
    return true;
  }

  /// 現場を既読にする（画面を開いた時）。失敗してもバッジ更新の副作用のみ。
  Future<void> markRead(String siteId) async {
    try {
      await ref.read(postRepositoryProvider).markRead(siteId);
      ref.invalidate(unreadCountsProvider);
    } catch (_) {
      // 既読化失敗は致命的でないため握りつぶす。
    }
  }
}
