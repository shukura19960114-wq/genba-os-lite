# Phase 5 現場内コミュニケーション（現場連絡）要件定義書（MVP）

**作成日:** 2026-06-25　／　**対象:** Phase 5「通知・連携」
**決定済み方針（ユーザー選択）:** **アプリ内コミュニケーション中心**（Supabaseのみ・証明書不要）。**本物のプッシュ通知（APNs/FCM）は後回し**。
**補足:** Apple Developer Program は保有済み → 将来のプッシュ通知・ベータ配信（TestFlight）の前提は満たしている。

---

## 目的
現場ごとに**チーム内で連絡を取り合える**ようにする（職人⇄監督の情報共有）。
端末に届く本物のプッシュ通知は重い設定（APNs/FCM）が要るため後回しにし、まずは**アプリ内のメッセージ＋未読バッジ**で「連携」の価値を出す。これによりベータ配信に向けて機能面を進める。

## スコープ（実装する / 実装しない）
| 実装する（MVP） | 実装しない（後続・非対象） |
|---|---|
| **現場連絡（メッセージ）**：現場ごとのスレッドに投稿・一覧 | **本物のプッシュ通知**（APNs/FCM・証明書）※Apple Dev保有のため後続で追加可 |
| 投稿者名（メール）・日時の表示 | 個人間DM・グループDM |
| **未読バッジ**：現場一覧に「新着」表示／開くと既読化 | 既読者一覧・タイプ中表示・リアクション・メンション |
| 自社・会社単位の閲覧（既存RLS流儀） | 添付（画像は既存の写真機能で対応）・編集/削除 |
| | リアルタイム自動更新（Supabase Realtime）※後続で追加可 |
| | 担当者(site_members)限定配信（閲覧は会社単位のまま） |

> 「通知」は**アプリ内未読バッジ**で表現。端末プッシュは Apple Developer 設定が必要なため別タスク（保有済みなので後続で着手可能）。

---

## 1. ユーザーストーリー
1. 監督として、現場ごとに「明日は8時集合」等の**連絡を投稿**し、メンバーに共有したい。
2. 職人として、自分の関わる現場の**連絡を読み**、返信（投稿）したい。
3. 現場一覧で、**新しい連絡がある現場に「新着」バッジ**が出てほしい。開けば既読になる。
4. 引き続き**自社のデータのみ**（会社単位のRLS維持）。

## 2. DB変更（マイグレーション `0006_site_posts.sql` を dev に適用）
既存の流儀（`company_id default current_company_id()` / `created_by default auth.uid()` / 会社単位RLS）に合わせる。
1. **`site_posts`**：`id / company_id(default current_company_id()) / site_id(FK sites) / author_id(default auth.uid()) / body / created_at`。
   - RLS：select/insert は `company_id = current_company_id()`（会社の誰でも閲覧・投稿可）。update/delete は本フェーズ非対象（ポリシーは置かない＝不可）。
2. **`site_post_reads`**：`user_id(default auth.uid()) / site_id / last_read_at`、PK=(user_id, site_id)。RLS：自分の行のみ。
3. **`mark_site_read(p_site_id)`**（RPC）：自分の既読時刻を upsert（現在時刻）。
4. **`site_unread_counts()`**（RPC）：現在ユーザーの「現場ごと未読件数」を返す（last_read_at より新しい投稿数。**自分の投稿は数えない**）。
   - インデックス：site_posts(site_id, created_at)。

## 3. 画面一覧
| 画面 | 区分 | 主な要素 |
|---|---|---|
| 現場連絡（S-Messages） | 追加 | 現場のメッセージ一覧（時系列）＋下部に入力欄。開いたら既読化。投稿者名・日時 |
| 現場詳細（既存） | 変更 | 「連絡」への導線 ListTile（日報の隣） |
| 現場一覧（既存） | 変更 | 各現場タイルに**未読バッジ**（新着件数） |

> 新規画面は **現場連絡** の1つ。現場詳細・現場一覧は導線/バッジの追加のみ。

## 4. Repository / Service 構成
- **PostRepository（新規）**：`listBySite(siteId)`（時系列）／`create(siteId, body)`／`markRead(siteId)`（RPC）／`unreadCounts()`（RPC）。
- `Post` モデル（freezed）：id / siteId / authorId / authorEmail（埋め込み）/ body / createdAt。
- 既存 `sites` 一覧（`sitesListProvider`）に未読数を組み合わせて表示（一覧側で `unreadCounts` を併用）。

## 5. Riverpod 構成
- `sitePostsProvider.family(siteId)`：現場のメッセージ一覧。投稿成功で invalidate。
- `unreadCountsProvider`：`Map<siteId, count>`。現場一覧で watch。既読化・投稿で invalidate。
- **PostController（autoDispose）**：`send(siteId, body)`（投稿→一覧/未読 invalidate）／`markRead(siteId)`（開いた時）。

## 6. 権限・ロール
- 閲覧・投稿は**会社の全メンバー可**（コミュニケーションは全員に開く）。owner/admin 限定にはしない。
- 編集・削除は本フェーズ非対象（投稿は残る）。
- 権限ゲートは不要（会社単位RLSで十分）。

## 7. 完了条件
1. 現場ごとに連絡を投稿・閲覧できる（投稿者・日時付き）。
2. 現場一覧に未読バッジが出て、開くと消える（既読化）。
3. 会社単位のRLS維持（自社のみ）。
4. analyze成功 / test成功 / dev実機確認。

## 8. テスト条件
- **PostController（Fake Repository）**：`send` 成功（true）/失敗（false・エラー）。`markRead` 呼び出し。
- **Post.fromJson**：埋め込み author（profiles.email）を読む。
- **unreadCounts** のパース（site_id→count）。
- 既存73件は緑のまま。RLS/RPCの実強制は dev実機＋Supabaseで確認。

---

## 実装順（段階・成果物はPhase 5一括）
- **5a メッセージ**：0006 適用、PostRepository/PostController、現場連絡画面、現場詳細の導線。
- **5b 未読バッジ**：unreadCounts/markRead、現場一覧バッジ、開封で既読化。

## 留意点・ベータへの道筋
- **新規依存なし**（supabase_flutter の from/rpc を使用）。**service_role 不使用**。
- **DB適用**：`0006_site_posts.sql` を dev で実行（prod は本番化時）。**コード変更前に承認をお願いします。**
- 承認後、`5a` の**実装仕様書（最小工数）**を作成してから着手（Phase 2〜7 と同じ流れ）。
- **ベータ配信（TestFlight）**：Apple Developer 保有済みのため、Phase 5 完了後に「**ベータ準備フェーズ**（署名・アイコン・ビルド番号・TestFlight アップロード手順）」を別途進められる。プッシュ通知も同アカウントで後続追加可能。
