-- =============================================================================
-- Phase 5 現場内コミュニケーション: 現場連絡（site_posts）＋ 未読（site_post_reads）
-- 適用先: Supabase dev（後日 prod）。SQL Editor に貼り付けて実行。冪等。
-- 前提: 0001〜0005 適用済み（companies/profiles/sites/current_company_id 等）。
-- =============================================================================

-- ---------- 現場連絡（メッセージ）----------
create table if not exists public.site_posts (
  id         uuid primary key default gen_random_uuid(),
  company_id uuid not null default public.current_company_id()
               references public.companies(id) on delete cascade,
  site_id    uuid not null references public.sites(id) on delete cascade,
  author_id  uuid default auth.uid() references public.profiles(id),
  body       text not null check (length(btrim(body)) > 0),
  created_at timestamptz not null default now()
);
create index if not exists site_posts_site_created_idx
  on public.site_posts(site_id, created_at);

alter table public.site_posts enable row level security;

-- 閲覧・投稿は会社の全メンバー（自社のみ）。編集/削除は本フェーズ非対象（ポリシーを置かない＝不可）。
drop policy if exists site_posts_select on public.site_posts;
create policy site_posts_select on public.site_posts
  for select to authenticated
  using (company_id = public.current_company_id());

drop policy if exists site_posts_insert on public.site_posts;
create policy site_posts_insert on public.site_posts
  for insert to authenticated
  with check (company_id = public.current_company_id());

-- ---------- 既読時刻（ユーザー×現場）----------
create table if not exists public.site_post_reads (
  user_id      uuid not null default auth.uid()
                 references public.profiles(id) on delete cascade,
  site_id      uuid not null references public.sites(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (user_id, site_id)
);

alter table public.site_post_reads enable row level security;

drop policy if exists site_post_reads_rw on public.site_post_reads;
create policy site_post_reads_rw on public.site_post_reads
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ---------- 既読化（upsert）----------
create or replace function public.mark_site_read(p_site_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  insert into public.site_post_reads(user_id, site_id, last_read_at)
  values (auth.uid(), p_site_id, now())
  on conflict (user_id, site_id) do update set last_read_at = now();
end $$;

-- ---------- 現場ごとの未読件数（自分の投稿は数えない）----------
create or replace function public.site_unread_counts()
returns table(site_id uuid, unread bigint)
language sql
stable
security definer
set search_path = public
as $$
  select p.site_id, count(*)::bigint
  from public.site_posts p
  left join public.site_post_reads r
    on r.site_id = p.site_id and r.user_id = auth.uid()
  where p.company_id = public.current_company_id()
    and p.author_id is distinct from auth.uid()
    and (r.last_read_at is null or p.created_at > r.last_read_at)
  group by p.site_id;
$$;

-- =============================================================================
-- 動作確認メモ:
--  * 投稿: insert into site_posts(site_id, body) values ('<site>', 'テスト連絡');
--          （company_id / author_id は既定値で自動。RLSで自社のみ）
--  * 未読: select * from site_unread_counts();
--  * 既読: select mark_site_read('<site>');  → 以後その現場の未読は0
-- =============================================================================
