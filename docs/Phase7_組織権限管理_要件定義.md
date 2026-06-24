# Phase 7 組織・権限管理 要件定義書（MVP）

**作成日:** 2026-06-25　／　**対象:** Phase 7「組織・権限管理」
**決定済みの方針（ユーザー選択）:** 招待は **招待コード方式**／**サイト担当割当（site_members）を含める**。
**前提（不変）:** アプリに **service_role は入れない**。よって管理者がアプリから直接ユーザーを作ることはできず、**招待は「新メンバー本人がサインアップして会社に参加」**する形になる。

---

## 目的
会社（テナント）単位で**安全に複数人運用**できるようにする。具体的には ①新メンバーの参加（招待コード）②ロール（owner/admin/member）と権限ゲート ③メンバー管理（一覧・ロール変更）④現場の担当メンバー割当。
これにより「単一ユーザー前提」から「**チームで使えるアプリ**」へ移行する。

## スコープ（実装する / 実装しない）
| 実装する（MVP） | 実装しない（後続・非対象） |
|---|---|
| **サインアップ画面**（メール＋パスワード新規登録） | メンバーの**除名**（会社からの削除）＝事故防止のため後続 |
| **会社に参加**（招待コード入力）／**会社を新規作成**（自分が owner） | **owner の付替え**（最後のownerが消える事故を防止）|
| **招待コード**の発行・失効（owner/admin） | メール送信・確認メールの高度化（dev は確認OFF前提） |
| **ロール**（owner/admin/member）＋権限ゲート（UI＋RLS） | 「担当現場のみ閲覧」へのRLS厳格化（**会社単位の閲覧は維持**） |
| **メンバー一覧**＋**ロール変更**（member⇄admin） | 現場/日報/写真の編集をロールで制限（**現状=全メンバー可を維持**） |
| **現場の担当メンバー割当**（site_members、割当/解除） | 監査ログ／複数会社の所属／通知 |

> 本フェーズは**これまでで最大**。DB変更（マイグレーション0005）の適用が必要。実装は **7a→7b→7c** の順で段階的に進め、各段で analyze/test/実機を回す（成果物は Phase 7 として一括）。

---

## 1. ユーザーストーリー
1. 新しい職人として、**アプリでサインアップ**し、親方からもらった**招待コード**を入れて会社に参加したい。
2. 親方（owner）として、**招待コードを発行**して職人に渡したい（LINE/口頭）。不要になったコードは**失効**したい。
3. owner/admin として、**メンバー一覧**を見て、信頼できる人を **admin に昇格**／元に戻したい。
4. owner/admin として、各**現場に担当メンバーを割り当て**たい（誰がどの現場か把握）。
5. 新規の会社として、**会社を作成**して自分が owner になり、使い始めたい。
6. 引き続き**自社データのみ**（会社単位のRLS維持）。担当外でも自社の現場は見える。

## 2. ロールと権限マトリクス
| 操作 | owner | admin | member |
|---|:--:|:--:|:--:|
| 現場/日報/写真の閲覧・作成・編集（既存） | ✓ | ✓ | ✓ |
| メンバー一覧の閲覧 | ✓ | ✓ | ✓ |
| 招待コードの発行・失効 | ✓ | ✓ | ✗ |
| ロール変更（member⇄admin、他人のみ） | ✓ | ✓ | ✗ |
| 現場の担当メンバー割当・解除 | ✓ | ✓ | ✗ |
| owner の付替え・メンバー除名 | ✗（非対象） | ✗ | ✗ |

- **自分自身のロールは変更不可**。**owner は変更対象外**（昇格先・降格元にしない）→「最後のowner」事故を構造的に回避。
- 権限は **UIゲート（ボタン出し分け）＋ RLS/RPC（DB強制）の二重**。memberがAPIを直接叩いても変更不可。

## 3. DB変更（マイグレーション `0005_org_roles.sql` を dev に適用）
**この適用はユーザーが Supabase ダッシュボードの SQL Editor で実行**（dev→後日prod）。冪等に記述。
1. **`current_role()`**（security definer）: ログイン中ユーザーの role を返す（RLSの再帰回避。`current_company_id()` と対）。
2. **profiles 更新ポリシーの強化**: 自己更新で **company_id / role を変更できない**よう差し替え（`with check` で旧値と一致を要求）。→ 自己昇格を防止。RPC（definer）は別途バイパス。
3. **`company_invites`** テーブル＋RLS: `id / company_id / code(一意) / role(member|admin) / created_by / created_at / expires_at / revoked`。select/insert/update(失効) は **owner/admin かつ自社**。
4. **`redeem_invite(code)`**（definer RPC）: 有効なコードなら、**会社未所属の本人**の profiles に company_id/role を設定。多重所属は拒否。
5. **`create_company(name)`**（definer RPC）: **会社未所属の本人**が会社を作成し owner になる。
6. **`set_member_role(target, role)`**（definer RPC）: caller が owner/admin かつ同一会社、target が自分でない・ownerでない、role∈{member,admin} のときのみ更新。
7. **`site_members`** テーブル＋RLS: `site_id / profile_id / assigned_at / assigned_by`（PK=site_id+profile_id）。select=自社の現場、insert/delete=**owner/admin かつ自社の現場・自社メンバー**。
8. インデックス（company_invites.code / company_invites.company_id / site_members.site_id）。

> **既存の穴の修正**：現状 `profiles_update_own` は自分の company_id/role を自由に変更可能（自己昇格の穴）。本フェーズで塞ぐ。

