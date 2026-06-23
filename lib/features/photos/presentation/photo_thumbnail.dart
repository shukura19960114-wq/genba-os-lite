import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/photos_providers.dart';

/// 写真サムネ/画像表示の共通ウィジェット。
/// 既存 [photoUrlProvider] で署名付きURLを取得して表示する（新Providerなし）。
class PhotoThumbnail extends ConsumerWidget {
  const PhotoThumbnail({super.key, required this.path, this.fit = BoxFit.cover});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(photoUrlProvider(path));
    final ph = Theme.of(context).colorScheme.surfaceContainerHighest;

    return urlAsync.when(
      data: (url) => Image.network(
        url,
        fit: fit,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : Container(color: ph),
        errorBuilder: (context, _, _) => Container(
          color: ph,
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      ),
      loading: () => Container(color: ph),
      error: (_, _) => Container(
        color: ph,
        child: const Icon(Icons.error_outline, color: Colors.grey),
      ),
    );
  }
}
