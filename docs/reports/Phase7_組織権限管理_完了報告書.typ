// Phase 7 組織・権限管理 — 完了報告書（チーム共有用）— typst
// 生成: typst compile docs/reports/Phase7_組織権限管理_完了報告書.typ docs/reports/Phase7_組織権限管理_完了報告書.pdf

#set document(title: "Phase 7 組織・権限管理 完了報告書", author: "開発チーム")
#set page(
  paper: "a4",
  margin: (x: 1.7cm, top: 1.7cm, bottom: 1.4cm),
  numbering: "1 / 1",
  footer: context [
    #set text(size: 8pt, fill: luma(130))
    #line(length: 100%, stroke: 0.4pt + luma(210))
    #v(2pt)
    現場OS Lite ・ Phase 7 組織・権限管理 完了報告書 ・ 2026-06-25
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
  #text(size: 20pt, weight: "bold", fill: cmain)[Phase 7 組織・権限管理 完了報告書]
  #v(3pt)
  #text(size: 11pt)[現場OS Lite ／ サインアップ・招待コード・ロール・メンバー管理・現場の担当割当]
  #v(4pt)
  #text(size: 10pt, fill: ctodo)[作成日：2026年6月25日　／　目的：会社（テナント）単位で安全に複数人運用できる]
]
#v(3pt)
#line(length: 100%, stroke: 1pt + cmain.lighten(35%))
#v(5pt)

#block(fill: cok.lighten(92%), inset: 10pt, radius: 6pt, width: 100%, stroke: 0.5pt + cok.lighten(55%))[
  #text(weight: "bold", fill: cok.darken(8%))[結論：Phase 7 完了 ✅（実装・テスト・CI・dev実機 すべてクリア）] \
  #v(2pt)
  「単一ユーザー前提」から「*チームで使えるアプリ*」へ移行。アプリ内サインアップ、招待コードでの会社参加、
  ロール（owner/admin/member）と権限ゲート、メンバー管理、現場の担当割当を追加。
  `flutter analyze`=*No issues* ／ `flutter test`=*73件 全合格* ／ iOSビルド成功 ／ *CI 緑（7a/7b/7c）*。
  *dev実機で一連の流れ（サインアップ→会社作成→招待→ロール変更→担当割当）を確認*。
  セキュリティ上の既存の穴（自己昇格）も本フェーズで封鎖。
]
#v(5pt)

= 1. 実装した機能
#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(cmain),
  table.header(th("機能"), th("内容")),
  [サインアップ（7a）], [アプリ内でメール＋パスワード新規登録。登録後はホームで会社参加/作成へ誘導。],
  [会社に参加 / 作成（7a）], [①招待コード入力で参加　②会社を新規作成して自分が owner。会社未所属はホーム内で分岐表示。],
  [ロール＋権限ゲート（7a）], [owner / admin / member。管理操作は UI で出し分け＋ DB（RLS/RPC）でも強制。],
  [メンバー管理（7b）], [自社メンバー一覧。owner/admin が member⇄admin を変更（自分・owner は対象外）。],
  [招待コード（7b）], [owner/admin が発行（付与ロール選択）・コピー・失効。8桁・期限7日。],
  [現場の担当割当（7c）], [現場詳細の「担当メンバー」。owner/admin が自社メンバーを割当/解除。閲覧は会社単位のまま。],
)

= 2. スコープ（実装した / しない）
#table(columns: (1fr, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: (col, row) => if row == 0 { (cok, cwarn).at(col).lighten(86%) } else { white },
  table.header(th("実装した（MVP）"), th("非対象（後続・対象外）")),
  [サインアップ／会社参加（招待コード）／会社作成], [メンバーの除名（会社からの削除）],
  [ロール owner/admin/member ＋権限ゲート], [owner の付替え（最後のowner事故を防止）],
  [メンバー一覧・ロール変更（member⇄admin）], [確認メールの高度化（dev は確認OFF前提）],
  [招待コードの発行・失効], [「担当現場のみ閲覧」へのRLS厳格化（会社単位の閲覧は維持）],
  [現場の担当メンバー割当（site_members）], [ロールによる 現場/日報/写真 の編集制限（全員可を維持）],
)

