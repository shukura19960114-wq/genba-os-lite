import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/async_value_widget.dart';
import '../../photos/application/photo_upload_controller.dart';
import '../../photos/application/photos_providers.dart';
import '../../photos/data/image_picker_service.dart';
import '../../photos/data/photo.dart';
import '../application/sites_providers.dart';
import '../data/site.dart';

/// 現場詳細画面。現場名・住所・ステータス・登録日と、現場写真の一覧/追加を表示する。
class SiteDetailScreen extends ConsumerWidget {
  const SiteDetailScreen({super.key, required this.siteId});

  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteDetailProvider(siteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('現場の詳細'),
        actions: [
          IconButton(
            key: const Key('site_edit_button'),
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/sites/$siteId/edit'),
          ),
        ],
      ),
      body: AsyncValueWidget<Site?>(
        value: siteAsync,
        data: (site) {
          if (site == null) {
            return const Center(child: Text('現場が見つかりませんでした'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(site.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              _DetailRow(
                icon: Icons.place_outlined,
                label: '住所',
                value: site.address?.isNotEmpty == true ? site.address! : '未登録',
              ),
              const Divider(height: 24),
              _DetailRow(
                icon: Icons.flag_outlined,
                label: 'ステータス',
                value: siteStatusLabel(site.status),
              ),
              const Divider(height: 24),
              _DetailRow(
                icon: Icons.event_outlined,
                label: '登録日',
                value: _formatDate(site.createdAt),
              ),
              const SizedBox(height: 8),
              // Phase 2: 日報への導線
              ListTile(
                key: const Key('site_reports_tile'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('日報'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/sites/${site.id}/reports'),
              ),
              const SizedBox(height: 16),
              _PhotosSection(siteId: siteId, companyId: site.companyId),
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    final local = d.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '${local.year}年$mm月$dd日';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 14),
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child:
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

/// 写真セクション（一覧グリッド + 追加ボタン）。
class _PhotosSection extends ConsumerWidget {
  const _PhotosSection({required this.siteId, required this.companyId});

  final String siteId;
  final String? companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosProvider(siteId));
    final isUploading = ref.watch(photoUploadControllerProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('写真', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (isUploading)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            FilledButton.tonalIcon(
              key: const Key('photo_add_button'),
              onPressed: (isUploading || companyId == null)
                  ? null
                  : () => _onAddPressed(context, ref),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('追加'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AsyncValueWidget<List<Photo>>(
          value: photosAsync,
          data: (photos) {
            if (photos.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('写真がありません',
                      style: TextStyle(color: Colors.grey)),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: photos.length,
              itemBuilder: (context, i) => _PhotoTile(path: photos[i].path),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('写真の取得に失敗しました：$e',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Future<void> _onAddPressed(BuildContext context, WidgetRef ref) async {
    final cid = companyId;
    if (cid == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('カメラで撮影'),
              onTap: () => Navigator.of(context).pop(PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('フォトライブラリから選択'),
              onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final result = await ref
        .read(photoUploadControllerProvider.notifier)
        .addPhoto(siteId: siteId, companyId: cid, source: source);

    final message = switch (result) {
      PhotoUploadResult.uploaded => '写真をアップロードしました',
      PhotoUploadResult.cancelled => null,
      PhotoUploadResult.failed => 'アップロードに失敗しました',
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

/// 1枚の写真タイル（署名付きURLを取得して表示）。
class _PhotoTile extends ConsumerWidget {
  const _PhotoTile({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(photoUrlProvider(path));
    final placeholderColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: urlAsync.when(
        data: (url) => Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : Container(color: placeholderColor),
          errorBuilder: (context, _, _) => Container(
            color: placeholderColor,
            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        ),
        loading: () => Container(color: placeholderColor),
        error: (_, _) => Container(
          color: placeholderColor,
          child: const Icon(Icons.error_outline, color: Colors.grey),
        ),
      ),
    );
  }
}
