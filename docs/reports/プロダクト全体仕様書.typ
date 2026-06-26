// 現場OS Lite プロダクト全体仕様書 — typst
// 生成: typst compile docs/reports/プロダクト全体仕様書.typ docs/reports/プロダクト全体仕様書.pdf

#set document(title: "現場OS Lite プロダクト全体仕様書", author: "開発チーム")
#set page(
  paper: "a4",
  margin: (x: 1.7cm, top: 1.7cm, bottom: 1.4cm),
  numbering: "1 / 1",
  footer: context [
    #set text(size: 8pt, fill: luma(130))
    #line(length: 100%, stroke: 0.4pt + luma(210))
    #v(2pt)
    現場OS Lite ・ プロダクト全体仕様書 ・ 2026-06-26
    #h(1fr)
    #counter(page).display("1 / 1", both: true)
  ],
)
#set text(font: "Hiragino Sans", size: 9.3pt, lang: "ja")
#set par(leading: 0.7em, justify: true)
#show raw.where(block: true): it => block(
  fill: luma(245), inset: 8pt, radius: 5pt, width: 100%, text(size: 8pt, it),
)
#set table(stroke: 0.5pt + luma(215), inset: (x: 6pt, y: 4.5pt))

#let cmain = rgb("#1f6feb")
#let cok = rgb("#1a7f37")
#let cwarn = rgb("#bf3e3e")
#let ctodo = rgb("#57606a")
#let th(s) = text(weight: "bold", size: 8.8pt, s)
#let headfill(c) = (_, row) => if row == 0 { c.lighten(86%) } else { white }

#show heading.where(level: 1): it => block(below: 0.55em, above: 0.95em)[
  #set text(size: 13pt, weight: "bold", fill: cmain)
  #box(fill: cmain, width: 4pt, height: 0.95em, baseline: 0.12em, radius: 1pt)
  #h(6pt) #it.body
]
#show heading.where(level: 2): it => block(below: 0.35em, above: 0.6em)[
  #set text(size: 10.5pt, weight: "bold", fill: ctodo.darken(20%)); #it.body
]

// ===== 表紙 =====
#align(center)[
  #v(4pt)
  #text(size: 22pt, weight: "bold", fill: cmain)[現場OS Lite]
  #v(2pt)
  #text(size: 15pt, weight: "bold")[プロダクト全体仕様書]
  #v(6pt)
  #text(size: 10.5pt, fill: ctodo)[中小建設企業の現場業務をスマホで支援するアプリ（Flutter + Supabase）]
  #v(2pt)
  #text(size: 9.5pt, fill: ctodo)[作成日：2026年6月26日　／　対象バージョン：1.0.0（ベータ準備中）]
]
#v(4pt)
#line(length: 100%, stroke: 1pt + cmain.lighten(35%))
#v(6pt)

#block(fill: cmain.lighten(94%), inset: 10pt, radius: 6pt, width: 100%, stroke: 0.5pt + cmain.lighten(55%))[
  #text(weight: "bold", fill: cmain.darken(5%))[このドキュメントについて] \
  #v(2pt)
  現状の実装に基づくプロダクト全体仕様。機能・画面・データモデル・権限・環境・品質・開発状況をまとめる。
  チーム共有／引き継ぎ／顧客説明用。詳細な進捗は `docs/ROADMAP.md`、各フェーズ仕様は `docs/PhaseX_*.md` を参照。
]

= 1. プロダクト概要
#table(columns: (auto, 1fr), fill: headfill(cmain),
  table.header(th("項目"), th("内容")),
  [プロダクト名], [現場OS Lite（genba_os_lite）],
  [対象ユーザー], [中小建設企業（現場で働く職人・監督）],
  [目的], [建設現場の業務（現場・日報・写真・帳票・連絡・組織管理）をスマホで一元的に支援する],
  [対応OS], [iOS（優先）/ Android。モバイル中心、Web は当面非対象],
  [バックエンド], [Supabase（認証 / PostgreSQL / Storage）。dev・prod の2環境],
  [認証方式], [Email + Password（アプリ内サインアップ・ログイン）],
  [配布], [TestFlight（ベータ準備中。Apple Developer 保有）],
)