## 4. 画面一覧
| 画面 | 区分 | 主な要素 |
|---|---|---|
| サインアップ（S-Signup） | 追加 | メール・パスワード・（任意）招待コード。登録→セッション作成→ホームへ |
| ログイン（既存） | 変更 | 「新規登録はこちら」リンクを追加 |
| 会社に参加/作成（S-Join） | 追加 | **会社未所属**のとき表示。①招待コードで参加 ②会社を新規作成（owner）。ホーム内分岐で表示 |
| ホーム（既存） | 変更 | 会社未所属なら S-Join を表示。所属済みなら「メンバー管理」導線（owner/admin） |
| メンバー管理（S-Members） | 追加 | 自社メンバー一覧（メール・ロール）。ロール変更（owner/admin）。**招待コード**の発行/一覧/失効 |
| 現場詳細（既存） | 変更 | 「担当メンバー」セクション（一覧＋割当/解除。owner/admin のみ操作可） |

> 新規画面は **サインアップ・会社参加・メンバー管理** の3つ。現場詳細・ログイン・ホームは変更。

## 5. Repository / Service 構成
- **AuthRepository**：`signUp(email, password)` を追加（`supabase.auth.signUp`）。
- **OrgRepository（新規・data）**：`redeemInvite(code)` / `createCompany(name)`（RPC呼び出し `rpc(...)`）。
- **MemberRepository（新規・data）**：`listMembers()`（profiles を RLSで自社のみ）／`setMemberRole(targetId, role)`（RPC）。
- **InviteRepository（新規・data）**：`createInvite(role)`（コード生成→insert）／`listInvites()`／`revokeInvite(id)`。
- **SiteMemberRepository（新規・data）**：`listForSite(siteId)` / `assignableMembers(companyId)` / `assign(siteId, profileId)` / `unassign(siteId, profileId)`。
- 既存 `ProfileRepository.fetchCurrentProfile` を流用。`Profile` モデル（id/companyId/email/role）を流用。

## 6. Riverpod 構成
- **`currentProfileProvider`（新規・FutureProvider）**：`fetchCurrentProfile()`。各画面の**ロールゲート**（`.value?.role`）と会社未所属判定（`companyId == null`）に使用。`homeProfileProvider` はこれを watch する形に整理。
- **AuthController**：`signUp` を追加（既存パターン）。
- **JoinController（autoDispose）**：`joinWithCode(code)` / `createCompany(name)`。成功で `currentProfileProvider` を invalidate。
- **MemberController（autoDispose）**：`changeRole(targetId, role)`。成功でメンバー一覧 invalidate。
- **InviteController（autoDispose）**：`create(role)` / `revoke(id)`。
- **SiteMemberController（autoDispose）**：`assign` / `unassign`。成功で `siteMembersProvider(siteId)` invalidate。
- 一覧系は `FutureProvider(.family)`：`membersProvider` / `invitesProvider` / `siteMembersProvider(siteId)` / `assignableMembersProvider(siteId)`。

## 7. ルーティング / リダイレクト
- `/signup`（未ログインでアクセス可）、`/members` を追加。
- `authRedirect` を拡張：未ログインは **/login・/signup** のみ許可。ログイン済みが /login・/signup → /home。
- **会社未所属の分岐は「同期リダイレクト」ではなくホーム画面内で行う**（company_id 判定は非同期のため。リダイレクトを複雑化させない）。サインアップ後はホームに入り、会社未所属なら S-Join を表示。

## 8. 完了条件
1. 新規ユーザーが**サインアップ**できる。
2. **招待コード**で会社に参加できる（owner/admin がコード発行→新メンバーが入力）。
3. **会社を新規作成**して owner になれる。
4. owner/admin が**メンバーのロールを member⇄admin** で変更できる（member は不可・自分とownerは対象外）。
5. owner/admin が**現場に担当メンバーを割当/解除**できる（member は閲覧のみ）。
6. **自己昇格不可**（member が直接APIで company_id/role を書き換えられない）。
7. 会社単位のRLS維持（自社データのみ）。
8. analyze成功 / test成功 / dev実機確認。

## 9. テスト条件
- **Controller（Fake Repository）**：JoinController（code成功/無効）、MemberController（昇格/降格・権限なしで失敗）、InviteController（発行/失効）、SiteMemberController（割当/解除）。
- **authRedirect 拡張**の純粋関数テスト（/signup 許可・ログイン済みリダイレクト）。
- **ロールゲート**：UIで owner/admin のみボタン表示（ウィジェットテスト最小1）。
- 既存52件は緑のまま。RLS/RPC の実際の強制は **dev 実機＋Supabaseで確認**（自己昇格が弾かれること等）。

---

## 実装順（段階リリース・成果物はPhase 7一括）
- **7a 基盤**：`0005` 適用ガイド＋ロール関数/RLS、`currentProfileProvider`、サインアップ＋会社参加/作成、ルーター拡張。
- **7b メンバー管理＋招待**：メンバー一覧・ロール変更、招待コード発行/失効/参加。
- **7c 現場の担当割当**：site_members の UI（現場詳細の担当メンバー）。

## 留意点
- **新規依存なし**（supabase_flutter の `signUp` / `rpc` を使用）。
- **Supabase 設定**：dev は Auth の **Email confirmation を OFF**（サインアップで即セッション）を推奨。ON のままなら「確認メール待ち」状態のハンドリングが追加で必要。
- **DB適用**：`0005_org_roles.sql` を dev で実行（prod は本番化時）。**コード変更前に、この要件定義の承認をお願いします。**
- 承認後、`7a` の**実装仕様書（最小工数）**を作成してから着手します（Phase 2〜6 と同じ流れ）。
