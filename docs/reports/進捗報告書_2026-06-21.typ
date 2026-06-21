// 現場OS Lite 進捗報告書（チーム共有用 / Phase 1 完了）— typst ソース
// 生成: typst compile docs/reports/進捗報告書_2026-06-21.typ docs/reports/進捗報告書_2026-06-21.pdf

#set document(title: "現場OS Lite 開発進捗報告書", author: "開発チーム")
#set page(
  paper: "a4",
  margin: (x: 1.7cm, top: 1.7cm, bottom: 1.4cm),
  numbering: "1 / 1",
  footer: context [
    #set text(size: 8pt, fill: luma(130))
    #line(length: 100%, stroke: 0.4pt + luma(210))
    #v(2pt)
    現場OS Lite 進捗報告書 ・ 2026-06-21
    #h(1fr)
    #counter(page).display("1 / 1", both: true)
  ],
)
#set text(font: "Hiragino Sans", size: 9.5pt, lang: "ja")
#set par(leading: 0.72em, justify: true)

#let cmain = rgb("#1f6feb")
#let cok   = rgb("#1a7f37")
#let cwip  = rgb("#bf8700")
#let ctodo = rgb("#57606a")
#let badge(t, c) = box(fill: c.lighten(82%), inset: (x: 5pt, y: 2pt), radius: 3pt, baseline: 2pt,
  text(fill: c.darken(8%), weight: "bold", size: 8pt, t))
#let DONE = badge("完了", cok)
#let TODO = badge("未着手", ctodo)
#let th(s) = text(weight: "bold", size: 9pt, s)
#let headfill(c) = (_, row) => if row == 0 { c.lighten(86%) } else { white }

#show heading.where(level: 1): it => block(below: 0.7em, above: 1.0em)[
  #set text(size: 13pt, weight: "bold", fill: cmain)
  #box(fill: cmain, width: 4pt, height: 0.95em, baseline: 0.12em, radius: 1pt)
  #h(6pt) #it.body
]
#show heading.where(level: 2): it => block(below: 0.45em, above: 0.7em)[
  #set text(size: 10.5pt, weight: "bold", fill: ctodo.darken(20%)); #it.body
]

// ===== 表紙 =====
#align(center)[
  #v(2pt)
  #text(size: 21pt, weight: "bold", fill: cmain)[現場OS Lite 開発進捗報告書]
  #v(4pt)
  #text(size: 10.5pt, fill: ctodo)[チーム共有用　／　2026年6月21日 時点]
]
#v(4pt)
#line(length: 100%, stroke: 1pt + cmain.lighten(35%))
#v(6pt)

// ===== サマリ =====
#block(fill: cok.lighten(93%), inset: 11pt, radius: 6pt, width: 100%, stroke: 0.5pt + cok.lighten(55%))[
  #text(weight: "bold", fill: cok.darken(8%))[■ ハイライト：Phase 1（基盤＋初期機能）完了 🎉] \
  #v(3pt)
  アプリの土台に加え、*ログイン → 現場の登録・一覧・詳細 → 現場写真の撮影/アップロード/表示* までが
  iOS実機（シミュレータ）で一通り動作することを確認しました。次は Phase 2（日報機能）に進みます。
  全体ロードマップ（Phase 1〜10）の進捗は *約25%* です。
]
#v(8pt)

= プロダクト概要

#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 4.5pt),
  fill: headfill(luma(180)),
  table.header(th("項目"), th("内容")),
  [プロダクト], [現場OS Lite（仮称）],
  [対象顧客], [中小建設企業（現場の職人・監督）],
  [目的], [建設現場の業務をスマホで支援。全10フェーズで段階的に開発],
  [対応端末], [iOS / Android（モバイル中心。Web は当面対象外）],
  [バックエンド], [Supabase（dev / prod の2環境、認証＋DB＋写真ストレージ）],
)

= 全体ロードマップ

