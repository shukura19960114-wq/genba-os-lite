import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/async_value_widget.dart';
import '../../photos/application/photo_upload_controller.dart';
import '../../photos/application/photos_providers.dart';
import '../../photos/data/photo.dart';
import '../../photos/presentation/photo_add.dart';
import '../../photos/presentation/photo_thumbnail.dart';
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

/// 写真セクション（枚数・先頭グリッド・拡大遷移・追加）。
class _PhotosSection extends ConsumerWidget {
  const _PhotosSection({required this.siteId, required this.companyId});

  final String siteId;
  final String? companyId;

  static const _previewCount = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosProvider(siteId));
    final isUploading = ref.watch(photoUploadControllerProvider).isLoading;
    final count = photosAsync.value?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(count > 0 ? '写真 ($count)' : '写真',
                style: Theme.of(context).textTheme.titleMedium),
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
            if (count > _previewCount)
              TextButton(
                key: const Key('photo_see_all_button'),
                onPressed: () => context.push('/sites/$siteId/photos'),
                child: const Text('すべて見る'),
              ),
            IconButton(
              key: const Key('photo_add_button'),
              tooltip: '写真を追加',
              onPressed: (isUploading || companyId == null)
                  ? null
                  : () => showAddPhotoSheet(context, ref,
                      siteId: siteId, companyId: companyId!),
              icon: const Icon(Icons.add_a_photo_outlined),
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
            final preview = photos.length > _previewCount
                ? photos.sublist(0, _previewCount)
                : photos;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: preview.length,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => context.push('/sites/$siteId/photos/$i'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: PhotoThumbnail(path: preview[i].path),
                ),
              ),
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
}
