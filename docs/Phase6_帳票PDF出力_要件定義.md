# Phase 6 帳票・PDF出力 要件定義書（MVP）

**作成日:** 2026-06-23　／　**対象:** Phase 6「帳票・PDF出力」　／　**方針:** 最小工数。既存データ（日報・写真）を流用してPDF化・共有。

---

## 目的
建設会社が、現場の記録を**提出できる成果物（PDF）**として出力・共有できるようにする。
利用者ヒアリングが無い段階でも、**単体で価値を提示できる**（写真台帳・日報は建設の定番帳票）。

## スコープ（実装する / 実装しない）
| 実装する（MVP） | 実装しない（後続・非対象） |
|---|---|
| **日報PDF出力**（1件の日報をPDF化→共有） | 帳票テンプレートのカスタマイズ／レイアウト編集 |
| **写真台帳PDF出力**（現場の写真をグリッドでPDF化→共有） | Excel/CSV 出力 |
| OS標準の**共有/保存/印刷**（`printing`） | 電子署名・押印・ウォーターマーク |
| 現場名・日付・撮影日時などの基本項目 | クラウド保存・メール自動送信 |
| | 月次集計・期間指定の一括帳票 |

> 帳票は2種（**日報PDF** と **写真台帳PDF**）。共通のPDF基盤（フォント・共有）を1つ作り、両方で使う。

---

## 1. ユーザーストーリー
1. 監督として、ある**日報をPDFにして**元請けや事務所に**共有/印刷**したい。
2. 監督として、現場の**写真を「写真台帳」PDF**にまとめて提出したい（現場名・撮影日時付き）。
3. 出力したPDFを、iOS標準の**共有シート**（AirDrop/メール/保存/印刷）で扱いたい。
4. 引き続き**自社のデータのみ**（既存RLS維持。PDFは取得済みデータから生成）。

## 2. DB変更有無
**変更なし（マイグレーション不要・Supabase手作業なし）**。
- 日報PDF：既存 `reports`（`reportDetailProvider` / `ReportRepository.fetch`）を流用。
- 写真台帳：既存 `photos`（`photosProvider` / `PhotoRepository.listPhotos`）＋写真バイト取得。
  - 写真の画像バイトは Supabase Storage から取得（RLSで自社のみ）。`PhotoRepository` に **`downloadPhoto(path)`（バイト取得）を1メソッド追加**（DB変更ではない）。

## 3. 画面一覧
新規画面は作らず、**既存画面にPDF出力アクションを追加**（最小工数）。

| 画面 | 区分 | 追加内容 |
|---|---|---|
| 日報詳細（S3） | 変更 | AppBar に「PDF出力」アクション（または本体ボタン）→ 生成→共有シート |
| 現場詳細 or 写真ギャラリー | 変更 | 「写真台帳PDF」ボタン → 生成→共有シート |
| （共通） | — | 生成中はローディング表示、失敗時 SnackBar |

> プレビュー画面は **MVPでは作らない**（`printing` の共有/プレビューはOS/プラグイン側に委譲）。

## 4. Repository / Service構成
- 既存 `ReportRepository` / `PhotoRepository` を**流用**（データ取得）。
- 追加：`PhotoRepository.downloadPhoto(String path) → Uint8List`（Storageからバイト取得。写真台帳の画像埋め込み用）。
- 追加：**`PdfService`**（`pdf` パッケージでドキュメント構築、`Uint8List` を返す。抽象interface + 実装でテスト差し替え可）
  - `Future<Uint8List> buildReportPdf(Report report)`
  - `Future<Uint8List> buildPhotoLedgerPdf({required String siteName, required List<(Photo, Uint8List)> photos})`
- 共有：`printing` の `Printing.sharePdf(bytes:, filename:)`（OS共有シート）。

## 5. Riverpod構成（新Providerは最小限）
- データ取得は既存 `reportDetailProvider` / `photosProvider` を流用。
- 追加：`pdfServiceProvider`（`PdfService` を注入。テストでfake差し替え）。
- 追加：**`PdfExportController`**（`AsyncNotifierProvider.autoDispose`）
  - `Future<bool> exportReport(String reportId)`：日報取得→`buildReportPdf`→`sharePdf`
  - `Future<bool> exportPhotoLedger({required String siteId, required String siteName})`：写真一覧取得→各バイトDL→`buildPhotoLedgerPdf`→`sharePdf`
  - 進行状態（loading/error）を保持。画面はそれを watch してボタンをローディング化。

## 6. 完了条件
1. 日報PDF出力成功（共有シートが開き、日報内容のPDFができる）
2. 写真台帳PDF出力成功（現場の写真がPDFに並ぶ・現場名/日時付き）
3. 既存RLS維持（自社データのみ）
4. analyze成功
5. test成功
6. dev実機確認（実機でPDF生成→共有シート表示→PDFを開ける）

## 7. テスト条件
- **PdfService（Fake）でController をテスト**：`exportReport` / `exportPhotoLedger` の成功（true）/失敗（false・stateエラー）。
- **PDF生成のスモーク**：`buildReportPdf` が**空でないバイト列（length>0）**を返す（実描画の中身検証は実機）。
  - ※日本語フォント取得にネットワークが要る場合、フォント取得をモック可能な構成にし、CIで落ちないようにする。
- 既存46件が緑のまま。実際のレイアウト/共有は dev 実機で確認。

---

## 新規依存・留意点
- **新規依存**：`pdf ^3.13.0` / `printing ^5.15.0`（dry-run で解決確認済み）。
- **日本語フォント**：`pdf` 標準フォントは日本語非対応。対応案2つ：
  - (A) `printing` の `PdfGoogleFonts.notoSansJapaneseRegular()` で実行時取得（**アセット同梱不要**・キャッシュ。生成時にネット要）。
  - (B) NotoSans JP の TTF をアセット同梱（オフライン可・リポジトリ容量増）。
  - → MVP は **(A) を推奨**（同梱物を増やさない。アプリは元々ネット前提）。実装時に最終決定。
- **DB変更・Supabase手作業**：なし。
- **工数目安**：🤖 実装 約50〜70分（PDF基盤＋2帳票＋共有＋テスト）＋ 🧑 実機確認 約5分。

> 実装に進む場合、この要件定義を基に**実装仕様書（最小工数）**を作成してから着手します（Phase 2〜4と同じ流れ）。PDF版が必要なら共有用に出力します。
