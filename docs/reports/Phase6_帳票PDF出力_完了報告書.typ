// Phase 6 帳票・PDF出力 — 完了報告書（チーム共有用）— typst
// 生成: typst compile docs/reports/Phase6_帳票PDF出力_完了報告書.typ docs/reports/Phase6_帳票PDF出力_完了報告書.pdf

#set document(title: "Phase 6 帳票・PDF出力 完了報告書", author: "開発チーム")
#set page(
  paper: "a4",
  margin: (x: 1.7cm, top: 1.7cm, bottom: 1.4cm),
  numbering: "1 / 1",
  footer: context [
    #set text(size: 8pt, fill: luma(130))
    #line(length: 100%, stroke: 0.4pt + luma(210))
    #v(2pt)
    現場OS Lite ・ Phase 6 帳票・PDF出力 完了報告書 ・ 2026-06-24
    #h(1fr)
    #counter(page).display("1 / 1", both: true)
  ],
)
#set text(font: "Hiragino Sans", size: 9.5pt, lang: "ja")
#set par(leading: 0.72em, justify: true)
#show raw.where(block: true): it => block(
  fill: luma(245), inset: 8pt, radius: 5pt, width: 100%, text(size: 8pt, it),
)

#let cmain = rgb("#1f6feb")
#let cok = rgb("#1a7f37")
#let cwarn = rgb("#bf3e3e")
#let ctodo = rgb("#57606a")
#let th(s) = text(weight: "bold", size: 9pt, s)
#let headfill(c) = (_, row) => if row == 0 { c.lighten(86%) } else { white }

#show heading.where(level: 1): it => block(below: 0.6em, above: 1.0em)[
  #set text(size: 13pt, weight: "bold", fill: cmain)
  #box(fill: cmain, width: 4pt, height: 0.95em, baseline: 0.12em, radius: 1pt)
  #h(6pt) #it.body
]
#show heading.where(level: 2): it => block(below: 0.4em, above: 0.65em)[
  #set text(size: 10.5pt, weight: "bold", fill: ctodo.darken(20%)); #it.body
]

// ===== 表紙 =====
#align(center)[
  #v(2pt)
  #text(size: 20pt, weight: "bold", fill: cmain)[Phase 6 帳票・PDF出力 完了報告書]
  #v(3pt)
  #text(size: 11pt)[現場OS Lite ／ 日報PDF ＋ 写真台帳PDF の出力・共有]
  #v(4pt)
  #text(size: 10pt, fill: ctodo)[作成日：2026年6月24日　／　目的：現場記録を「提出できる成果物（PDF）」として出力・共有できる]
]
#v(3pt)
#line(length: 100%, stroke: 1pt + cmain.lighten(35%))
#v(5pt)

#block(fill: cok.lighten(92%), inset: 10pt, radius: 6pt, width: 100%, stroke: 0.5pt + cok.lighten(55%))[
  #text(weight: "bold", fill: cok.darken(8%))[結論：実装・自動検証・CIまで完了 ✅] \
  #v(2pt)
  日報・写真台帳の *2帳票を PDF 出力 → OS 共有シートで共有* する機能を、*DB変更なし・新規画面なし*で追加。
  `flutter analyze`=*No issues* ／ `flutter test`=*52件 全合格* ／ iOS シミュレータビルド成功 ／ *CI 緑*。
  実フォントでの日本語PDF描画は *ローカルでPNG目視確認済み*（本書 P.3 に実物プレビュー）。
  残りは「アプリ内ボタン→共有シート表示」の端末タップ最終確認のみ（アプリはインストール・起動済み）。
]
#v(6pt)

= 1. 実装した機能
#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(cmain),
  table.header(th("機能"), th("内容")),
  [日報PDF出力], [日報詳細の *PDFアイコン* から、1件の日報を A4 PDF 化（タイトル「日報」＋作業日／天候／作業人数／作成者／更新日時の項目テーブル＋作業内容）→ 共有シート。],
  [写真台帳PDF出力], [写真ギャラリーの *PDFアイコン* から、現場の写真を *3列グリッド* で台帳 PDF 化（見出し「写真台帳」＋現場名、各写真下に撮影日時、自動改ページ）→ 共有シート。],
  [OS共有・印刷], [`printing` の共有シート（AirDrop／メール／ファイル保存／印刷）に委譲。アプリ内プレビュー画面は作らない（MVP）。],
  [日本語表示], [`PdfGoogleFonts.notoSansJPRegular` を *実行時取得*（アセット同梱なし・取得後キャッシュ）。],
)

