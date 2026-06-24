-- =============================================================================
-- Phase 7 組織・権限管理: ロール / 招待コード / 会社参加・作成 / 現場の担当割当
-- 適用先: Supabase dev（後日 prod）。SQL Editor に貼り付けて実行。
-- 冪等（再実行可能）に記述。0001〜0004 を適用済みであること。
-- =============================================================================

-- ---------- ロール判定関数（security definer・RLS再帰回避）----------
-- current_company_id()（0001）と対。ログイン中ユーザーの role を返す。
create or replace function public.current_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

-- ---------- 自己昇格の穴を塞ぐ（重要）----------
-- 現状の profiles_update_own は自分の company_id / role を自由に変更でき、
-- member が自分を owner に昇格できてしまう。旧値との一致を要求して封じる。
-- （会社割当・ロール変更は下の security definer RPC からのみ行う）
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and company_id is not distinct from public.current_company_id()
    and role is not distinct from public.current_role()
  );

-- ---------- 招待コード ----------
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

-- 閲覧・発行・失効は owner/admin かつ自社のみ。
drop policy if exists company_invites_rw on public.company_invites;
create policy company_invites_rw on public.company_invites
  for all to authenticated
  using (company_id = public.current_company_id() and public.current_role() in ('owner','admin'))
  with check (company_id = public.current_company_id() and public.current_role() in ('owner','admin'));

-- ---------- 招待コードで会社に参加（会社未所属の本人のみ）----------
create or replace function public.redeem_invite(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_inv public.company_invites;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;
  select * into v_inv from public.company_invites
    where code = p_code and revoked = false and expires_at > now()
    limit 1;
  if not found then raise exception 'invalid_code'; end if;
  if (select company_id from public.profiles where id = v_uid) is not null then
    raise exception 'already_in_company';
  end if;
  update public.profiles
    set company_id = v_inv.company_id, role = v_inv.role
    where id = v_uid;
  return jsonb_build_object('company_id', v_inv.company_id, 'role', v_inv.role);
end $$;

-- ---------- 会社を新規作成して owner になる（会社未所属の本人のみ）----------
create or replace function public.create_company(p_name text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_company uuid;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;
  if coalesce(trim(p_name), '') = '' then raise exception 'empty_name'; end if;
  if (select company_id from public.profiles where id = v_uid) is not null then
    raise exception 'already_in_company';
  end if;
  insert into public.companies(name) values (trim(p_name)) returning id into v_company;
  update public.profiles set company_id = v_company, role = 'owner' where id = v_uid;
  return jsonb_build_object('company_id', v_company);
end $$;

-- ---------- ロール変更（owner/admin が同一会社の他メンバーを member⇄admin）----------
create or replace function public.set_member_role(p_target uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_crole text; v_ccompany uuid;
  v_tcompany uuid; v_trole text;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;
  if p_role not in ('member','admin') then raise exception 'invalid_role'; end if;
  if p_target = v_uid then raise exception 'cannot_change_self'; end if;
  select company_id, role into v_ccompany, v_crole from public.profiles where id = v_uid;
  if v_crole not in ('owner','admin') then raise exception 'forbidden'; end if;
  select company_id, role into v_tcompany, v_trole from public.profiles where id = p_target;
  if v_tcompany is null or v_tcompany is distinct from v_ccompany then raise exception 'not_same_company'; end if;
  if v_trole = 'owner' then raise exception 'cannot_change_owner'; end if;
  update public.profiles set role = p_role where id = p_target;
end $$;

-- ---------- 現場の担当メンバー（割当情報。閲覧RLSは会社単位のまま）----------
create table if not exists public.site_members (
  site_id     uuid not null references public.sites(id) on delete cascade,
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  assigned_at timestamptz not null default now(),
  assigned_by uuid references public.profiles(id),
  primary key (site_id, profile_id)
);
create index if not exists idx_site_members_site on public.site_members(site_id);

alter table public.site_members enable row level security;

-- 閲覧: 自社の現場の割当のみ（担当外でも自社現場は見える＝閲覧は会社単位のまま）。
drop policy if exists site_members_select on public.site_members;
create policy site_members_select on public.site_members
  for select to authenticated
  using (exists (select 1 from public.sites s
                 where s.id = site_members.site_id
                   and s.company_id = public.current_company_id()));

-- 割当/解除: owner/admin かつ、対象の現場もメンバーも自社。
drop policy if exists site_members_write on public.site_members;
create policy site_members_write on public.site_members
  for all to authenticated
  using (public.current_role() in ('owner','admin')
         and exists (select 1 from public.sites s
                     where s.id = site_members.site_id
                       and s.company_id = public.current_company_id()))
  with check (public.current_role() in ('owner','admin')
         and exists (select 1 from public.sites s
                     where s.id = site_members.site_id
                       and s.company_id = public.current_company_id())
         and exists (select 1 from public.profiles p
                     where p.id = site_members.profile_id
                       and p.company_id = public.current_company_id()));

-- =============================================================================
-- 動作確認メモ:
--  * member ユーザーで `update profiles set role='owner' where id=auth.uid();` が
--    RLS(with check)で弾かれること（自己昇格不可）。
--  * 招待: owner/admin で company_invites に1行 insert → 別の新規ユーザーで
--    `select redeem_invite('そのコード');` → profiles.company_id/role が入る。
--  * `select create_company('テスト建設');` で会社未所属ユーザーが owner になる。
-- =============================================================================
