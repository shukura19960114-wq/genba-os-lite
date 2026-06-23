import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/export/application/pdf_export_controller.dart';
import 'package:genba_os_lite/features/export/data/pdf_service.dart';
import 'package:genba_os_lite/features/photos/data/photo.dart';
import 'package:genba_os_lite/features/photos/data/photo_repository.dart';
import 'package:genba_os_lite/features/reports/application/report_providers.dart';

import '../photos/fakes.dart';
import 'fakes.dart';

ProviderContainer _container({
  required FakePdfService pdf,
  FakeReportRepository? reports,
  FakePhotoRepository? photos,
}) {
  final container = ProviderContainer(overrides: [
    pdfServiceProvider.overrideWithValue(pdf),
    reportRepositoryProvider.overrideWithValue(reports ?? FakeReportRepository()),
    photoRepositoryProvider.overrideWithValue(photos ?? FakePhotoRepository()),
  ]);
  // autoDispose を生かしたまま購読を張る。
  container.listen(pdfExportControllerProvider, (_, _) {}, fireImmediately: true);
  addTearDown(container.dispose);
  return container;
}

Photo _photo(String id) => Photo(
      id: id,
      siteId: 's1',
      companyId: 'c1',
      path: 'c1/s1/$id.jpg',
      createdAt: DateTime(2026, 6, 23, 10),
    );

void main() {
  group('PdfExportController.exportReport', () {
    test('成功 → true・日報PDF生成・共有が呼ばれる', () async {
      final pdf = FakePdfService();
      final container = _container(pdf: pdf);

      final ok = await container
          .read(pdfExportControllerProvider.notifier)
          .exportReport('r1');

      expect(ok, isTrue);
      expect(pdf.reportBuildCount, 1);
      expect(pdf.shareCount, 1);
      expect(pdf.lastFilename, '日報_2026-06-23.pdf');
      expect(container.read(pdfExportControllerProvider).hasError, isFalse);
    });

    test('取得失敗 → false・state はエラー・共有されない', () async {
      final pdf = FakePdfService();
      final container = _container(
        pdf: pdf,
        reports: FakeReportRepository(failOnFetch: true),
      );

      final ok = await container
          .read(pdfExportControllerProvider.notifier)
          .exportReport('r1');

      expect(ok, isFalse);
      expect(pdf.shareCount, 0);
      expect(container.read(pdfExportControllerProvider).hasError, isTrue);
    });
  });

  group('PdfExportController.exportPhotoLedger', () {
    test('写真2枚 → true・各バイト取得・台帳PDF生成・共有', () async {
      final pdf = FakePdfService();
      final photos = FakePhotoRepository(initial: [_photo('p1'), _photo('p2')]);
      final container = _container(pdf: pdf, photos: photos);

      final ok = await container
          .read(pdfExportControllerProvider.notifier)
          .exportPhotoLedger(siteId: 's1', siteName: '現場A');

      expect(ok, isTrue);
      expect(photos.downloadCount, 2);
      expect(pdf.ledgerBuildCount, 1);
      expect(pdf.lastLedgerPhotoCount, 2);
      expect(pdf.shareCount, 1);
      expect(pdf.lastFilename, '写真台帳_現場A.pdf');
    });

    test('写真0枚 → false・生成も共有もされない', () async {
      final pdf = FakePdfService();
      final container = _container(pdf: pdf, photos: FakePhotoRepository());

      final ok = await container
          .read(pdfExportControllerProvider.notifier)
          .exportPhotoLedger(siteId: 's1', siteName: '現場A');

      expect(ok, isFalse);
      expect(pdf.ledgerBuildCount, 0);
      expect(pdf.shareCount, 0);
      expect(container.read(pdfExportControllerProvider).hasError, isTrue);
    });

    test('生成失敗 → false・state はエラー', () async {
      final pdf = FakePdfService(failBuild: true);
      final photos = FakePhotoRepository(initial: [_photo('p1')]);
      final container = _container(pdf: pdf, photos: photos);

      final ok = await container
          .read(pdfExportControllerProvider.notifier)
          .exportPhotoLedger(siteId: 's1', siteName: '現場A');

      expect(ok, isFalse);
      expect(pdf.shareCount, 0);
      expect(container.read(pdfExportControllerProvider).hasError, isTrue);
    });
  });
}
