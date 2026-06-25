import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/post.dart';
import '../data/post_repository.dart';

/// 現場のメッセージ一覧（時系列）。投稿成功で invalidate。
final sitePostsProvider = FutureProvider.family<List<Post>, String>(
  (ref, siteId) => ref.watch(postRepositoryProvider).listBySite(siteId),
);

/// 現場ごとの未読件数 `{site_id: 件数}`。現場一覧で watch。既読化・投稿で invalidate。
final unreadCountsProvider = FutureProvider<Map<String, int>>(
  (ref) => ref.watch(postRepositoryProvider).unreadCounts(),
);