= 2. スコープ（実装する / しない）
#table(columns: (1fr, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: (col, row) => if row == 0 { (cok, cwarn).at(col).lighten(86%) } else { white },
  table.header(th("実装した（MVP）"), th("非対象（後続・対象外）")),
  [日報PDF（1件→共有）], [帳票テンプレートのカスタマイズ／レイアウト編集],
  [写真台帳PDF（グリッド→共有）], [Excel / CSV 出力],
  [OS標準の共有／保存／印刷], [電子署名・押印・ウォーターマーク],
  [現場名・日付・撮影日時などの基本項目], [クラウド保存・メール自動送信／月次集計],
)

= 3. 追加・変更ファイル
#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 6pt, y: 4.5pt),
  fill: headfill(cmain),
  table.header(th("区分"), th("ファイル")),
  [追加（実装）],
  [`lib/features/export/data/pdf_service.dart`（`PdfService`＋`PrintingPdfService`＋`pdfServiceProvider`）／ `lib/features/export/application/pdf_export_controller.dart`（`PdfExportController`・autoDispose）],
  [変更（実装）],
  [`photos/data/photo_repository.dart`（`downloadPhoto` 追加）／ `reports/presentation/report_detail_screen.dart`（PDF出力アクション）／ `photos/presentation/photo_gallery_screen.dart`（写真台帳PDFアクション）／ `pubspec.yaml`（pdf・printing）],
  [追加（テスト）],
  [`test/export/fakes.dart`（FakePdfService・FakeReportRepository）／ `test/export/pdf_export_controller_test.dart`（5件）／ `test/export/pdf_service_smoke_test.dart`（1件）],
  [変更（テスト）],
  [`test/photos/fakes.dart`（FakePhotoRepository に `downloadPhoto`）],
  [追加（ドキュメント）],
  [`docs/Phase6_帳票PDF出力_要件定義.md`／`docs/Phase6_帳票PDF出力_実装仕様書.md`／本完了報告書],
  [変更なし],
  [DBマイグレーション／Supabase手作業／新規画面],
)
#v(2pt)
#text(size: 8.5pt, fill: ctodo)[
  ※ 自動生成の `pubspec.lock` と各OSの `generated_plugin_registrant`（pdf/printing登録）も更新。
]

= 4. 技術構成
- *PdfService（抽象）*：`buildReportPdf` / `buildPhotoLedgerPdf` / `sharePdf` の3メソッド。実装 `PrintingPdfService` は `pdf`＋`printing` を使用。フォント取得関数を *注入可能* にし、テストはネット非依存。
- *PdfExportController（`AsyncNotifierProvider.autoDispose`）*：`exportReport(reportId)` / `exportPhotoLedger(siteId, siteName)`。`AsyncValue.guard` で成否を state に反映し、成功で `true`。写真0枚は専用例外で `false`。
- *データ取得*：既存 `reportRepositoryProvider` / `photoRepositoryProvider` を流用。`PhotoRepository.downloadPhoto(path)` のみ追加（Storage バイト取得・RLSで自社のみ）。*新Repositoryなし・DB変更なし*。
- *UI*：既存2画面（日報詳細・写真ギャラリー）の AppBar に PDF アクションを追加。生成中はスピナー表示、失敗時 SnackBar。*新規画面なし*。

