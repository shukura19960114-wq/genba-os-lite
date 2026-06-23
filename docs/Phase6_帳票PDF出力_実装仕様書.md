# Phase 6 帳票・PDF出力 実装仕様書（最小工数）

**作成日:** 2026-06-23　／　**前提:** [要件定義書](Phase6_帳票PDF出力_要件定義.md)を承認済み。日本語フォントは **(A) `PdfGoogleFonts.notoSansJapaneseRegular()` 実行時取得**で確定。
**方針:** 既存データ（reports / photos）を流用。DB変更なし。新規画面なし。既存画面にPDF出力アクションを追加。

---

## 0. 追加依存（pubspec.yaml）
```yaml
  # --- Phase 6 帳票・PDF出力 ---
  pdf: ^3.13.0        # PDFドキュメント構築
  printing: ^5.15.0   # OS共有シート・PdfGoogleFonts（日本語フォント実行時取得）
```

## 1. 追加・変更ファイル一覧

| 区分 | パス | 内容 |
|---|---|---|
| 追加 | `lib/features/export/data/pdf_service.dart` | `PdfService`（抽象）＋ `PrintingPdfService`（実装）。日報PDF・写真台帳PDF構築＋共有。`pdfServiceProvider`。 |
| 追加 | `lib/features/export/application/pdf_export_controller.dart` | `PdfExportController`（`AsyncNotifierProvider.autoDispose`）。`exportReport` / `exportPhotoLedger`。 |
| 変更 | `lib/features/photos/data/photo_repository.dart` | `downloadPhoto(String path) → Uint8List` を1メソッド追加（Storageバイト取得）。 |
| 変更 | `lib/features/reports/presentation/report_detail_screen.dart` | AppBar に「PDF出力」アクション（IconButton）追加。 |
| 変更 | `lib/features/photos/presentation/photo_gallery_screen.dart` | AppBar に「写真台帳PDF」アクション追加。 |
| 追加 | `test/export/fakes.dart` | `FakePdfService`（呼び出し記録・成否制御）。 |
| 追加 | `test/export/pdf_export_controller_test.dart` | Controller の success/failure テスト。 |
| 追加 | `test/export/pdf_service_smoke_test.dart` | `buildReportPdf` がバイト列（length>0）を返すスモーク（フォントは注入でモック）。 |

> 新Providerは `pdfServiceProvider` と `pdfExportControllerProvider` のみ。データ取得は既存 `reportRepositoryProvider` / `photoRepositoryProvider` を流用。

## 2. PdfService（data層）
```text
abstract interface class PdfService
  Future<Uint8List> buildReportPdf(Report report);
  Future<Uint8List> buildPhotoLedgerPdf({required String siteName, required List<LedgerPhoto> photos});
  Future<void> sharePdf({required Uint8List bytes, required String filename});

class LedgerPhoto { final Photo photo; final Uint8List bytes; }   // 画像＋メタの組
```
- **PrintingPdfService 実装:**
  - フォント取得を注入可能に：`PrintingPdfService({Future<pw.Font> Function()? loadJpFont})`。既定は `PdfGoogleFonts.notoSansJapaneseRegular`。
  - 取得フォントは**インスタンスでキャッシュ**（複数ページ・複数回出力でも1回取得）。
  - `buildReportPdf`: A4縦。タイトル「日報」＋現場名は呼び出し元で持たないため**日報の項目のみ**（作業日/天候/作業内容/作業人数/作成者/更新日時）をテーブル表示。
  - `buildPhotoLedgerPdf`: A4縦。見出し「写真台帳」＋現場名。3列グリッドで写真を並べ、各写真の下に撮影日時（`created_at`、`yyyy/MM/dd HH:mm`）。`pw.MemoryImage(bytes)`。1ページに収まらない分は自動改ページ（`pw.Wrap` / 複数ページ）。
  - `sharePdf`: `Printing.sharePdf(bytes: bytes, filename: filename)`。
