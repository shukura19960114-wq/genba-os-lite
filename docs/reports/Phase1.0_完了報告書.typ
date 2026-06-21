// Phase 1.0 完了報告書 — typst ソース
// 生成: typst compile docs/reports/Phase1.0_完了報告書.typ docs/reports/Phase1.0_完了報告書.pdf

#set document(title: "Phase 1.0 完了報告書 — 現場OS Lite", author: "開発チーム")
#set page(
  paper: "a4",
  margin: (x: 1.7cm, top: 1.7cm, bottom: 1.4cm),
  numbering: "1 / 1",
  footer: context [
    #set text(size: 8pt, fill: luma(130))
    #line(length: 100%, stroke: 0.4pt + luma(210))
    #v(2pt)
    Phase 1.0 完了報告書 ・ 現場OS Lite ・ 2026-06-21
    #h(1fr)
    #counter(page).display("1 / 1", both: true)
  ],
)
#set text(font: "Hiragino Sans", size: 9.5pt, lang: "ja")
#set par(leading: 0.72em, justify: true)

#let cmain = rgb("#1f6feb")
#let cok   = rgb("#1a7f37")
#let ctodo = rgb("#57606a")
#let badge(t, c) = box(fill: c.lighten(82%), inset: (x: 5pt, y: 2pt), radius: 3pt, baseline: 2pt,
  text(fill: c.darken(8%), weight: "bold", size: 8pt, t))
#let OK = badge("✓", cok)

#show heading.where(level: 1): it => block(below: 0.7em, above: 1.0em)[
  #set text(size: 13pt, weight: "bold", fill: cmain)
  #box(fill: cmain, width: 4pt, height: 0.95em, baseline: 0.12em, radius: 1pt)
  #h(6pt) #it.body
]
#show heading.where(level: 2): it => block(below: 0.45em, above: 0.7em)[
  #set text(size: 10.5pt, weight: "bold", fill: ctodo.darken(20%)); #it.body
]
#let th(s) = text(weight: "bold", size: 9pt, s)
#let headfill(c) = (_, row) => if row == 0 { c.lighten(86%) } else { white }

// ===== 表紙 =====
#align(center)[
  #v(3pt)
  #text(size: 22pt, weight: "bold", fill: cmain)[Phase 1.0 完了報告書]
  #v(3pt)
  #text(size: 13pt)[現場OS Lite]
  #v(6pt)
  #box(fill: cok.lighten(82%), inset: (x: 10pt, y: 4pt), radius: 4pt,
    text(fill: cok.darken(8%), weight: "bold")[ステータス： ✅ 完了])
  #v(3pt)
  #text(size: 10pt, fill: ctodo)[作成日：2026年6月21日　／　対象：Phase 1.0（基盤構築）]
]
#v(4pt)
#line(length: 100%, stroke: 1pt + cmain.lighten(35%))
#v(4pt)

= 1. プロジェクト概要

#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(luma(180)),
  table.header(th("項目"), th("内容")),
  [プロダクト], [現場OS Lite（仮称）],
  [対象顧客], [中小建設企業（現場で働く職人・監督）],
  [開発目的], [建設現場の業務をスマホで支援するアプリ。全10フェーズの開発ロードマップの土台（基盤）から構築する。],
  [プラットフォーム], [iOS / Android（モバイル中心。Web は当面対象外）],
  [バックエンド], [Supabase（dev / prod の2環境）],
)

= 2. Phase 1.0 の目標

Phase 1.0 は「機能」ではなく、以降のすべての機能が乗る *土台（基盤）* を作ることを目標とした。

- *基盤構築* — アプリの起動処理・設定・画面骨格の整備
- *dev / prod 環境分離* — 開発用と本番用で接続先・アプリを完全に分ける
- *CI 構築* — コードを保存するたびに自動で品質チェックが走る仕組み
- *Git 管理* — ソースコードを GitHub で安全に管理
- *Flutter 基盤構築* — feature-first アーキテクチャ・状態管理・ルーティングの確立

= 3. 完了内容

== 3-1. 技術構成

