import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/site.dart';
import '../data/site_repository.dart';

/// 自社の現場一覧。`ref.invalidate(sitesListProvider)` で再取得。
final sitesListProvider = FutureProvider<List<Site>>(
  (ref) => ref.watch(siteRepositoryProvider).fetchSites(),
);

/// 現場の詳細（id 指定）。
final siteDetailProvider = FutureProvider.family<Site?, String>(
  (ref, id) => ref.watch(siteRepositoryProvider).fetchSite(id),
);
