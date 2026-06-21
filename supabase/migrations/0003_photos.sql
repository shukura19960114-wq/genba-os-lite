-- =============================================================================
-- Phase 1.3 写真管理: photos テーブル + Storage バケット + RLS
-- 適用先: Supabase dev / prod の両方（SQL Editor に貼り付けて実行）
-- 前提: 0001 / 0002 適用済み（companies / profiles / sites / current_company_id()）
-- 冪等（再実行可能）。
-- =============================================================================

-- ---------- photos テーブル ----------
create table if not exists public.photos (
  id         uuid primary key default gen_random_uuid(),
  site_id    uuid not null references public.sites (id) on delete cascade,
  company_id uuid not null default public.current_company_id()
               references public.companies (id) on delete cascade,
  path       text not null,  -- Storage パス: {company_id}/{site_id}/{photo_id}.jpg
  created_at timestamptz not null default now()
);

create index if not exists photos_site_id_idx on public.photos (site_id);

alter table public.photos enable row level security;

drop policy if exists photos_select_company on public.photos;
create policy photos_select_company on public.photos
  for select to authenticated using (company_id = public.current_company_id());

drop policy if exists photos_insert_company on public.photos;
create policy photos_insert_company on public.photos
  for insert to authenticated with check (company_id = public.current_company_id());

drop policy if exists photos_delete_company on public.photos;
create policy photos_delete_company on public.photos
  for delete to authenticated using (company_id = public.current_company_id());

-- ---------- Storage バケット（プライベート）----------
insert into storage.buckets (id, name, public)
values ('photos', 'photos', false)
on conflict (id) do nothing;

-- ---------- Storage RLS（パス先頭フォルダ = company_id のみ許可）----------
-- name 例: '<company_id>/<site_id>/<photo_id>.jpg' → foldername[1] = company_id
drop policy if exists photos_storage_select on storage.objects;
create policy photos_storage_select on storage.objects
  for select to authenticated
  using (bucket_id = 'photos'
         and (storage.foldername(name))[1] = public.current_company_id()::text);

drop policy if exists photos_storage_insert on storage.objects;
create policy photos_storage_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'photos'
              and (storage.foldername(name))[1] = public.current_company_id()::text);

drop policy if exists photos_storage_delete on storage.objects;
create policy photos_storage_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'photos'
         and (storage.foldername(name))[1] = public.current_company_id()::text);

-- =============================================================================
-- 注: storage.objects へのポリシー作成が権限エラーになる場合は、
--     ダッシュボード Storage > Policies から同等のポリシーを作成してください。
-- =============================================================================
