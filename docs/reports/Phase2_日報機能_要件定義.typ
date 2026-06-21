// Phase 2 日報機能 要件定義書（MVP）— typst ソース
// 生成: typst compile docs/reports/Phase2_日報機能_要件定義.typ docs/reports/Phase2_日報機能_要件定義.pdf

#set document(title: "Phase 2 日報機能 要件定義書（MVP）", author: "開発チーム")
#set page(
  paper: "a4",
  margin: (x: 1.7cm, top: 1.7cm, bottom: 1.4cm),
  numbering: "1 / 1",
  footer: context [
    #set text(size: 8pt, fill: luma(130))
    #line(length: 100%, stroke: 0.4pt + luma(210))
    #v(2pt)
    現場OS Lite ・ Phase 2 日報機能 要件定義書 ・ 2026-06-21
    #h(1fr)
    #counter(page).display("1 / 1", both: true)
  ],
)
#set text(font: "Hiragino Sans", size: 9.5pt, lang: "ja")
#set par(leading: 0.72em, justify: true)

#let cmain = rgb("#1f6feb")
#let cok   = rgb("#1a7f37")
#let cwarn = rgb("#bf3e3e")
#let ctodo = rgb("#57606a")
#let th(s) = text(weight: "bold", size: 9pt, s)
#let headfill(c) = (_, row) => if row == 0 { c.lighten(86%) } else { white }
#let mono(s) = raw(s)

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
  #text(size: 20pt, weight: "bold", fill: cmain)[Phase 2 日報機能 要件定義書（MVP）]
  #v(4pt)
  #text(size: 11pt)[現場OS Lite]
  #v(4pt)
  #text(size: 10pt, fill: ctodo)[作成日：2026年6月21日　／　方針：MVP最優先・建設会社ヒアリングで検証できる最小構成]
]
#v(4pt)
#line(length: 100%, stroke: 1pt + cmain.lighten(35%))
#v(6pt)

= 1. 目的とスコープ

== 目的
現場ごとに「その日の作業内容」をスマホで記録・閲覧できるようにする。
*建設会社へのヒアリングで「日報をスマホで付ける」体験を見せ、項目・運用の妥当性を検証する*ことがゴール。

== MVPの考え方
- 既存の Phase 1（認証・会社・現場）の上に、最小の「日報CRUD」を載せるだけ。
- 凝った機能（承認・PDF・集計）は入れない。*まず「書ける・見れる・直せる」*を最短で。
- データは既存同様 `company_id` + RLS で会社単位に隔離。日報は*現場（site）に紐づく*。

== やること / やらないこと
#table(columns: (1fr, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: (col, row) => if row == 0 { (cok, cwarn).at(col).lighten(86%) } else { white },
  table.header(th("やること（MVP）"), th("やらないこと（後続フェーズ）")),
  [日報の 作成 / 一覧 / 詳細 / 編集], [承認・ワークフロー（→ Phase 7）],
  [現場ごとの日報記録・閲覧], [PDF / 報告書出力（→ Phase 6）],
  [天候・作業人数などの基本項目], [日報への写真添付（→ Phase 4 と統合）],
  [自社のみ閲覧（RLS）], [集計・分析・グラフ],
  [作成者の記録（created_by）], [テンプレ / 音声入力 / オフライン同期],
)

= 2. ユーザーストーリー（MVP）

+ 監督として、現場を選んで*今日の作業内容を記録*したい（天候・人数も）。
+ 過去の日報を*新しい順に一覧*で振り返りたい。
+ 1件の日報を*詳細表示*したい。
+ 書き間違いを*後から編集*したい。
+ 自社の日報だけが見え、*他社の日報は見えない*。

= 3. 画面一覧

