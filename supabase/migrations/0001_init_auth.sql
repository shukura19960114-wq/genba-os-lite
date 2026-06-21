-- =============================================================================
-- Phase 1.1 認証/ログイン: companies / profiles + RLS
-- 適用先: Supabase dev / prod の両方（SQL Editor に貼り付けて実行）
-- 冪等（再実行可能）に書いてあります。
-- =============================================================================

-- ---------- テーブル ----------

-- 会社（テナント）。マルチテナントの起点。
create table if not exists public.companies (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  created_at timestamptz not null default now()
);

-- ユーザープロフィール（auth.users と 1:1）。会社に紐付く。
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  company_id uuid references public.companies (id) on delete set null,
  email      text,
  role       text not null default 'member',
  created_at timestamptz not null default now()
);

-- ---------- 自社判定関数（security definer）----------
-- RLS ポリシー内から profiles を参照すると無限再帰になるため、
-- definer 権限で RLS をバイパスして「ログイン中ユーザーの company_id」を返す。
create or replace function public.current_company_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select company_id from public.profiles where id = auth.uid();
$$;

-- ---------- 新規ユーザー時に profiles を自動作成 ----------
-- ダッシュボードや signUp で auth.users が作られたら、対応する profiles 行を作る。
-- company_id は NULL（後から会社へ割当）。role は member。
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- RLS（Row Level Security）----------
alter table public.companies enable row level security;
alter table public.profiles  enable row level security;

-- profiles: 自分の行、または「同じ会社」の行のみ閲覧可。
drop policy if exists profiles_select_own_or_company on public.profiles;
create policy profiles_select_own_or_company on public.profiles
  for select to authenticated
  using (id = auth.uid() or company_id = public.current_company_id());

-- profiles: 自分の行のみ更新可（role/company の他者改変を防ぐ。admin 制御は将来フェーズ）。
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- companies: 自社のみ閲覧可。
drop policy if exists companies_select_own on public.companies;
create policy companies_select_own on public.companies
  for select to authenticated
  using (id = public.current_company_id());

-- =============================================================================
-- 動作確認用シード（任意）: 下を必要に応じて編集して実行。
-- 1) Authenticationでテストユーザーを作成（Auto Confirm User を ON）すると、
--    トリガーで profiles 行が自動作成される（company_id は NULL）。
-- 2) 下記で会社を作り、そのユーザーを会社に割り当てる。
--    'test@example.com' を実際に作成したユーザーのメールに置き換える。
-- -----------------------------------------------------------------------------
-- insert into public.companies (name) values ('デモ建設株式会社');
-- update public.profiles
--   set company_id = (select id from public.companies where name = 'デモ建設株式会社' limit 1),
--       role = 'owner'
--   where email = 'test@example.com';
-- =============================================================================