#table(columns: (auto, 1fr, auto), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 4.5pt),
  align: (left, left, center + horizon), fill: headfill(cmain),
  table.header(th("Phase"), th("内容"), th("状態")),
  [*1. 基盤＋初期機能*], [土台・ログイン・現場・写真], DONE,
  [#h(8pt)1.0 基盤構築], [Supabase接続・dev/prod切替・CI], DONE,
  [#h(8pt)1.1 認証/ログイン], [Email+Password・権限(会社)管理], DONE,
  [#h(8pt)1.2 現場一覧], [現場の登録・一覧・詳細], DONE,
  [#h(8pt)1.3 写真管理], [現場写真の撮影・アップロード・表示], DONE,
  [*2. 日報機能*], [日報の作成・一覧・編集], TODO,
  [*3. 現場管理の拡充*], [編集/状態管理・メンバー割当], TODO,
  [*4. 写真の本格化*], [オフライン同期・アルバム/タグ], TODO,
  [*5. 通知・連携*], [プッシュ通知・現場内連絡], TODO,
  [*6. 帳票・出力*], [報告書/写真台帳のPDF出力], TODO,
  [*7. 組織・権限管理*], [招待・ロール・管理画面], TODO,
  [*8〜10*], [品質強化 / ベータ検証 / ストア公開], TODO,
)
#v(2pt)
#text(size: 8pt, fill: ctodo)[凡例：#DONE 完了　#TODO 未着手]

#pagebreak()

= Phase 1 で実装した機能

#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5.5pt),
  fill: headfill(cok),
  table.header(th("機能"), th("内容")),
  [認証 / ログイン],
  [Email + Password でログイン。会社（テナント）単位でデータを分離し、ログイン状態は
   端末に保存され再起動後も自動ログイン。未ログイン時はログイン画面へ自動誘導。],
  [現場管理],
  [現場の新規登録（現場名・住所）、一覧表示（ステータス付き）、詳細表示。
   自社の現場のみ表示（他社データは見えない）。],
  [写真管理],
  [現場ごとに写真をカメラ撮影またはフォトライブラリから追加し、クラウド保存・一覧表示。
   写真も会社単位で隔離（プライベート保管）。],
)
#v(3pt)
#text(size: 8.5pt, fill: ctodo)[
  ※ 全データは「会社ID＋アクセス制御(RLS)」で守られ、ログインユーザーは自社のデータのみ閲覧できます。
]

= 画面（iOS 実機確認）

#grid(columns: (1fr, 1fr), column-gutter: 24pt,
  align(center)[
    #image("images/p1_login.png", height: 8.2cm)
    #v(3pt) #text(size: 8.5pt, fill: ctodo)[① ログイン画面（未ログイン時に表示）]
  ],
  align(center)[
    #image("images/p1_site_photo.png", height: 8.2cm)
    #v(3pt) #text(size: 8.5pt, fill: ctodo)[② 現場詳細＋現場写真]
  ],
)

= 技術・インフラ / 品質

#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 4.5pt),
  fill: headfill(luma(180)),
  table.header(th("項目"), th("内容")),
  [フレームワーク], [Flutter 3.44.2（iOS / Android を単一コードで開発）],
  [バックエンド], [Supabase（認証 / DB / Storage）。dev・prod の2環境],
  [主要技術], [Riverpod（状態管理）/ GoRouter（画面遷移）/ Freezed（モデル）/ image_picker（写真）],
  [自動チェック], [GitHub Actions（CI）：保存のたびに コード解析＋テストを自動実行 — *現在グリーン*],
  [品質], [静的解析エラー 0 ／ 自動テスト *29件* パス ／ コミット 14件],
)

= 次の予定・運用メモ

#table(columns: (auto, 1fr), stroke: none, inset: (x: 0pt, y: 3pt),
  [#text(weight: "bold", fill: cmain)[次フェーズ]], [Phase 2「日報機能」（現場ごとに日報を作成・一覧・編集）],
  [#text(weight: "bold", fill: cwip)[本番化前]], [本番(prod)環境へDBスキーマを適用（開発環境で検証済み・コード変更不要）],
)

= 進捗率（KPI）

#table(columns: (1fr, auto), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  align: (left, center + horizon), fill: headfill(luma(180)),
  table.header(th("指標"), th("値")),
  [Phase 1（基盤＋初期機能）], [#text(weight: "bold", fill: cok)[100%（完了）]],
  [全体ロードマップ（Phase 1〜10）], [#text(weight: "bold", fill: cmain)[約25%]],
)
#v(6pt)
#let bar(ratio, col, label) = {
  grid(columns: (4.2cm, 1fr), column-gutter: 8pt, align: (left, horizon),
    text(size: 9pt, label),
    box(width: 100%, height: 13pt, fill: luma(232), radius: 3pt,
      align(left + horizon, box(width: ratio * 100%, height: 13pt, fill: col, radius: 3pt))),
  )
}
#bar(1.0, cok, [Phase 1])
#v(3pt)
#bar(0.25, cmain, [全体ロードマップ])

#v(10pt)
#line(length: 100%, stroke: 0.4pt + luma(210))
#v(2pt)
#text(size: 8pt, fill: ctodo)[本報告書は現場OS Lite リポジトリ `docs/reports/` 配下で管理されています。]