#table(columns: (auto, auto, 1fr, auto), stroke: 0.5pt + luma(215), inset: (x: 6pt, y: 5pt),
  fill: headfill(cmain),
  table.header(th("#"), th("画面"), th("主な要素"), th("遷移")),
  [S1], [日報一覧（現場別）],
  [その現場の日報を新しい順に表示（作業日・天候・作業内容の冒頭）。空/エラー・pull-to-refresh。作成FAB], [現場詳細→S1／行→S3／＋→S2],
  [S2], [日報作成],
  [作業日（既定=今日）・天候（選択）・作業内容（必須）・作業人数（任意）。保存（ローディング/エラー）], [保存成功→S1],
  [S3], [日報詳細],
  [作業日・現場名・天候・作業内容・作業人数・作成者・更新日時。編集ボタン], [編集→S4],
  [S4], [日報編集],
  [S2 と同じフォーム（既存値プリフィル）。更新ボタン], [更新成功→S3],
)
#v(3pt)
#text(size: 8.5pt, fill: ctodo)[
  導線：既存「現場詳細」に「日報」ボタンを追加し S1 へ。S2/S4 は同一フォームを共有（新規/編集をモード切替）。
  ＊任意（MVP外）: Home から全現場の日報フィード。MVPは現場別のみで十分。
]
#v(4pt)
#block(fill: luma(245), inset: 9pt, radius: 5pt, width: 100%)[
  #text(size: 8.5pt)[
*画面遷移* \
現場詳細(既存) ─[日報]→ S1 日報一覧 ─[＋]→ S2 日報作成 ─保存→ S1 \
#h(7.6em) └─[行タップ]→ S3 日報詳細 ─[編集]→ S4 日報編集 ─更新→ S3
  ]
]

#pagebreak()

= 4. DB設計

== テーブル: `reports`
#table(columns: (auto, auto, 1fr, 1.1fr), stroke: 0.5pt + luma(215), inset: (x: 6pt, y: 4.5pt),
  fill: headfill(luma(180)),
  table.header(th("カラム"), th("型"), th("制約 / 既定"), th("説明")),
  [`id`], [uuid], [PK, `gen_random_uuid()`], [日報ID],
  [`company_id`], [uuid], [NOT NULL, 既定 `current_company_id()`], [会社（RLS・自動付与）],
  [`site_id`], [uuid], [NOT NULL, FK→sites], [対象現場],
  [`report_date`], [date], [NOT NULL, 既定 `current_date`], [作業日],
  [`weather`], [text], [NULL可], [天候(sunny/cloudy/rainy/snowy)],
  [`work_content`], [text], [NOT NULL], [作業内容（本文・必須）],
  [`worker_count`], [int], [NULL可, CHECK ≥ 0], [作業人数],
  [`created_by`], [uuid], [既定 `auth.uid()`, FK→auth.users], [作成者],
  [`created_at`], [timestamptz], [NOT NULL, `now()`], [作成日時],
  [`updated_at`], [timestamptz], [NOT NULL, `now()`（トリガ更新）], [更新日時],
)
#v(2pt)
- インデックス: `(site_id, report_date desc)`（現場別・日付順）
- `updated_at` は BEFORE UPDATE トリガで自動更新

== RLS（自社のみ）
`company_id = current_company_id()` を select / insert / update / delete に適用（Phase 1.2 sites と同方針）。
insert は既定値＋ with check で自社固定。
*拡張ポイント*: 編集を「作成者のみ」に絞る場合は update を `created_by = auth.uid()` に変更。

== マイグレーション骨子（`supabase/migrations/0004_reports.sql` 想定）
#block(fill: luma(245), inset: 9pt, radius: 5pt, width: 100%)[
#text(size: 8pt)[#raw(lang: "sql",
"create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null default public.current_company_id()
    references public.companies(id) on delete cascade,
  site_id uuid not null references public.sites(id) on delete cascade,
  report_date date not null default current_date,
  weather text,
  work_content text not null,
  worker_count int check (worker_count >= 0),
  created_by uuid default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists reports_site_date_idx
  on public.reports(site_id, report_date desc);
alter table public.reports enable row level security;
-- select/insert/update/delete: company_id = current_company_id()
-- updated_at 自動更新トリガ")]
]
#text(size: 8.5pt, fill: ctodo)[※ 適用は dev / prod の SQL Editor で実行（Phase 1 と同じ運用）。]

= 5. 実装方針（既存パターン踏襲）

