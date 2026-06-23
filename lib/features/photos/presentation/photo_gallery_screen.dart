import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../export/application/pdf_export_controller.dart';
import '../../sites/application/sites_providers.dart';
import '../application/photos_providers.dart';
import '../data/photo.dart';
import 'photo_add.dart';
import 'photo_thumbnail.dart';

/// P-Gallery: 現場の写真ギャラリー（全件・新しい順・枚数表示）。
/// 既存 photosProvider / photoUrlProvider のみ使用（新Providerなし）。
class PhotoGalleryScreen extends ConsumerWidget {
  const PhotoGalleryScreen({super.key, required this.siteId});

  final String siteId;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(photosProvider(siteId));
    await ref.read(photosProvider(siteId).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosProvider(siteId));
    // 追加・台帳PDFに必要な現場情報は既存 siteDetailProvider から取得（新Providerなし）。
    final site = ref.watch(siteDetailProvider(siteId)).value;
    final companyId = site?.companyId;
    final exporting = ref.watch(pdfExportControllerProvider).isLoading;
    final photoCount = photosAsync.value?.length ?? 0;

    final title = photosAsync.maybeWhen(
      data: (photos) => '現場の写真 (${photos.length})',
      orElse: () => '現場の写真',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            key: const Key('ledger_pdf_button'),
            tooltip: '写真台帳PDF',
            icon: exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            onPressed: (exporting || site == null || photoCount == 0)
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await ref
                        .read(pdfExportControllerProvider.notifier)
                        .exportPhotoLedger(siteId: siteId, siteName: site.name);
                    if (!ok) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('PDFの出力に失敗しました')),
                      );
                    }
                  },
          ),
        ],
      ),
      floatingActionButton: companyId == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('gallery_add_fab'),
              onPressed: () => showAddPhotoSheet(
                context,
                ref,
                siteId: siteId,
                companyId: companyId,
              ),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('写真を追加'),
            ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: photosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              const Center(child: Text('写真の取得に失敗しました')),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(photosProvider(siteId)),
                  child: const Text('再読み込み'),
                ),
              ),
            ],
          ),
          data: (photos) {
            if (photos.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 140),
                  Center(child: Text('写真がありません')),
                  SizedBox(height: 4),
                  Center(
                    child: Text('右下の「写真を追加」から登録できます',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ],
              );
            }
            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: photos.length,
              itemBuilder: (context, i) => _GalleryTile(
                photo: photos[i],
                onTap: () => context.push('/sites/$siteId/photos/$i'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.photo, required this.onTap});

  final Photo photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: PhotoThumbnail(path: photo.path),
      ),
    );
  }
}
