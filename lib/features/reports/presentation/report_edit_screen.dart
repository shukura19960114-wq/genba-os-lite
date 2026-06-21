import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/report_providers.dart';
import 'report_form_screen.dart';

/// S4: 日報編集（ラッパ）。詳細をロードしてからフォームへ既存値を渡す。
class ReportEditScreen extends ConsumerWidget {
  const ReportEditScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportDetailProvider(reportId));

    return reportAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('日報編集')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('日報編集')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('日報の取得に失敗しました'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(reportDetailProvider(reportId)),
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
      // data 時は ReportFormScreen 自身の Scaffold/AppBar を使う（二重AppBar回避）。
      data: (report) => ReportFormScreen(
        siteId: report.siteId,
        initialReport: report,
      ),
    );
  }
}
