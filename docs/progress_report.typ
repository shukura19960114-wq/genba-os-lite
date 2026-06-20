// 現場OS Lite 開発進捗報告書（チーム共有用） — typst ソース
// 生成: typst compile docs/progress_report.typ "docs/現場OS_Lite_進捗報告_2026-06-21.pdf"

#set document(title: "現場OS Lite 開発進捗報告書", author: "開発チーム")
#set page(
  paper: "a4",
  margin: (x: 1.8cm, top: 1.8cm, bottom: 1.5cm),
  numbering: "1 / 1",
  footer: context [
    #set text(size: 8pt, fill: luma(130))
    #line(length: 100%, stroke: 0.4pt + luma(210))
    #v(2pt)
    現場OS Lite 開発進捗報告書 ・ 2026-06-21
    #h(1fr)
    #counter(page).display("1 / 1", both: true)
  ],
)
#set text(font: "Hiragino Sans", size: 9.5pt, lang: "ja")
#set par(leading: 0.72em, justify: true)

// ---- 配色 ----
#let cmain = rgb("#1f6feb")
#let cok   = rgb("#1a7f37")
#let cwip  = rgb("#bf8700")
#let ctodo = rgb("#57606a")

// ---- 状態バッジ ----
#let badge(t, c) = box(
  fill: c.lighten(82%), inset: (x: 5pt, y: 2pt), radius: 3pt, baseline: 2pt,
  text(fill: c.darken(8%), weight: "bold", size: 8pt, t),
)
#let DONE  = badge("完了", cok)
#let WIP   = badge("進行中", cwip)
#let TODO  = badge("未着手", ctodo)
#let LATER = badge("後回し", ctodo)

// ---- 見出しスタイル ----
#show heading.where(level: 1): it => block(below: 0.8em, above: 1.1em)[
  #set text(size: 13pt, weight: "bold", fill: cmain)
  #box(fill: cmain, width: 4pt, height: 0.95em, baseline: 0.12em, radius: 1pt)
  #h(6pt) #it.body
]
#show heading.where(level: 2): it => block(below: 0.5em, above: 0.8em)[
  #set text(size: 10.5pt, weight: "bold", fill: ctodo.darken(20%))
  #it.body
]

// ============================ 表紙ブロック ============================
#align(center)[
  #v(2pt)
  #text(size: 21pt, weight: "bold", fill: cmain)[現場OS Lite 開発進捗報告書]
  #v(4pt)
  #text(size: 10.5pt, fill: ctodo)[チーム共有用　／　2026年6月21日 時点]
]
#v(4pt)
#line(length: 100%, stroke: 1pt + cmain.lighten(35%))
#v(6pt)

// ============================ 進捗ハイライト ============================
#block(fill: cmain.lighten(93%), inset: 11pt, radius: 6pt, width: 100%, stroke: 0.5pt + cmain.lighten(55%))[
  #text(weight: "bold", fill: cmain.darken(5%))[■ 現在地（サマリ）] \
  #v(3pt)
  *Phase 1.0「基盤構築」がほぼ完了。* アプリの土台（サーバー接続・開発/本番の環境切替・
  画面の骨組み）を実装し、ソースコードを GitHub に保存、自動テスト（CI）も全項目グリーンを確認しました。
  残るは *iOS実機での起動確認のみ*。これが済めば Phase 1.0 完了 → 最初の機能（ログイン）開発に進みます。
]
#v(8pt)

// ============================ 1. プロダクト概要 ============================
= プロダクト概要