= 3. DB変更（マイグレーション 0005_org_roles.sql・dev 適用済み）
#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 6pt, y: 4.5pt),
  fill: headfill(cmain),
  table.header(th("対象"), th("内容")),
  [関数], [`current_role()`（RLS再帰回避・definer）],
  [ポリシー修正], [*profiles 自己更新で company_id / role を変更不可*（旧値一致を要求）＝ 自己昇格の穴を封鎖],
  [テーブル], [`company_invites`（招待コード）／`site_members`（現場の担当割当）＋ 各 RLS],
  [RPC（definer）], [`redeem_invite`（参加）／`create_company`（作成→owner）／`set_member_role`（ロール変更）],
)
#v(2pt)
#text(size: 8.5pt, fill: ctodo)[
  ※ 会社割当・ロール変更は security definer RPC からのみ実行可能。クライアントから直接 company_id/role は書けない。
  ※ prod は本番化時に 0001〜0005 を順に適用（dev は適用済み）。
]

= 4. セキュリティ設計（要点）
- *自己昇格の封鎖*：従来 `profiles` の自己更新で role/company を自由に変えられたが、`with check` で旧値一致を要求し封鎖。会社割当・ロール変更は definer RPC 経由のみ。
- *二重の権限制御*：UI でボタンを出し分け（owner/admin のみ）＋ RLS/RPC で DB 強制。member が API を直接叩いても変更不可。
- *最後のowner保護*：owner は変更対象外・自分のロールは変更不可 → owner が消える事故を構造的に回避。
- *マルチテナント維持*：すべて会社単位（`current_company_id()`）。招待コードは自社のみ発行・参加は会社未所属者のみ。

= 5. 追加・変更ファイル（主なもの）
#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 6pt, y: 4.5pt),
  fill: headfill(luma(180)),
  table.header(th("区分"), th("ファイル")),
  [追加（org）],
  [`org/data/`：org_repository・invite(.dart＋モデル)・invite_repository・member_repository ／ `org/application/`：join_controller・members_providers・member_controller・invite_controller ／ `org/presentation/`：join_company_view・members_screen],
  [追加（auth/sites）],
  [`auth/application/current_profile_provider.dart`・`auth/presentation/signup_screen.dart` ／ `sites/data/site_member_repository.dart`・`sites/application/site_member_controller.dart`],
  [追加（DB）], [`supabase/migrations/0005_org_roles.sql`],
  [変更],
  [auth_repository(signUp)・auth_controller(signUp)・auth_providers ／ login_screen(登録導線) ／ home_screen(会社分岐＋メンバー管理導線) ／ site_detail_screen(担当メンバー) ／ app_routes・app_router(/signup・/members・authRedirect)],
  [テスト],
  [追加：join/member/invite/site_member の各Controller＋モデル ／ 変更：auth_redirect(signup)・auth_controller(signUp)・auth fakes],
)

#pagebreak()

