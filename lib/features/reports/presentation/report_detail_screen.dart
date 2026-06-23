import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../export/application/pdf_export_controller.dart';
import '../application/report_providers.dart';

final _dateFmt = DateFormat('yyyy/MM/dd');
final _dateTimeFmt = DateFormat('yyyy/MM/dd HH:mm');

/// S3: 日報詳細。
class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({
    super.key,
    required this.siteId,
    required this.reportId,
  });

  final String siteId;
  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportDetailProvider(reportId));
    final exporting = ref.watch(pdfExportControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('日報詳細'),
        actions: [
          IconButton(
            key: const Key('report_pdf_button'),
            tooltip: 'PDF出力',
            icon: exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            onPressed: exporting
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await ref
                        .read(pdfExportControllerProvider.notifier)
                        .exportReport(reportId);
                    if (!ok) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('PDFの出力に失敗しました')),
                      );
                    }
                  },
          ),
          IconButton(
            key: const Key('report_edit_button'),
            icon: const Icon(Icons.edit),
            onPressed: () =>
                context.push('/sites/$siteId/reports/$reportId/edit'),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('日報の取得に失敗しました'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(reportDetailProvider(reportId)),
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
        data: (report) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _row('作業日', _dateFmt.format(report.reportDate)),
            const Divider(height: 24),
            _row('天候', report.weatherLabel),
            const Divider(height: 24),
            _row('作業内容', report.workContent, multiline: true),
            const Divider(height: 24),
            _row(
              '作業人数',
              report.workerCount != null ? '${report.workerCount} 人' : '—',
            ),
            const Divider(height: 24),
            _row('作成者', report.createdBy ?? '—'),
            const Divider(height: 24),
            _row('更新日時', _dateTimeFmt.format(report.updatedAt.toLocal())),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool multiline = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: multiline ? null : 1,
            overflow: multiline ? null : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