#table(columns: (auto, auto, auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 6pt, y: 5pt),
  fill: headfill(cmain),
  table.header(th("区分"), th("技術"), th("バージョン"), th("役割")),
  [フレームワーク], [Flutter], [3.44.2], [iOS / Android を単一コードで開発],
  [バックエンド], [Supabase (supabase_flutter)], [^2.15.0], [DB・認証・APIキー（dev/prod 2環境）],
  [状態管理], [Riverpod (flutter_riverpod)], [^3.3.2], [アプリ状態のオーケストレーション],
  [ルーティング], [GoRouter (go_router)], [^17.3.0], [画面遷移・認証リダイレクト],
  [モデル生成], [Freezed], [^3.2.5], [イミュータブルなデータモデル生成],
  [CI/CD], [GitHub Actions], [—], [push/PR ごとの自動 analyze + test],
)

== 3-2. 実施内容

#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(cmain),
  table.header(th("実施項目"), th("内容")),
  [Supabase dev/prod 構築], [開発用・本番用の2プロジェクトを作成し、接続URL・公開鍵を取得],
  [環境変数管理], [`.env.dev` / `.env.prod` で接続情報を分離。Git管理外とし `.env.example` のみ追跡],
  [feature-first 構成], [`core / shared / features` の3層。依存方向は presentation → application → data の一方向],
  [CI 構築], [GitHub Actions で analyze + test を自動実行（実鍵不要・接続テストなし）],
  [テスト構築], [ユニット/ウィジェットテスト 6件],
  [iOS 起動確認], [iOSシミュレータ（iPhone 17 Pro）で起動し「接続OK」を目視確認],
  [Flavor 対応], [iOS Build Configuration 9種・Android productFlavor を整備し dev/prod を分離],
  [Scheme 対応], [共有Scheme `dev` / `prod` を作成し、各ビルドアクションに対応Configを割当],
)

= 4. 成果

#table(columns: (auto, auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  align: (left, center + horizon, left), fill: headfill(cok),
  table.header(th("成果項目"), th("判定"), th("証拠")),
  [dev 起動成功], OK, [`flutter run --flavor dev` → Xcode build done / Dart VM Service 起動],
  [prod 起動成功], OK, [`flutter run --flavor prod` → 同上],
  [Supabase 接続成功], OK, [dev・prod とも画面に「Supabase接続：OK」（接続先は別プロジェクト）],
  [analyze 成功], OK, [`flutter analyze` → No issues found!],
  [test 成功], OK, [`flutter test` → All tests passed!（6件）],
  [GitHub 管理完了], OK, [main に push 済み・CI success・作業ツリー差分なし],
)
#v(3pt)
#text(size: 8.5pt, fill: ctodo)[
  ※ dev/prod は Bundle ID が異なり（dev=`...genbaOsLite.dev` / prod=`...genbaOsLite`）1台に同居インストール可能。
  接続先 Supabase も別プロジェクト（URL・anon key とも相違を確認済み）。
]

#pagebreak()

= 5. 変更ファイル一覧（コミット履歴ベース）

== コミット履歴

#table(columns: (auto, auto, auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 6pt, y: 4pt),
  fill: headfill(luma(180)),
  table.header(th("#"), th("ハッシュ"), th("日付"), th("内容")),
  [1], [`c4d5469`], [06-19], [Initial Flutter setup],
  [2], [`74e5c0d`], [06-19], [Add Phase1 specification],
  [3], [`55f9a8a`], [06-21], [Phase 1.0: 基盤構築],
  [4], [`90ffa6c`], [06-21], [docs: ROADMAPを実態に同期],
  [5], [`8a5f276`], [06-21], [ci: Androidビルドを後回し方針に合わせCIから除外],
  [6], [`9a957b6`], [06-21], [docs: チーム共有用の進捗報告書PDFを追加],
  [7], [`f208e27`], [06-21], [Phase 1.0完了: iOS Flavor正式対応（dev/prod）],
)

== 変更規模（スキャフォールド `c4d5469` 以降）

#align(center)[#box(fill: cmain.lighten(92%), inset: 8pt, radius: 5pt,
  text(weight: "bold", fill: cmain.darken(5%))[52 ファイル変更　／　+4,825 行　／　−172 行])]
#v(4pt)

