-- =============================================================================
-- Phase 1.2 現場一覧: sites テーブル + RLS
-- 適用先: Supabase dev / prod の両方（SQL Editor に貼り付けて実行）
-- 前提: 0001_init_auth.sql 適用済み（companies / profiles / current_company_id()）
-- 冪等（再実行可能）。
-- =============================================================================

create table if not exists public.sites (
  id         uuid primary key default gen_random_uuid(),
  -- company_id は明示指定しなくてもログインユーザーの会社が自動で入る
  company_id uuid not null default public.current_company_id()
               references public.companies (id) on delete cascade,
  name       text not null,
  address    text,
  status     text not null default 'active',  -- active(進行中) / completed(完了) / suspended(中止)
  created_at timestamptz not null default now()
);

create index if not exists sites_company_id_idx on public.sites (company_id);

-- ---------- RLS（自社の現場のみ操作可）----------
alter table public.sites enable row level security;

drop policy if exists sites_select_company on public.sites;
create policy sites_select_company on public.sites
  for select to authenticated
  using (company_id = public.current_company_id());

drop policy if exists sites_insert_company on public.sites;
create policy sites_insert_company on public.sites
  for insert to authenticated
  with check (company_id = public.current_company_id());

drop policy if exists sites_update_company on public.sites;
create policy sites_update_company on public.sites
  for update to authenticated
  using (company_id = public.current_company_id())
  with check (company_id = public.current_company_id());

drop policy if exists sites_delete_company on public.sites;
create policy sites_delete_company on public.sites
  for delete to authenticated
  using (company_id = public.current_company_id());

-- =============================================================================
-- 動作確認（任意）: ログイン中ユーザーの会社に紐づく現場のみ見えることを確認できる。
--   select id, company_id, name, status from public.sites;
-- =============================================================================