- **`pdfServiceProvider`** = `Provider<PdfService>((ref) => PrintingPdfService());`

## 3. PhotoRepository.downloadPhoto（data層・追加）
```text
Future<Uint8List> downloadPhoto(String path);   // _client.storage.from('photos').download(path)
```
RLSで自社のみ取得可。FakePhotoRepository（既存テスト）にもダミー実装を追加。

## 4. PdfExportController（application層）
```text
pdfExportControllerProvider = AsyncNotifierProvider.autoDispose<PdfExportController, void>(PdfExportController.new)

Future<bool> exportReport(String reportId)
  state = loading
  → report = reportRepository.fetch(reportId)
  → bytes  = pdfService.buildReportPdf(report)
  → pdfService.sharePdf(bytes, '日報_<reportDate>.pdf')
  → state = data; return true
  例外時: state = error; return false

Future<bool> exportPhotoLedger({required String siteId, required String siteName})
  state = loading
  → photos = photoRepository.listPhotos(siteId)
  → 各 photo.path を downloadPhoto でバイト取得（失敗写真はスキップ）
  → bytes = pdfService.buildPhotoLedgerPdf(siteName, ledgerPhotos)
  → sharePdf(bytes, '写真台帳_<siteName>.pdf')
  → state = data; return true
  写真0枚: false（SnackBarで「写真がありません」）／例外時: error, return false
```
- `AsyncNotifier<void>` 基底 ＋ `.autoDispose`（Riverpod 3.x。`AutoDisposeAsyncNotifier` は不可）。
- メソッド名は `update` を避ける（予約）。`exportReport`/`exportPhotoLedger` を使用。

## 5. UI導線（presentation層・変更のみ）
- **日報詳細（report_detail_screen）:** AppBar actions に `IconButton(Icons.picture_as_pdf)` 追加。`Key('report_pdf_button')`。押下→`exportReport(reportId)`。`pdfExportControllerProvider` の `isLoading` を watch しローディング表示、`false`/error 時 SnackBar。`await` 前に `ScaffoldMessenger` を捕捉。
- **写真ギャラリー（photo_gallery_screen）:** AppBar actions に `IconButton(Icons.picture_as_pdf)`。`Key('ledger_pdf_button')`。`siteName` は `siteDetailProvider(siteId).value?.name`。押下→`exportPhotoLedger(siteId, siteName)`。写真0枚や未取得時はボタン無効 or SnackBar。
- 生成中は両ボタンを `isLoading` で無効化。

## 6. テスト
- **pdf_export_controller_test:** FakePdfService + FakeReportRepository / FakePhotoRepository を override。
  - `exportReport` 成功（true・sharePdf呼ばれた・state not error）
  - `exportReport` 失敗（fetch例外 → false・state error）
  - `exportPhotoLedger` 成功（写真2枚・downloadPhoto×2・sharePdf呼ばれた）
  - `exportPhotoLedger` 写真0枚（false・sharePdf呼ばれない）
  - `exportPhotoLedger` 失敗（buildで例外 → false・error）
- **pdf_service_smoke_test:** `PrintingPdfService(loadJpFont: () async => <注入フォント>)` で `buildReportPdf` を呼び、`bytes.length > 0` を検証（ネット非依存）。注入フォントは実環境で確実に使える方式を実装時に確定（Latin標準フォント or テスト用バイト）。
- 既存46件は緑のまま（合計はテスト追加分だけ増える）。

## 7. 完了条件（要件と同一）
1. 日報PDF出力成功（共有シート→日報PDF）　2. 写真台帳PDF出力成功（写真グリッド・現場名/日時）
3. 既存RLS維持　4. analyze成功　5. test成功　6. dev実機確認

## 8. 非対象（再掲）
テンプレ編集 / Excel・CSV / 署名・押印 / クラウド保存・メール送信 / 月次集計 / 削除。DB変更・Supabase手作業なし。
