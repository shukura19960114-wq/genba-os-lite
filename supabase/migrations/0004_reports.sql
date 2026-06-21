-- 0004_reports.sql : Phase 2 日報機能
-- 依存: companies, sites, current_company_id(), auth.users
-- 適用: dev / prod の SQL Editor で実行（コード変更不要）。冪等。

-- 1) テーブル
create table if not exists public.reports (
  id           uuid primary key default gen_random_uuid(),
  company_id   uuid not null default public.current_company_id()
                 references public.companies(id) on delete cascade,
  site_id      uuid not null
                 references public.sites(id) on delete cascade,
  report_date  date not null default current_date,
  weather      text,
  work_content text not null,
  worker_count int check (worker_count >= 0),
  created_by   uuid default auth.uid()
                 references auth.users(id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- 2) インデックス（現場別・日付降順）
create index if not exists reports_site_date_idx
  on public.reports (site_id, report_date desc);

-- 3) updated_at 自動更新トリガ
-- set_updated_at() が Phase 1 で既に存在する場合も create or replace で冪等。
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists reports_set_updated_at on public.reports;
create trigger reports_set_updated_at
  before update on public.reports
  for each row execute function public.set_updated_at();

-- 4) RLS
alter table public.reports enable row level security;

drop policy if exists reports_select on public.reports;
create policy reports_select on public.reports
  for select
  using (company_id = public.current_company_id());

drop policy if exists reports_insert on public.reports;
create policy reports_insert on public.reports
  for insert
  with check (company_id = public.current_company_id());

drop policy if exists reports_update on public.reports;
create policy reports_update on public.reports
  for update
  using (company_id = public.current_company_id())
  with check (company_id = public.current_company_id());

drop policy if exists reports_delete on public.reports;
create policy reports_delete on public.reports
  for delete
  using (company_id = public.current_company_id());
