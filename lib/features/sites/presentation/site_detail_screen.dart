import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/async_value_widget.dart';
import '../../auth/application/current_profile_provider.dart';
import '../../org/application/members_providers.dart';
import '../../photos/application/photo_upload_controller.dart';
import '../../photos/application/photos_providers.dart';
import '../../photos/data/photo.dart';
import '../../photos/presentation/photo_add.dart';
import '../../photos/presentation/photo_thumbnail.dart';
import '../application/site_member_controller.dart';
import '../application/sites_providers.dart';
import '../data/site.dart';
import '../data/site_member_repository.dart';

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
              // Phase 7c: 担当メンバー
              _SiteMembersSection(siteId: siteId),
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

String _roleLabel(String? role) => switch (role) {
      'owner' => 'オーナー',
      'admin' => '管理者',
      'member' => 'メンバー',
      _ => '—',
    };

/// 担当メンバーセクション（割当一覧・追加/解除）。割当/解除は owner/admin のみ。
class _SiteMembersSection extends ConsumerWidget {
  const _SiteMembersSection({required this.siteId});

  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedAsync = ref.watch(siteMembersProvider(siteId));
    final isManager = isManagerRole(ref.watch(currentRoleProvider));
    final isBusy = ref.watch(siteMemberControllerProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('担当メンバー',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (isBusy)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (isManager)
              IconButton(
                key: const Key('site_member_add_button'),
                tooltip: 'メンバーを割り当て',
                onPressed: isBusy
                    ? null
                    : () => _showAssignSheet(context, ref,
                        assignedAsync.value ?? const []),
                icon: const Icon(Icons.person_add_alt_1_outlined),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AsyncValueWidget<List<AssignedMember>>(
          value: assignedAsync,
          data: (members) {
            if (members.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('担当メンバーがいません',
                    style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              children: [
                for (final m in members)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.person, size: 20)),
                      title: Text(m.email ?? '(メール未設定)'),
                      subtitle: Text(_roleLabel(m.role)),
                      trailing: isManager
                          ? IconButton(
                              key: Key('site_member_remove_${m.profileId}'),
                              tooltip: '解除',
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: isBusy
                                  ? null
                                  : () => ref
                                      .read(siteMemberControllerProvider
                                          .notifier)
                                      .unassign(
                                          siteId: siteId,
                                          profileId: m.profileId),
                            )
                          : null,
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('担当メンバーの取得に失敗しました：$e',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Future<void> _showAssignSheet(
    BuildContext context,
    WidgetRef ref,
    List<AssignedMember> assigned,
  ) async {
    final assignedIds = assigned.map((e) => e.profileId).toSet();
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final membersAsync = ref.watch(membersProvider);
              return membersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('メンバーの取得に失敗しました：$e'),
                ),
                data: (all) {
                  final candidates = all
                      .where((p) => !assignedIds.contains(p.id))
                      .toList();
                  if (candidates.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('割り当てできるメンバーがいません'),
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('割り当てるメンバーを選択',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      for (final p in candidates)
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(p.email ?? '(メール未設定)'),
                          subtitle: Text(_roleLabel(p.role)),
                          onTap: () async {
                            Navigator.pop(context);
                            final ok = await ref
                                .read(siteMemberControllerProvider.notifier)
                                .assign(siteId: siteId, profileId: p.id);
                            messenger.showSnackBar(SnackBar(
                              content:
                                  Text(ok ? '割り当てました' : '割り当てに失敗しました'),
                            ));
                          },
                        ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
