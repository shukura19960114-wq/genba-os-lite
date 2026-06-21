import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../application/report_providers.dart';

final _dateFmt = DateFormat('yyyy/MM/dd');

/// S1: 日報一覧（現場別）。
class ReportListScreen extends ConsumerWidget {
  const ReportListScreen({super.key, required this.siteId});

  final String siteId;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(reportsBySiteProvider(siteId));
    await ref.read(reportsBySiteProvider(siteId).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsBySiteProvider(siteId));

    return Scaffold(
      appBar: AppBar(title: const Text('日報')),
      floatingActionButton: FloatingActionButton(
        key: const Key('report_add_fab'),
        onPressed: () => context.push('/sites/$siteId/reports/new'),
        child: const Icon(Icons.add),
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('日報の取得に失敗しました'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(reportsBySiteProvider(siteId)),
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
        data: (reports) => RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: reports.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 160),
                    Center(child: Text('日報がまだありません')),
                    SizedBox(height: 4),
                    Center(
                      child: Text('右下の＋から作成できます',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = reports[i];
                    return ListTile(
                      title: Text(_dateFmt.format(r.reportDate)),
                      subtitle: Text(
                        '${r.weatherLabel}・${r.workContent}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () =>
                          context.push('/sites/$siteId/reports/${r.id}'),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
