import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/photos_providers.dart';
import 'photo_thumbnail.dart';

final _dateTimeFmt = DateFormat('yyyy/MM/dd HH:mm');

/// P-Viewer: 写真の全画面ビューア（左右スワイプ＋ピンチズーム＋撮影日時表示）。
/// 既存 photosProvider / photoUrlProvider のみ使用。現在indexは画面ローカル state。
class PhotoViewerScreen extends ConsumerStatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.siteId,
    required this.initialIndex,
  });

  final String siteId;
  final int initialIndex;

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(photosProvider(widget.siteId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: photosAsync.maybeWhen(
          data: (photos) => Text(
            photos.isEmpty ? '' : '${_index.clamp(0, photos.length - 1) + 1} / ${photos.length}',
          ),
          orElse: () => const Text(''),
        ),
      ),
      body: photosAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => const Center(
          child: Text('写真の取得に失敗しました',
              style: TextStyle(color: Colors.white)),
        ),
        data: (photos) {
          if (photos.isEmpty) {
            return const Center(
              child: Text('写真がありません',
                  style: TextStyle(color: Colors.white)),
            );
          }
          final current = photos[_index.clamp(0, photos.length - 1)];
          return Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: PhotoThumbnail(
                      path: photos[i].path,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 16, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text(
                        current.createdAt != null
                            ? _dateTimeFmt.format(current.createdAt!.toLocal())
                            : '—',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