#table(columns: (auto, auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  align: (left, center + horizon, left), fill: headfill(luma(180)),
  table.header(th("カテゴリ"), th("ファイル数"), th("主なファイル")),
  [lib/（Dartコード）], [17], [`bootstrap.dart` `app.dart` `core/config/*` `core/supabase/*` `features/foundation/*`],
  [ios/（Flavor・Xcode設定）], [12], [`project.pbxproj` `xcschemes/{dev,prod}.xcscheme` `Flutter/*-{dev,prod}.xcconfig`],
  [設定（pubspec等）], [3], [`pubspec.yaml` `pubspec.lock` `analysis_options.yaml`],
  [docs/（ドキュメント）], [3], [`ROADMAP.md` `SETUP.md` 進捗報告PDF],
  [.github/（CI）], [1], [`workflows/ci.yml`],
  [test/（テスト）], [1], [`widget_test.dart`],
)

= 6. スクリーンショット（接続OK画面）

#grid(columns: (1fr, 1fr), column-gutter: 14pt,
  align(center)[
    #image("images/dev_connection_ok.png", height: 8.6cm)
    #v(2pt) #text(size: 8.5pt, fill: ctodo)[*dev* ／ 環境：dev ／ Supabase接続：OK]
  ],
  align(center)[
    #image("images/prod_connection_ok.png", height: 8.6cm)
    #v(2pt) #text(size: 8.5pt, fill: ctodo)[*prod* ／ 環境：prod ／ Supabase接続：OK]
  ],
)

#pagebreak()

= 7. 学び・課題

#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 6pt),
  fill: headfill(luma(180)),
  table.header(th("テーマ"), th("内容")),
  [Xcode Flavor 構成],
  [Flutter の iOS flavor は「`Debug-<flavor>` 等の Build Configuration」＋「flavor 名と一致する Scheme」が必須。
   Build Configuration を9種（基本3 × dev/prod の6）整備し、各 flavor に専用 xcconfig を紐付け、ターゲットの
   Bundle ID 直書きを削除して xcconfig 側の値（`.dev` サフィックス）が効くようにした。Xcode GUI ではなく
   `xcodeproj`（Ruby）で自動化し、再現性と安全性を確保。],
  [Scheme 管理],
  [共有Scheme（Shared）にしないと CI や他環境から見えないため `dev` / `prod` を Shared で作成。
   Scheme 名は `--flavor` の値と完全一致（大文字小文字含む）させる必要がある。],
  [SPM 採用（CocoaPods 不採用）の理由],
  [本 Flutter 構成では iOS プラグイン解決に *Swift Package Manager (SPM)* が使われ `Podfile` が生成されなかった。
   当初の CocoaPods 前提の手順は不要と判明。SPM は依存解決が速く `Podfile` / `Pods/` の管理が不要という利点がある。
   flavor xcconfig 側も `#include?`（条件付きインクルード）で Pods を参照しているため、Pods 不在でも安全に動作する。],
)

= 8. Phase 1.1 計画（次フェーズ）

*テーマ: 認証 / ログイン*

#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(cmain),
  table.header(th("項目"), th("内容")),
  [companies], [会社（テナント）テーブル。マルチテナントの起点],
  [profiles], [ユーザープロフィール。会社に紐付く],
  [RLS], [Row Level Security。`company_id` ＋ `current_company_id()` で自社データのみアクセス可に],
  [Auth], [Supabase Auth によるログイン画面。go_router で認証ガード（未ログインは `/login`、ログイン後は現場一覧へ）],
)

= 9. KPI

#table(columns: (1fr, auto), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 6pt),
  align: (left, center + horizon), fill: headfill(luma(180)),
  table.header(th("指標"), th("値")),
  [Phase 1.0 進捗率], [#text(weight: "bold", fill: cok)[100%（完了）]],
  [全体ロードマップ進捗率（Phase 1〜10）], [#text(weight: "bold", fill: cmain)[約10%（推定）]],
)
#v(6pt)

#let bar(ratio, col, label) = {
  grid(columns: (3.4cm, 1fr), column-gutter: 8pt, align: (left, horizon),
    text(size: 9pt, label),
    box(width: 100%, height: 13pt, fill: luma(232), radius: 3pt,
      align(left + horizon, box(width: ratio * 100%, height: 13pt, fill: col, radius: 3pt))),
  )
}
#bar(1.0, cok, [Phase 1.0])
#v(3pt)
#bar(0.10, cmain, [全体ロードマップ])

#v(10pt)
#line(length: 100%, stroke: 0.4pt + luma(210))
#v(2pt)
#text(size: 8pt, fill: ctodo)[本報告書は現場OS Lite リポジトリ `docs/reports/` 配下で管理されています。]
