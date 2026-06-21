import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/async_value_widget.dart';
import '../application/sites_providers.dart';
import '../data/site.dart';

/// 現場詳細画面。現場名・住所・ステータス・登録日を表示する。
class SiteDetailScreen extends ConsumerWidget {
  const SiteDetailScreen({super.key, required this.siteId});

  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteDetailProvider(siteId));

    return Scaffold(
      appBar: AppBar(title: const Text('現場の詳細')),
      body: AsyncValueWidget<Site?>(
        value: siteAsync,
        data: (site) {
          if (site == null) {
            return const Center(child: Text('現場が見つかりませんでした'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                site.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              _DetailRow(
                icon: Icons.place_outlined,
                label: '住所',
                value: site.address?.isNotEmpty == true
                    ? site.address!
                    : '未登録',
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
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