= 5. 品質チェック結果
#table(columns: (auto, auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(cok),
  table.header(th("項目"), th("結果"), th("内容")),
  [`flutter analyze`], [#text(fill: cok, weight: "bold")[No issues]], [警告・エラー0],
  [`flutter test`], [#text(fill: cok, weight: "bold")[52 / 52 緑]], [Phase 6 で新規6件（Controller 5＋スモーク1）。既存46件はそのまま緑],
  [iOSビルド], [#text(fill: cok, weight: "bold")[成功]], [`flutter build ios --simulator --flavor dev`。printing は Swift Package Manager で解決],
  [CI（GitHub Actions）], [#text(fill: cok, weight: "bold")[緑]], [`b7603ff`：analyze＋test を main push で自動実行],
)
#v(3pt)
*新規テストの内訳*
- `exportReport`：成功（true・PDF生成・共有・ファイル名 `日報_2026-06-23.pdf`）／取得失敗（false・state エラー・共有されない）
- `exportPhotoLedger`：写真2枚（true・downloadPhoto×2・台帳生成・共有）／0枚（false・生成も共有もしない）／生成失敗（false・state エラー）
- スモーク：`buildReportPdf` が *空でないPDFバイト列* を返す（フォント注入でネット非依存）

#pagebreak()

= 6. 生成PDFの実物プレビュー（ローカル検証）
実フォント（Noto Sans JP）を埋め込んで実際に生成し、PDFをPNGに変換して目視確認した結果です。
*日本語が正しく描画され*、写真台帳は *3列グリッド＋撮影日時＋自動改行* が機能しています。

#grid(columns: (1fr, 1fr), gutter: 10pt,
  [
    #align(center)[#text(size: 9pt, weight: "bold", fill: ctodo)[① 日報PDF]]
    #v(3pt)
    #box(stroke: 0.5pt + luma(200), radius: 3pt, clip: true, image("images/phase6/report-1.png", width: 100%))
  ],
  [
    #align(center)[#text(size: 9pt, weight: "bold", fill: ctodo)[② 写真台帳PDF]]
    #v(3pt)
    #box(stroke: 0.5pt + luma(200), radius: 3pt, clip: true, image("images/phase6/ledger-1.png", width: 100%))
  ],
)
#v(3pt)
#text(size: 8.5pt, fill: ctodo)[
  ※ サンプルデータで生成（写真はテスト用の単色画像）。実機では実際の現場写真・日報内容が入ります。
]

= 7. 完了条件チェック
#table(columns: (auto, 1fr, auto), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(cok),
  table.header(th("#"), th("条件"), th("判定")),
  [1], [日報PDFを生成・共有できる], [#text(fill: cok)[✅]],
  [2], [写真台帳PDFを生成・共有できる（現場名・日時付き）], [#text(fill: cok)[✅]],
  [3], [既存RLS維持（自社データのみ）], [#text(fill: cok)[✅]],
  [4], [`flutter analyze` 成功], [#text(fill: cok)[✅]],
  [5], [`flutter test` 成功], [#text(fill: cok)[✅]],
  [6], [dev実機確認（共有シート表示）], [#text(fill: cwarn)[△ 端末タップ最終確認のみ]],
)
#v(2pt)
#text(size: 8.5pt, fill: ctodo)[
  ※ #6 は、PDF生成・描画・iOSビルド・CI まで検証済み。残るのは「アプリ内ボタン→OS共有シートが開く」最終目視のみ（アプリは dev シミュレータにインストール・起動済み）。
]

= 8. ROADMAP 更新内容
- Phase 6（帳票・出力）を *⬜ → ✅完了*（2026-06-24）に更新。
- ★現在地を *「Phase 1〜4 ＋ 6 完了」* に更新。次候補は Phase 5（通知・連携）／Phase 7（組織・権限）。
- 実装メモ追記：PDFは `lib/features/export/`、共有は `Printing.sharePdf`、日本語フォントは注入可（テストはネット非依存）。
- DB変更なしのため、本番化前の追加SQLは発生せず（prod 適用は 0001〜0004 のまま）。

= 9. 完了判定
#block(fill: cmain.lighten(93%), inset: 10pt, radius: 6pt, width: 100%, stroke: 0.5pt + cmain.lighten(55%))[
  *Phase 6 は実質完了（実装・自動検証・CI・ローカル描画検証 すべてクリア）。* \
  唯一の残作業は、アプリ内ボタンからの *OS共有シート表示の端末タップ確認*（環境依存の最終目視）。
  これは生成ロジック・PDF描画・ネイティブ統合が検証済みであることから、表示阻害要因はない見込み。
]

= 10. 次フェーズの提案
#table(columns: (auto, 1fr, auto), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(cmain),
  table.header(th("候補"), th("内容・狙い"), th("推奨度")),
  [Phase 7\ 組織・権限], [招待フロー／ロール（owner/admin/member）／メンバー割当。複数人運用の前提。Phase 3 で先送りした項目を回収], [#text(fill: cok, weight: "bold")[◎ 推奨]],
  [Phase 5\ 通知・連携], [プッシュ通知・現場内コミュニケーション。APNs/FCM 等の外部設定が必要でセットアップ比重が大きい], [○],
  [Phase 8\ 品質強化], [テスト網羅・クラッシュ監視・パフォーマンス。リリース品質づくり], [○（後半向き）],
)
#v(2pt)
#text(size: 9pt)[
  *推奨：Phase 7（組織・権限管理）。* 現状は単一ユーザー前提。実運用（複数人の現場）に踏み出すには、招待とロールが要。
  Phase 3 で意図的に外した「メンバー割当」もここで回収でき、機能の連続性が高い。着手時はこれまで同様
  *要件定義書 → 承認 → 実装仕様書 → 実装 → analyze/test/CI/実機 → 完了報告* の順で進めます。
]
