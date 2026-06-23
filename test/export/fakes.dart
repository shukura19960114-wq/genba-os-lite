import 'dart:typed_data';

import 'package:genba_os_lite/features/export/data/pdf_service.dart';
import 'package:genba_os_lite/features/reports/data/report.dart';
import 'package:genba_os_lite/features/reports/data/report_repository.dart';

/// テスト用 [PdfService] フェイク。呼び出しを記録し、失敗も再現できる。
class FakePdfService implements PdfService {
  FakePdfService({this.failBuild = false});

  final bool failBuild;

  int reportBuildCount = 0;
  int ledgerBuildCount = 0;
  int shareCount = 0;
  String? lastFilename;
  int? lastLedgerPhotoCount;

  @override
  Future<Uint8List> buildReportPdf(Report report) async {
    if (failBuild) throw Exception('build failed');
    reportBuildCount++;
    return Uint8List.fromList(const [37, 80, 68, 70]); // "%PDF"
  }

  @override
  Future<Uint8List> buildPhotoLedgerPdf({
    required String siteName,
    required List<LedgerPhoto> photos,
  }) async {
    if (failBuild) throw Exception('build failed');
    ledgerBuildCount++;
    lastLedgerPhotoCount = photos.length;
    return Uint8List.fromList(const [37, 80, 68, 70]);
  }

  @override
  Future<void> sharePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    shareCount++;
    lastFilename = filename;
  }
}

/// テスト用 [ReportRepository] フェイク（fetch のみ使用）。
class FakeReportRepository implements ReportRepository {
  FakeReportRepository({this.failOnFetch = false});

  final bool failOnFetch;

  @override
  Future<Report> fetch(String id) async {
    if (failOnFetch) throw Exception('fetch failed');
    return Report(
      id: id,
      companyId: 'c1',
      siteId: 's1',
      reportDate: DateTime(2026, 6, 23),
      weather: 'sunny',
      workContent: '基礎工事',
      workerCount: 5,
      createdBy: 'u1',
      createdAt: DateTime(2026, 6, 23, 9),
      updatedAt: DateTime(2026, 6, 23, 18),
    );
  }

  @override
  Future<List<Report>> listBySite(String siteId) async => [];

  @override
  Future<Report> create({
    required String siteId,
    required DateTime reportDate,
    String? weather,
    required String workContent,
    int? workerCount,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Report> update({
    required String id,
    required DateTime reportDate,
    String? weather,
    required String workContent,
    int? workerCount,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) async {}
}
