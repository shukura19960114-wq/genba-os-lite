# Phase 7a（基盤）実装仕様書（最小工数）

**作成日:** 2026-06-25　／**前提:** [Phase 7 要件定義](Phase7_組織権限管理_要件定義.md)を承認済み（招待コード方式＋site_members）。
**7a の範囲:** DB層（**マイグレーション0005 = 7a/7b/7c 全部の土台を一度に適用**）／サインアップ／会社参加・作成／ロール基盤Provider／ルーター拡張。
**7b（メンバー管理＋招待UI）・7c（担当割当UI）は後続**。0005 にはそれらのテーブル/RPCも含めておき、UIだけ後で足す。

---

## 0. マイグレーション `supabase/migrations/0005_org_roles.sql`（全DB層）
冪等。dev の SQL Editor で実行。**要点:** `current_role()`／自己昇格を塞ぐ profiles 更新ポリシー／company_invites＋RPC／site_members／set_member_role。

```sql
-- current_role(): ログイン中ユーザーの role（RLS再帰回避・definer）
create or replace function public.current_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid();
$$;

-- 自己昇格の穴を塞ぐ: 自分の company_id / role は直接変更不可（旧値一致を要求）
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and company_id is not distinct from public.current_company_id()
    and role is not distinct from public.current_role()
  );

-- 招待コード
create table if not exists public.company_invites (
  id         uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  code       text not null unique,
  role       text not null default 'member' check (role in ('member','admin')),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  revoked    boolean not null default false
);
create index if not exists idx_company_invites_company on public.company_invites(company_id);
alter table public.company_invites enable row level security;
drop policy if exists company_invites_rw on public.company_invites;
create policy company_invites_rw on public.company_invites
  for all to authenticated
  using (company_id = public.current_company_id() and public.current_role() in ('owner','admin'))
  with check (company_id = public.current_company_id() and public.current_role() in ('owner','admin'));

-- 招待コードで参加（会社未所属の本人のみ）
create or replace function public.redeem_invite(p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_inv public.company_invites;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;
  select * into v_inv from public.company_invites
    where code = p_code and revoked = false and expires_at > now() limit 1;
  if not found then raise exception 'invalid_code'; end if;
  if (select company_id from public.profiles where id = v_uid) is not null then
    raise exception 'already_in_company';
  end if;
  update public.profiles set company_id = v_inv.company_id, role = v_inv.role where id = v_uid;
  return jsonb_build_object('company_id', v_inv.company_id, 'role', v_inv.role);
end $$;

-- 会社を新規作成して owner になる（会社未所属の本人のみ）
create or replace function public.create_company(p_name text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_company uuid;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;
  if coalesce(trim(p_name),'') = '' then raise exception 'empty_name'; end if;
  if (select company_id from public.profiles where id = v_uid) is not null then
    raise exception 'already_in_company';
  end if;
  insert into public.companies(name) values (trim(p_name)) returning id into v_company;
  update public.profiles set company_id = v_company, role = 'owner' where id = v_uid;
  return jsonb_build_object('company_id', v_company);
end $$;

-- ロール変更（owner/admin が同一会社の他メンバーを member⇄admin）
create or replace function public.set_member_role(p_target uuid, p_role text)
returns void language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_crole text; v_ccompany uuid; v_tcompany uuid; v_trole text;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;
  if p_role not in ('member','admin') then raise exception 'invalid_role'; end if;
  if p_target = v_uid then raise exception 'cannot_change_self'; end if;
  select company_id, role into v_ccompany, v_crole from public.profiles where id = v_uid;
  if v_crole not in ('owner','admin') then raise exception 'forbidden'; end if;
  select company_id, role into v_tcompany, v_trole from public.profiles where id = p_target;
  if v_tcompany is distinct from v_ccompany then raise exception 'not_same_company'; end if;
  if v_trole = 'owner' then raise exception 'cannot_change_owner'; end if;
  update public.profiles set role = p_role where id = p_target;
end $$;

-- 現場の担当メンバー（割当情報。閲覧RLSは会社単位のまま）
create table if not exists public.site_members (
  site_id     uuid not null references public.sites(id) on delete cascade,
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  assigned_at timestamptz not null default now(),
  assigned_by uuid references public.profiles(id),
  primary key (site_id, profile_id)
);
create index if not exists idx_site_members_site on public.site_members(site_id);
alter table public.site_members enable row level security;
drop policy if exists site_members_select on public.site_members;
create policy site_members_select on public.site_members
  for select to authenticated
  using (exists (select 1 from public.sites s
                 where s.id = site_members.site_id and s.company_id = public.current_company_id()));
drop policy if exists site_members_write on public.site_members;
create policy site_members_write on public.site_members
  for all to authenticated
  using (public.current_role() in ('owner','admin')
         and exists (select 1 from public.sites s
                     where s.id = site_members.site_id and s.company_id = public.current_company_id()))
  with check (public.current_role() in ('owner','admin')
         and exists (select 1 from public.sites s
                     where s.id = site_members.site_id and s.company_id = public.current_company_id())
         and exists (select 1 from public.profiles p
                     where p.id = site_members.profile_id and p.company_id = public.current_company_id()));
```