== 提供価値（できること）
- 会社（テナント）単位で、現場・日報・写真・帳票・連絡を*安全に*管理（マルチテナント＋行レベルセキュリティ）。
- 招待コードで*チーム参加*、ロール（オーナー/管理者/メンバー）で*権限管理*。
- 日報・写真台帳を*PDF出力*して提出物にできる。
- 現場ごとに*連絡（メッセージ）*を共有、未読バッジで把握。

= 2. 技術スタック
#table(columns: (auto, auto, 1fr), fill: headfill(cmain),
  table.header(th("分類"), th("採用"), th("用途")),
  [フレームワーク], [Flutter / Dart (SDK ^3.12.2)], [モバイルUI・ロジック],
  [状態管理], [flutter_riverpod ^3.3.2], [AsyncNotifier / Provider（DI・テスト差替）],
  [ルーティング], [go_router ^17.3.0], [認証ガード付きルーティング],
  [バックエンドSDK], [supabase_flutter ^2.15.0], [Auth / Postgres / Storage / RPC],
  [モデル生成], [freezed ^3.2.5 / json_serializable], [イミュータブルモデル・JSON変換],
  [環境変数], [flutter_dotenv ^6.0.1], [.env.dev / .env.prod の読込],
  [写真], [image_picker ^1.2.2 / uuid ^4.5.3], [撮影・複数選択・Storageパス],
  [帳票], [pdf ^3.13.0 / printing ^5.15.0], [PDF生成・OS共有・日本語フォント],
  [日付], [intl ^0.20.2], [日付フォーマット],
  [アイコン], [flutter_launcher_icons ^0.14.4], [アプリアイコン生成（ベータ準備）],
)
#text(size: 8.5pt, fill: ctodo)[※ iOS プラグインは Swift Package Manager で解決（Podfile 不要）。service_role 鍵はアプリに含めない（anon/publishable のみ）。]

= 3. アーキテクチャ（feature-first）
```
lib/
├── main_dev.dart / main_prod.dart   # 環境別エントリポイント
├── bootstrap.dart                    # dotenv→AppConfig→Supabase初期化→runApp
├── app.dart                          # MaterialApp.router
├── core/      config / supabase / router / theme        # 横断インフラ
├── shared/    再利用UI・ヘルパー
└── features/<feature>/
    ├── presentation/  画面（ConsumerWidget。ロジック/Supabase直叩き禁止）
    ├── application/   Riverpod Provider / Notifier（状態・オーケストレーション）
    └── data/          repository（抽象+Supabase実装）+ freezedモデル
```
- 依存方向は *presentation → application → data* の一方向。
- *SupabaseClient に触れるのは data 層の repository だけ*（Provider で注入＝テストで差し替え可能）。
- フィーチャー：`auth / sites / reports / photos / export(帳票) / org(組織) / messages(連絡) / home / foundation`。

= 4. 環境構成（dev / prod フレーバー）
#table(columns: (auto, 1fr, 1fr), fill: headfill(cmain),
  table.header(th("項目"), th("dev"), th("prod")),
  [起動エントリ], [`lib/main_dev.dart`], [`lib/main_prod.dart`],
  [`--flavor`], [dev], [prod],
  [表示名], [現場OS Lite Dev], [現場OS Lite],
  [Bundle ID(iOS)], [com.example.genbaOsLite.dev #text(fill: cwarn, size: 7.5pt)[(本物に変更予定)]], [com.example.genbaOsLite #text(fill: cwarn, size: 7.5pt)[(本物に変更予定)]],
  [接続環境], [.env.dev（dev Supabase）], [.env.prod（prod Supabase）],
)
#text(size: 8.5pt, fill: ctodo)[起動: `flutter run --flavor dev -t lib/main_dev.dart`。dev/prod は Bundle ID が異なり同居インストール可。]

#pagebreak()

= 5. 機能仕様（ドメイン別）
== 5.1 認証・組織（auth / org）
- *サインアップ／ログイン*（Email+Password）。go_router の認証ガードで未ログインは `/login` へ。
- *会社参加・作成*：会社未所属ならホームで「招待コードで参加」or「会社を新規作成（owner化）」。
- *ロール*：owner / admin / member。管理操作（招待・ロール変更・担当割当）は owner/admin のみ（UI＋DBで強制）。
- *メンバー管理*：自社メンバー一覧、ロール変更（member⇔admin、自分・owner は対象外）。
- *招待コード*：owner/admin が発行（付与ロール選択・8桁・期限7日）・コピー・失効。