#table(
  columns: (auto, 1fr),
  stroke: none,
  inset: (x: 0pt, y: 2.5pt),
  [#text(fill: ctodo)[プロダクト]], [現場OS Lite（仮称）— 中小建設企業の現場業務をスマホで支援するアプリ],
  [#text(fill: ctodo)[対象ユーザー]], [建設現場の職人・監督],
  [#text(fill: ctodo)[対応端末]], [iOS / Android（モバイル中心。Webは当面対象外）],
  [#text(fill: ctodo)[開発規模]], [全10フェーズのロードマップ。現在は最初の土台（Phase 1.0）を構築中],
)

// ============================ 2. 全体ロードマップ ============================
= 全体ロードマップ（Phase 1 → ローンチ）

#table(
  columns: (auto, 1fr, auto),
  stroke: 0.5pt + luma(215),
  inset: (x: 7pt, y: 5pt),
  align: (left, left, center + horizon),
  fill: (_, row) => if row == 0 { cmain.lighten(86%) } else { white },
  table.header(
    [#text(weight: "bold", size: 9pt)[Phase]],
    [#text(weight: "bold", size: 9pt)[内容]],
    [#text(weight: "bold", size: 9pt)[状態]],
  ),
  [*1. 基盤＋初期機能*], [アプリの土台＋ログイン・現場一覧・写真管理], WIP,
  [#h(8pt)1.0 基盤構築], [サーバー接続・dev/prod切替・主要ライブラリ・CI・接続確認画面], WIP,
  [#h(8pt)1.1 認証/ログイン], [ログイン画面・権限管理（会社単位）], TODO,
  [#h(8pt)1.2 現場一覧], [自社の現場の一覧表示], TODO,
  [#h(8pt)1.3 写真管理], [現場写真の撮影・保存・アップロード], TODO,
  [*2. 日報機能*], [日報の作成・一覧・編集], TODO,
  [*3. 現場管理の拡充*], [現場の登録/編集/状態管理・メンバー割当], TODO,
  [*4. 写真の本格化*], [オフライン同期・アルバム/タグ・位置情報], TODO,
  [*5. 通知・連携*], [プッシュ通知・現場内コミュニケーション], TODO,
  [*6. 帳票・出力*], [報告書/写真台帳のPDF出力・共有], TODO,
  [*7. 組織・権限管理*], [招待フロー・ロール管理・管理画面], TODO,
  [*8. 品質強化*], [テスト網羅・クラッシュ監視・パフォーマンス], TODO,
  [*9. ベータ検証*], [TestFlight / Google Play 内部テスト配信], TODO,
  [*10. ストア公開*], [App Store / Google Play 申請・本番リリース], TODO,
)
#v(2pt)
#text(size: 8pt, fill: ctodo)[凡例：#DONE 完了　#WIP 進行中　#TODO 未着手]

#pagebreak()

// ============================ 3. Phase 1.0 完了工程 ============================
= Phase 1.0「基盤構築」— 完了した工程

土台づくりとして、以下を実装・検証しました。コードは自分のPCだけでなく、
GitHub上のまっさらな環境（CI）でも正常動作することを確認済みです。

#table(
  columns: (1fr, auto),
  stroke: 0.5pt + luma(215),
  inset: (x: 7pt, y: 5pt),
  align: (left, center + horizon),
  fill: (_, row) => if row == 0 { cok.lighten(88%) } else { white },
  table.header(
    [#text(weight: "bold", size: 9pt)[工程]],
    [#text(weight: "bold", size: 9pt)[状態]],
  ),
  [Supabase（サーバー）の開発用・本番用 2環境を作成・接続鍵を取得], DONE,
  [環境別設定（dev / prod の切替、接続情報の安全な管理）], DONE,
  [主要ライブラリの選定・導入（状態管理・画面遷移・モデル生成 等）], DONE,
  [アプリ構成（feature-first アーキテクチャ）の骨組みを整備], DONE,
  [「サーバー接続OK」確認画面の実装], DONE,
  [静的解析（コード品質チェック）エラー0], DONE,
  [自動テスト 6件すべて成功], DONE,
  [ソースコードを GitHub に保存（コミット & プッシュ）], DONE,
  [CI（GitHub Actions）の構築 — 保存のたびに自動でチェック], DONE,
  [CI をグリーン化（Analyze＋Test が自動で通る状態に）], DONE,
  [開発環境の不具合（日本語フォルダ名問題）を解消], DONE,
)

== Phase 1.0 完了までに残っている作業

#table(
  columns: (1fr, auto),
  stroke: 0.5pt + luma(215),
  inset: (x: 7pt, y: 5pt),
  align: (left, center + horizon),
  fill: (_, row) => if row == 0 { cwip.lighten(85%) } else { white },
  table.header(
    [#text(weight: "bold", size: 9pt)[残作業]],
    [#text(weight: "bold", size: 9pt)[状態]],
  ),
  [iOS のビルド設定（pod install、Xcode の環境構成・スキーム作成）], TODO,
  [iOS 実機／シミュレータで「接続OK」を目視確認], TODO,
  [（Android の実機起動確認は方針により後続フェーズへ）], LATER,
)
#v(3pt)
#text(size: 8.5pt, fill: ctodo)[
  ※ iOS を優先し、Android は後続フェーズで対応する方針です。そのため現時点では
  CI の自動チェックも「コード解析＋テスト」に絞っています（Android ビルド検証は着手時に追加）。
]

// ============================ 4. 次の工程 ============================
= 次の工程

#table(
  columns: (auto, 1fr),
  stroke: none,
  inset: (x: 0pt, y: 3pt),
  [#text(weight: "bold", fill: cmain)[STEP 1]], [iOS のビルド設定を行う（pod install → Xcode 構成 → スキーム作成）],
  [#text(weight: "bold", fill: cmain)[STEP 2]], [iOS で起動し「環境：dev／接続：OK」を確認 → *これで Phase 1.0 完了*],
  [#text(weight: "bold", fill: cmain)[STEP 3]], [Phase 1.1「認証／ログイン」の開発に着手],
)

// ============================ 5. 技術・インフラ構成 ============================
= 技術・インフラ構成

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(215),
  inset: (x: 7pt, y: 5pt),
  fill: (_, row) => if row == 0 { luma(243) } else { white },
  table.header(
    [#text(weight: "bold", size: 9pt)[項目]],
    [#text(weight: "bold", size: 9pt)[内容]],
  ),
  [フレームワーク], [Flutter 3.44.2（iOS / Android を1つのコードで開発）],
  [バックエンド], [Supabase — 開発用 `genba-os-dev` / 本番用 `genba-os-prod` の2環境],
  [コード管理], [GitHub リポジトリ `shukura19960114-wq/genba-os-lite`],
  [自動チェック], [GitHub Actions（CI）：コード解析＋テストを自動実行 — *現在グリーン*],
  [主要ライブラリ], [supabase_flutter / flutter_riverpod / go_router / freezed ほか],
)

== 補足：Supabase と GitHub の役割の違い

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(215),
  inset: (x: 7pt, y: 5pt),
  fill: (_, row) => if row == 0 { luma(243) } else { white },
  table.header(
    [#text(weight: "bold", size: 9pt)[サービス]],
    [#text(weight: "bold", size: 9pt)[役割]],
  ),
  [Supabase], [アプリのバックエンド。データの保存・ユーザー認証を担当。開発用と本番用で分離],
  [GitHub], [アプリのソースコードの保管庫＋自動チェック（CI）。プログラムそのものを管理],
)
#v(3pt)
#text(size: 8.5pt, fill: ctodo)[
  ※ 同じ1つのアプリ「現場OS Lite」を、この2つのサービスが役割分担して支えています（別プロジェクトではありません）。
]