- *feature-first*: `lib/features/reports/{data, application, presentation}`
- `Report` モデル（freezed+json、snake_case、天候ラベル helper）
- `ReportRepository`（抽象interface + Supabase実装）: listBySite / fetch / create / update / delete
- Provider: `reportsBySiteProvider.family(siteId)` / `reportDetailProvider.family(id)`
- Controller: `ReportFormController`（AsyncNotifier、create/update、成功時に一覧 invalidate）
- テスト: モデル fromJson / FormController（fake repo）/ 一覧画面（fake repo）

= 6. 工数見積もり

#table(columns: (auto, 1fr, auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 6pt, y: 4.5pt),
  align: (center, left, center, left), fill: headfill(cmain),
  table.header(th("#"), th("タスク"), th("人日"), th("備考")),
  [1], [DBマイグレーション（reports+RLS+トリガ）], [0.25], [既存流用],
  [2], [Reportモデル(freezed)+天候helper], [0.25], [],
  [3], [ReportRepository（CRUD）], [0.5], [],
  [4], [Provider + Form(作成/編集)Controller], [0.5], [],
  [5], [日報一覧画面(S1)], [0.5], [sites一覧流用],
  [6], [作成/編集フォーム(S2/S4 共有)], [0.75], [日付/天候選択含む],
  [7], [日報詳細画面(S3)], [0.25], [],
  [8], [現場詳細への導線+ルーティング], [0.25], [],
  [9], [テスト（model/controller/list）], [0.5], [],
  [10], [analyze/test/ビルド/実機検証], [0.5], [],
  [11], [ドキュメント・SQL適用ガイド], [0.25], [],
  [—], [*合計*], [*約4.5*], [純粋な開発工数の目安],
)
#v(3pt)
#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(cok),
  table.header(th("本プロジェクト（AI実装）での実時間目安"), th("")),
  [🤖 AI実装（コード一式+テスト+analyze/test緑+push）], [約40〜60分],
  [🧑 あなたの作業（dev に 0004 SQL 適用 + 実機検証）], [約15分],
  [合計（壁時計）], [*約1時間*],
)

#pagebreak()

= 7. Phase 2 完了条件

#table(columns: (auto, 1fr, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(cok),
  table.header(th("#"), th("完了条件"), th("確認方法")),
  [1], [日報作成成功], [現場を選び入力→保存→一覧に出る],
  [2], [日報一覧表示成功], [現場別に新しい順で表示],
  [3], [日報詳細表示成功], [1件タップで全項目表示],
  [4], [日報編集成功], [既存値を直して更新→詳細反映],
  [5], [RLS確認], [company_id自動付与・自社のみ取得],
  [6], [analyze成功], [`flutter analyze` → No issues],
  [7], [test成功], [`flutter test` → 全件パス],
  [8], [dev実機検証], [iOSシミュレータで 1〜5 を目視確認],
)
#v(3pt)
#text(size: 8.5pt, fill: ctodo)[本番化前の運用タスク（任意・コード変更不要）: prod へ `0004_reports.sql` を適用。]

= 8. 建設会社ヒアリングで確認したいこと（検証観点）

MVPを見せながら、以下を聞いて次の優先度を決める：

+ *入力項目は過不足ないか？*（天候・作業人数は要る？ 翌日予定・使用機材・安全確認は要る？）
+ *写真は日報に紐づけたいか？*（現場単位の今の写真で足りるか／日報ごとに付けたいか → Phase 4 と統合判断）
+ *承認・確認フローは要るか？*（上長が承認する運用か → Phase 7）
+ *PDF/紙の体裁で出したいか？*（提出先がある → Phase 6 優先度UP）
+ *だれが書くか／編集権限*（職人本人 / 監督のみ / 作成者だけ編集 → RLS方針）
+ *1日1現場1枚か、複数枚か*（運用粒度）

#v(4pt)
#block(fill: cmain.lighten(92%), inset: 9pt, radius: 5pt, width: 100%)[
  #text(size: 8.5pt)[この回答で、Phase 2 の項目追加や Phase 3〜7 の優先順位を調整する。]
]

#v(8pt)
#line(length: 100%, stroke: 0.4pt + luma(210))
#v(2pt)
#text(size: 8pt, fill: ctodo)[関連: docs/ROADMAP.md（全体ロードマップ）／ 踏襲元 = Phase 1.2 現場一覧。]
