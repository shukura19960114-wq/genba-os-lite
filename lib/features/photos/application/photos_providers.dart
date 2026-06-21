import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/photo.dart';
import '../data/photo_repository.dart';

/// 指定現場の写真一覧。`ref.invalidate(photosProvider(siteId))` で再取得。
final photosProvider = FutureProvider.family<List<Photo>, String>(
  (ref, siteId) => ref.watch(photoRepositoryProvider).listPhotos(siteId),
);

/// Storage パスから表示用の署名付きURLを生成する。
final photoUrlProvider = FutureProvider.family<String, String>(
  (ref, path) => ref.watch(photoRepositoryProvider).createSignedUrl(path),
);
