import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../messages/application/posts_providers.dart';
import '../application/sites_providers.dart';
import '../data/site.dart';

/// 現場一覧画面。自社の現場（RLS適用）を新しい順に表示する。
class SiteListScreen extends ConsumerWidget {
  const SiteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(sitesListProvider);
    // 未読件数 {site_id: 件数}。0006 未適用や取得前は空（バッジなし）で安全に劣化。
    final unread = ref.watch(unreadCountsProvider).value ?? const <String, int>{};

    return Scaffold(
      appBar: AppBar(title: const Text('現場一覧')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('site_add_fab'),
        onPressed: () => context.push(RoutePaths.siteNew),
        icon: const Icon(Icons.add),
        label: const Text('現場を登録'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sitesListProvider);
          ref.invalidate(unreadCountsProvider);
          await ref.read(sitesListProvider.future);
        },
        child: AsyncValueWidget<List<Site>>(
          value: sitesAsync,
          data: (sites) {
            if (sites.isEmpty) return const _EmptyState();
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: sites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _SiteCard(
                site: sites[index],
                unread: unread[sites[index].id] ?? 0,
              ),
            );
          },
          error: (e, _) => _ErrorState(
            message: '$e',
            onRetry: () => ref.invalidate(sitesListProvider),
          ),
        ),
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  const _SiteCard({required this.site, this.unread = 0});

  final Site site;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Row(
          children: [
            Flexible(
              child: Text(
                site.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              _UnreadBadge(count: unread),
            ],
          ],
        ),
        subtitle: Text(
          site.address?.isNotEmpty == true ? site.address! : '住所未登録',
        ),
        trailing: _StatusChip(status: site.status),
        onTap: () => context.push('${RoutePaths.sites}/${site.id}'),
      ),
    );
  }
}

/// 未読の連絡件数バッジ（赤）。
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      'completed' => Colors.green,
      'suspended' => scheme.outline,
      _ => scheme.primary,
    };
    return Chip(
      label: Text(siteStatusLabel(status)),
      labelStyle: TextStyle(color: color, fontSize: 12),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    // RefreshIndicator が効くようスクロール可能にする。
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.location_city_outlined,
            size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        const Center(child: Text('現場がまだありません')),
        const SizedBox(height: 4),
        const Center(
          child: Text('右下の「現場を登録」から追加してください',
              style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Center(child: Text('一覧の取得に失敗しました')),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('再試行'),
          ),
        ),
      ],
    );
  }
}