== 5.2 現場（sites）
- 現場の*一覧 / 作成 / 詳細 / 編集*。ステータス（進行中 / 完了 / 中止）。
- 現場詳細から 日報・連絡・担当メンバー・写真へ導線。
- *担当メンバー割当*（site_members）：owner/admin が自社メンバーを現場に割当/解除（閲覧は会社単位）。

== 5.3 日報（reports）
- 現場ごとの日報の*作成 / 一覧 / 詳細 / 編集*。
- 項目：作業日・天候（晴/曇/雨/雪）・作業内容・作業人数・作成者・更新日時。

== 5.4 写真（photos）
- 現場写真の*複数追加*（カメラ1枚 / ライブラリ複数）・アップロード（プライベートStorage）。
- *拡大ビューア*（スワイプ切替・ピンチズーム）・撮影日時表示・現場別*ギャラリー*・枚数表示。

== 5.5 帳票・PDF出力（export）
- *日報PDF*（1件をA4化→OS共有）・*写真台帳PDF*（3列グリッド＋現場名・撮影日時→OS共有）。
- 日本語フォントは実行時取得（`PdfGoogleFonts.notoSansJPRegular`）。共有は `Printing.sharePdf`。

== 5.6 現場連絡（messages）
- 現場ごとの*メッセージ*（投稿・時系列一覧、投稿者・日時）。
- *未読バッジ*：現場一覧に新着件数（自分の投稿は除外）、連絡を開くと既読化。
- ※ 端末プッシュ通知（APNs/FCM）は後続（Apple Developer 設定後に追加可能）。

= 6. 画面一覧
#table(columns: (auto, 1fr, auto), fill: headfill(cmain),
  table.header(th("画面"), th("役割"), th("主な操作")),
  [ログイン / サインアップ], [認証], [ログイン・新規登録],
  [会社に参加 / 作成], [会社未所属時（ホーム内）], [招待コード参加・会社作成],
  [ホーム], [起点], [プロフィール表示・各機能へ・（管理者）メンバー管理],
  [メンバー管理], [組織], [メンバー一覧・ロール変更・招待コード発行/失効],
  [現場一覧 / 作成], [現場], [一覧（未読バッジ）・新規作成],
  [現場詳細 / 編集], [現場], [詳細・ステータス変更・担当割当・各機能導線],
  [日報 一覧/作成/詳細/編集], [日報], [日報CRUD・PDF出力],
  [写真ギャラリー / ビューア], [写真], [複数追加・拡大・台帳PDF],
  [現場の連絡], [連絡], [メッセージ投稿・閲覧・既読],
  [接続確認], [保守], [Supabase接続の確認],
)

= 7. データモデル / DBスキーマ（Supabase / PostgreSQL）
全テーブルに *行レベルセキュリティ（RLS）*。会社判定は `current_company_id()`、ロール判定は `current_role()`（security definer）。
#table(columns: (auto, 1fr, auto), fill: headfill(cmain),
  table.header(th("テーブル"), th("主な列"), th("RLS方針")),
  [companies], [id, name, created_at], [自社のみ],
  [profiles], [id(=auth.users), company_id, email, role], [自分＋同一会社（自己昇格不可）],
  [sites], [id, company_id, name, address, status, created_at], [自社のみ CRUD],
  [photos], [id, site_id, company_id, path, created_at], [自社のみ（Storageもパス先頭=company_id）],
  [reports], [id, company_id, site_id, report_date, weather, work_content, worker_count, created_by, …], [自社のみ CRUD],
  [company_invites], [id, company_id, code, role, expires_at, revoked, …], [owner/admin・自社],
  [site_members], [site_id, profile_id, assigned_at, assigned_by], [閲覧=自社現場 / 変更=owner/admin],
  [site_posts], [id, company_id, site_id, author_id, body, created_at], [自社の全メンバー（閲覧・投稿）],
  [site_post_reads], [user_id, site_id, last_read_at], [自分のみ],
)
#v(2pt)
*主な関数 / RPC（security definer）*：`current_company_id()` / `current_role()` / `handle_new_user()`（プロフィール自動作成）/ `redeem_invite`（招待参加）/ `create_company`（会社作成→owner）/ `set_member_role`（ロール変更）/ `mark_site_read`（既読）/ `site_unread_counts`（未読集計）。
#v(2pt)
*Storage*：`photos`（プライベートバケット）。パス `{company_id}/{site_id}/{photo_id}.jpg`、表示は署名付きURL。
#v(2pt)
#text(size: 8.5pt, fill: ctodo)[マイグレーション：`supabase/migrations/0001_init_auth` 〜 `0006_site_posts`。SQL Editor で順に適用。]