= 6. 品質チェック結果
#table(columns: (auto, auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(cok),
  table.header(th("項目"), th("結果"), th("内容")),
  [`flutter analyze`], [#text(fill: cok, weight: "bold")[No issues]], [警告・エラー0],
  [`flutter test`], [#text(fill: cok, weight: "bold")[73 / 73 緑]], [Phase 7 で新規21件（7a 10＋7b 7＋7c 4）。既存52件も緑],
  [iOSビルド], [#text(fill: cok, weight: "bold")[成功]], [`flutter build ios --simulator --flavor dev`（新規ネイティブ依存なし）],
  [CI（GitHub Actions）], [#text(fill: cok, weight: "bold")[緑]], [7a `727bec4`／7b `a56197b`／7c `44001ed`（build_runner→analyze→test）],
  [dev実機], [#text(fill: cok, weight: "bold")[確認済み]], [サインアップ→会社作成／招待発行→別アカ参加／ロール変更／担当割当（ユーザー確認 2026-06-25）],
)
#v(3pt)
*新規テストの内訳（21件）*
- 7a：authRedirect(signup 2)・AuthController.signUp(2)・JoinController(4)・orgErrorMessage(2)
- 7b：MemberController(2)・InviteController(3)・Invite.isActive(2)
- 7c：SiteMemberController(3)・AssignedMember.fromJson(1)

= 7. 完了条件チェック
#table(columns: (auto, 1fr, auto), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(cok),
  table.header(th("#"), th("条件"), th("判定")),
  [1], [サインアップできる], [#text(fill: cok)[✅]],
  [2], [招待コードで会社に参加できる], [#text(fill: cok)[✅]],
  [3], [会社を新規作成して owner になれる], [#text(fill: cok)[✅]],
  [4], [owner/admin がロールを member⇄admin に変更できる], [#text(fill: cok)[✅]],
  [5], [owner/admin が現場に担当メンバーを割当/解除できる], [#text(fill: cok)[✅]],
  [6], [自己昇格不可（直接APIで role/company を書き換え不可）], [#text(fill: cok)[✅]],
  [7], [会社単位のRLS維持（自社データのみ）], [#text(fill: cok)[✅]],
  [8], [analyze / test / CI / dev実機], [#text(fill: cok)[✅]],
)

= 8. 完了判定
#block(fill: cok.lighten(92%), inset: 10pt, radius: 6pt, width: 100%, stroke: 0.5pt + cok.lighten(55%))[
  *Phase 7 は完了。* 実装・自動テスト（73件）・CI・iOSビルド・dev実機確認 すべてクリア。
  migration 0005 を dev に適用済み。複数人運用の土台（参加・ロール・担当割当）が整い、
  顧客に「チームで使える」状態を提示できる。prod 化時に 0005 を適用すれば本番でも利用可能。
]

= 9. ROADMAP 更新内容
- Phase 7（組織・権限管理）を *⬜ → ✅完了*（2026-06-25）。
- ★現在地を *「Phase 1〜4 ＋ 6 ＋ 7 完了」* に更新。残るは Phase 5（通知・連携）と 8〜10。
- Phase 5 は *飛ばし中* と明記（APNs/FCM の証明書設定が必要なため後着手）。
- 本番化前の残：prod へ 0001〜0004 ＋ *0005* を順に適用。

= 10. 次フェーズの提案
#table(columns: (auto, 1fr, auto), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(cmain),
  table.header(th("候補"), th("内容・狙い"), th("推奨度")),
  [Phase 8\ 品質強化], [テスト網羅・クラッシュ監視・パフォーマンス・アクセシビリティ。リリース品質づくり。外部設定が軽い], [#text(fill: cok, weight: "bold")[◎ 推奨]],
  [Phase 5\ 通知・連携], [飛ばし中。プッシュ通知は APNs/FCM の証明書設定が重い。まず「現場内お知らせ/コメント」等の軽い範囲から始めると着手しやすい], [○],
  [ベータ準備\ (Phase 9寄り)], [TestFlight 配信で実機ベータ。実利用フィードバックを得る], [○],
)
#v(2pt)
#text(size: 9pt)[
  *推奨：Phase 8（品質強化）または Phase 5 の軽量スコープ。* 主要機能（現場/日報/写真/帳票/組織）が揃ったため、
  次は「品質を固めて配信へ」か「飛ばした通知を軽い範囲で回収」のどちらか。Phase 5 を選ぶ場合は、
  証明書設定の要否で重さが変わるため *要件定義の前にスコープ相談* を推奨。
  いずれも着手時は *要件定義書 → 承認 → 実装仕様書 → 実装 → analyze/test/CI/実機 → 完了報告* の順で進めます。
]
