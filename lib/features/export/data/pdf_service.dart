import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../photos/data/photo.dart';
import '../../reports/data/report.dart';

/// 写真台帳の1要素（画像バイト + 写真メタ）。
class LedgerPhoto {
  const LedgerPhoto({required this.photo, required this.bytes});

  final Photo photo;
  final Uint8List bytes;
}

/// 帳票PDF（日報・写真台帳）の構築と共有を担う抽象。テストで差し替え可能。
abstract interface class PdfService {
  /// 日報1件をPDF化してバイト列を返す。
  Future<Uint8List> buildReportPdf(Report report);

  /// 現場の写真台帳をPDF化してバイト列を返す。
  Future<Uint8List> buildPhotoLedgerPdf({
    required String siteName,
    required List<LedgerPhoto> photos,
  });

  /// 生成したPDFをOSの共有シート（AirDrop/メール/保存/印刷）で共有する。
  Future<void> sharePdf({required Uint8List bytes, required String filename});
}

/// `pdf` + `printing` による実装。日本語フォントは実行時取得（既定: Noto Sans JP）。
class PrintingPdfService implements PdfService {
  PrintingPdfService({Future<pw.Font> Function()? loadJpFont})
      : _loadJpFont = loadJpFont ?? PdfGoogleFonts.notoSansJPRegular;

  /// 日本語フォントの取得関数。テストでは注入してネット非依存にする。
  final Future<pw.Font> Function() _loadJpFont;

  /// 取得済みフォントのインスタンスキャッシュ（複数回出力でも1回だけ取得）。
  pw.Font? _jpFont;

  static final _dateFmt = DateFormat('yyyy/MM/dd');
  static final _dateTimeFmt = DateFormat('yyyy/MM/dd HH:mm');

  Future<pw.Font> _font() async => _jpFont ??= await _loadJpFont();

  pw.ThemeData _theme(pw.Font font) =>
      pw.ThemeData.withFont(base: font, bold: font);

  @override
  Future<Uint8List> buildReportPdf(Report report) async {
    final font = await _font();
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: _theme(font),
        build: (context) => [
          pw.Text('日報',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          _kv('作業日', _dateFmt.format(report.reportDate)),
          _kv('天候', report.weatherLabel),
          _kv('作業人数',
              report.workerCount != null ? '${report.workerCount} 人' : '—'),
          _kv('作成者', report.createdBy ?? '—'),
          _kv('更新日時', _dateTimeFmt.format(report.updatedAt.toLocal())),
          pw.SizedBox(height: 12),
          pw.Text('作業内容',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(report.workContent),
        ],
      ),
    );
    return doc.save();
  }

  @override
  Future<Uint8List> buildPhotoLedgerPdf({
    required String siteName,
    required List<LedgerPhoto> photos,
  }) async {
    final font = await _font();
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: _theme(font),
        build: (context) => [
          pw.Text('写真台帳',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('現場：$siteName'),
          pw.SizedBox(height: 12),
          ..._photoRows(photos),
        ],
      ),
    );
    return doc.save();
  }

  @override
  Future<void> sharePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  pw.Widget _kv(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// 写真を3列ずつの行に分割する。MultiPage は行単位で自動改ページする。
  List<pw.Widget> _photoRows(List<LedgerPhoto> photos) {
    const columns = 3;
    final rows = <pw.Widget>[];
    for (var i = 0; i < photos.length; i += columns) {
      final chunk = photos.sublist(i, math.min(i + columns, photos.length));
      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < columns; j++)
                pw.Expanded(
                  child: pw.Padding(
                    padding: pw.EdgeInsets.only(right: j < columns - 1 ? 12 : 0),
                    child: j < chunk.length
                        ? _photoTile(chunk[j])
                        : pw.SizedBox(),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  pw.Widget _photoTile(LedgerPhoto lp) {
    final captured = lp.photo.createdAt;
    final caption =
        captured != null ? _dateTimeFmt.format(captured.toLocal()) : '—';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 110,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.ClipRect(
            child: pw.Image(pw.MemoryImage(lp.bytes), fit: pw.BoxFit.cover),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(caption, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }
}

/// [PdfService] を提供する Provider。
final pdfServiceProvider =
    Provider<PdfService>((ref) => PrintingPdfService());
