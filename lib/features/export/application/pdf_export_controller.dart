import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../photos/data/photo_repository.dart';
import '../../reports/application/report_providers.dart';
import '../data/pdf_service.dart';

/// 写真が0枚で写真台帳PDFを出力できないことを表す例外。
class PdfExportEmptyException implements Exception {
  const PdfExportEmptyException();
  @override
  String toString() => '写真がありません';
}

/// 帳票PDFの出力（生成→共有）を実行し、進行状態を保持するコントローラ。
/// autoDispose: 画面を離れると状態をリセットする。
final pdfExportControllerProvider =
    AsyncNotifierProvider.autoDispose<PdfExportController, void>(
  PdfExportController.new,
);

class PdfExportController extends AsyncNotifier<void> {
  static final _fileDateFmt = DateFormat('yyyy-MM-dd');

  @override
  FutureOr<void> build() {}

  /// 日報1件をPDF化して共有する。成功で true。
  Future<bool> exportReport(String reportId) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final report = await ref.read(reportRepositoryProvider).fetch(reportId);
      final service = ref.read(pdfServiceProvider);
      final bytes = await service.buildReportPdf(report);
      await service.sharePdf(
        bytes: bytes,
        filename: '日報_${_fileDateFmt.format(report.reportDate)}.pdf',
      );
    });
    state = result;
    return !result.hasError;
  }

  /// 現場の写真台帳をPDF化して共有する。成功で true。写真0枚や失敗は false。
  Future<bool> exportPhotoLedger({
    required String siteId,
    required String siteName,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final repo = ref.read(photoRepositoryProvider);
      final photos = await repo.listPhotos(siteId);
      if (photos.isEmpty) throw const PdfExportEmptyException();

      // 各写真の画像バイトを取得。個別の取得失敗はスキップする。
      final ledger = <LedgerPhoto>[];
      for (final p in photos) {
        try {
          final bytes = await repo.downloadPhoto(p.path);
          ledger.add(LedgerPhoto(photo: p, bytes: bytes));
        } catch (_) {
          // この写真はスキップ
        }
      }
      if (ledger.isEmpty) throw const PdfExportEmptyException();

      final service = ref.read(pdfServiceProvider);
      final bytes = await service.buildPhotoLedgerPdf(
        siteName: siteName,
        photos: ledger,
      );
      await service.sharePdf(bytes: bytes, filename: '写真台帳_$siteName.pdf');
    });
    state = result;
    return !result.hasError;
  }
}