---

## 1. 追加・変更ファイル（7a）
| 区分 | パス | 内容 |
|---|---|---|
| 追加 | `supabase/migrations/0005_org_roles.sql` | 上記DB層（全Phase 7） |
| 変更 | `lib/features/auth/data/auth_repository.dart` | `signUp(email, password)` 追加 |
| 追加 | `lib/features/org/data/org_repository.dart` | `redeemInvite(code)` / `createCompany(name)`（`rpc`） |
| 変更 | `lib/features/auth/data/profile_repository.dart` | （変更なし。`fetchCurrentProfile` 流用） |
| 追加 | `lib/features/auth/application/current_profile_provider.dart` | `currentProfileProvider`（FutureProvider<Profile?>）＋ `currentRoleProvider` |
| 変更 | `lib/features/auth/application/auth_providers.dart` | `homeProfileProvider` を `currentProfileProvider` ベースに整理 |
| 変更 | `lib/features/auth/application/auth_controller.dart` | `signUp` 追加 |
| 追加 | `lib/features/org/application/join_controller.dart` | `JoinController`（autoDispose）`joinWithCode` / `createCompany` |
| 追加 | `lib/features/auth/presentation/signup_screen.dart` | サインアップ画面 |
| 変更 | `lib/features/auth/presentation/login_screen.dart` | 「新規登録はこちら」リンク |
| 追加 | `lib/features/org/presentation/join_company_view.dart` | 会社参加/作成（ホーム内分岐で表示） |
| 変更 | `lib/features/home/presentation/home_screen.dart` | 会社未所属なら JoinCompanyView を表示 |
| 変更 | `lib/core/router/app_routes.dart` / `app_router.dart` | `/signup` 追加・`authRedirect` 拡張 |
| 追加 | テスト | `auth_redirect`（/signup）／`join_controller_test`／`auth_controller signUp`（最小） |

## 2. AuthRepository（追加メソッド）
```dart
Future<void> signUp({required String email, required String password}) async {
  await _client.auth.signUp(email: email.trim(), password: password);
}
```
- 抽象interfaceにも宣言を追加。`authErrorMessage` に `user already registered` の日本語化を1行追加。

## 3. OrgRepository（新規）
```dart
abstract interface class OrgRepository {
  Future<void> redeemInvite(String code);     // rpc('redeem_invite', {p_code: code})
  Future<void> createCompany(String name);    // rpc('create_company', {p_name: name})
}
// Supabase実装は _client.rpc(...) を呼ぶだけ。PostgrestException はそのまま投げる。
final orgRepositoryProvider = Provider<OrgRepository>(...);
```
- RPC例外メッセージ（`invalid_code` / `already_in_company` / `empty_name`）を画面用日本語に変換する `orgErrorMessage(Object)` を同ファイルに用意。

