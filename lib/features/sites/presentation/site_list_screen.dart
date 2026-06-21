import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../application/sites_providers.dart';
import '../data/site.dart';

/// 現場一覧画面。自社の現場（RLS適用）を新しい順に表示する。
class SiteListScreen extends ConsumerWidget {
  const SiteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(sitesListProvider);

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
              itemBuilder: (context, index) => _SiteCard(site: sites[index]),
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
  const _SiteCard({required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Text(
          site.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
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
