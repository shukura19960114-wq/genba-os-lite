import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/export/data/pdf_service.dart';
import 'package:genba_os_lite/features/reports/data/report.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('buildReportPdf は空でないPDFバイト列を返す（フォント注入でネット非依存）', () async {
    // 日本語フォント取得をモック（標準フォント注入）。実フォントは実機で検証。
    final service = PrintingPdfService(loadJpFont: () async => pw.Font.helvetica());
    final report = Report(
      id: 'r1',
      companyId: 'c1',
      siteId: 's1',
      reportDate: DateTime(2026, 6, 23),
      weather: 'sunny',
      workContent: '基礎工事 配筋検査',
      workerCount: 5,
      createdBy: 'u1',
      createdAt: DateTime(2026, 6, 23, 9),
      updatedAt: DateTime(2026, 6, 23, 18),
    );

    final bytes = await service.buildReportPdf(report);

    expect(bytes.length, greaterThan(0));
  });
}