## 4. currentProfileProvider（新規）
```dart
final currentProfileProvider = FutureProvider<Profile?>(
  (ref) => ref.watch(profileRepositoryProvider).fetchCurrentProfile());
final currentRoleProvider = Provider<String?>(
  (ref) => ref.watch(currentProfileProvider).value?.role);
```
- `homeProfileProvider` は `currentProfileProvider` を watch して会社名のみ追加取得（二重フェッチ回避）。
- ロールゲート用ヘルパー：`bool isManager(String? role) => role == 'owner' || role == 'admin';`（org か shared に置く）。

## 5. JoinController（新規・autoDispose）
```dart
final joinControllerProvider =
    AsyncNotifierProvider.autoDispose<JoinController, void>(JoinController.new);
class JoinController extends AsyncNotifier<void> {
  FutureOr<void> build() {}
  Future<bool> joinWithCode(String code) async { ...guard: orgRepo.redeemInvite; 成功で currentProfile/home invalidate... }
  Future<bool> createCompany(String name) async { ...guard: orgRepo.createCompany; 成功で invalidate... }
}
```
- 成功時 `ref.invalidate(currentProfileProvider)` と `ref.invalidate(homeProfileProvider)`。

## 6. AuthController（追加）
- `Future<bool> signUp({email, password})`：既存 signIn と同型。`AsyncValue.guard` → 成功で true。
  - 既存 `signOut`/`signIn` パターンに合わせる。

## 7. 画面
- **SignupScreen**：メール・パスワード（+確認用は任意で省略可）。`signUp` 成功 → 認証状態変化でホームへ（リダイレクトに任せる）。`pop` でログインへ戻れる。
- **LoginScreen**：下部に `TextButton('新規登録はこちら') → context.push('/signup')`。
- **JoinCompanyView**：2カード。①招待コード入力 → `joinWithCode`。②会社名入力 → `createCompany`。成功でホーム本体に切替（currentProfile invalidate で再描画）。失敗は SnackBar（`orgErrorMessage`）。
- **HomeScreen**：`currentProfileProvider` を watch。`profile == null`→ローディング/エラー。`profile.companyId == null`→ `JoinCompanyView`。それ以外→既存ホーム（後続7bで「メンバー管理」導線を owner/admin に追加）。

## 8. ルーティング
- `app_routes.dart`：`signup = '/signup'` 追加。
- `app_router.dart`：`/signup` の GoRoute 追加（builder: `SignupScreen`）。
- `authRedirect` 拡張：
```dart
String? authRedirect({required bool loggedIn, required String location}) {
  final authPages = location == RoutePaths.login || location == RoutePaths.signup;
  if (!loggedIn) return authPages ? null : RoutePaths.login;
  if (authPages) return RoutePaths.home;
  return null;
}
```
- 会社未所属の分岐は**リダイレクトせずホーム内で**処理（非同期判定のため）。

## 9. テスト（7a）
- `auth_redirect`：未ログインで /signup 許可（null）、ログイン済みで /signup→/home、未ログインで他→/login（既存ケース維持）。
- `JoinController`（Fake OrgRepository）：`joinWithCode` 成功（true）／例外（false・state エラー）。`createCompany` 成功（true）。
- `AuthController.signUp`（Fake AuthRepository）：成功（true・state not error）／例外（false・error）。
- 既存52件は緑のまま。RLS/RPCの実強制（自己昇格拒否・コード参加）は **dev実機＋Supabase** で確認。

## 10. 完了条件（7a）
1. サインアップできる（新規ユーザー作成→ホームへ）。
2. 会社未所属だと会社参加/作成画面が出る。
3. 招待コードで参加できる／会社を作成して owner になれる（※コード発行UIは7b。7aは既存のコードか手動INSERTで参加を確認可）。
4. analyze成功／test成功／dev実機確認。

> 7a 実装後、`0005` 適用ガイド（Supabase手順）と実機確認手順を提示。続けて 7b（メンバー管理＋招待UI）へ。