#pagebreak()

= 8. 権限・ロールとセキュリティ
== ロール別の権限
#table(columns: (1fr, auto, auto, auto), fill: headfill(cok),
  table.header(th("操作"), th("owner"), th("admin"), th("member")),
  [現場 / 日報 / 写真 / 連絡 の閲覧・作成・編集], [✓], [✓], [✓],
  [メンバー一覧の閲覧], [✓], [✓], [✓],
  [招待コードの発行・失効], [✓], [✓], [—],
  [ロール変更（member⇔admin）], [✓], [✓], [—],
  [現場の担当メンバー割当・解除], [✓], [✓], [—],
  [メンバー除名・owner 付替え], [非対応], [非対応], [非対応],
)
== セキュリティ設計
- *マルチテナント*：全テーブル company_id ＋ RLS。自社データのみアクセス可。
- *自己昇格の防止*：profiles の自己更新で company_id / role を変更不可。会社割当・ロール変更は security definer RPC からのみ。
- *二重の権限制御*：UI で出し分け＋ DB（RLS/RPC）で強制。直接 API を叩いても権限外操作は不可。
- *最後の owner 保護*：owner は変更対象外・自分のロールは変更不可。
- *秘密情報*：service_role 鍵はアプリに含めない。`.env.dev/.env.prod` は Git 管理外。

= 9. 品質・CI・テスト
#table(columns: (auto, 1fr), fill: headfill(cmain),
  table.header(th("項目"), th("内容")),
  [静的解析], [`flutter analyze` = エラー0（No issues）],
  [テスト], [`flutter test` = *79件 全合格*（モデル・コントローラ・認証ガード等のユニット/ウィジェット）],
  [CI], [GitHub Actions：main への push / PR で build_runner → analyze → test を自動実行（実鍵不要）],
  [テスト方針], [repository を抽象化し Fake に差し替え。RLS/RPC の実強制は dev 実機＋Supabase で確認],
)

= 10. 開発状況（フェーズ別）
#table(columns: (auto, 1fr, auto), fill: headfill(cok),
  table.header(th("Phase"), th("内容"), th("状態")),
  [1.0–1.3], [基盤 / 認証 / 現場 / 写真], [#text(fill: cok)[✅ 完了]],
  [2], [日報], [#text(fill: cok)[✅ 完了]],
  [3], [現場管理の拡充（編集・ステータス）], [#text(fill: cok)[✅ 完了]],
  [4], [写真機能の本格化], [#text(fill: cok)[✅ 完了]],
  [6], [帳票・PDF出力], [#text(fill: cok)[✅ 完了]],
  [7], [組織・権限管理], [#text(fill: cwarn)[🔄 実装完了・DB(0005)適用待ち]],
  [5], [現場連絡（通知・連携）], [#text(fill: cwarn)[🔄 実装完了・DB(0006)適用待ち]],
  [ベータ], [TestFlight 配信準備], [#text(fill: cwarn)[🔄 準備中（アイコン済・Bundle ID/署名/アップロード）]],
  [8 / 9 / 10], [品質強化 / ベータ検証 / ストア公開], [#text(fill: ctodo)[⬜ 未着手]],
)
#text(size: 8.5pt, fill: ctodo)[
  ※ Phase 7・5 はコード・テスト・CI 完了済み。dev の Supabase に `0005`/`0006` を適用すると実機で有効になる（適用待ち）。
]

= 11. 今後の計画
- *最優先*：dev に `0005`→`0006` を適用し、招待/ロール/担当割当・連絡/未読を実機確認（Phase 7・5 のクローズ）。
- *ベータ準備*：本物の Bundle ID 確定 → 署名（Apple Developer チーム）→ prod へ 0001〜0006 適用＋本番鍵 → IPA ビルド → TestFlight アップロード → テスター招待。
- *将来拡張*：端末プッシュ通知（APNs/FCM）、Android 実機ビルド、品質強化（クラッシュ監視・テスト網羅）、ストア公開。

#v(6pt)
#align(center)[#text(size: 8.5pt, fill: ctodo)[— 以上。最新の詳細は docs/ROADMAP.md および各フェーズ仕様書を参照 —]]
