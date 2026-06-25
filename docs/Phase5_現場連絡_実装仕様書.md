# Phase 5 現場連絡 実装仕様書（最小工数）

**作成日:** 2026-06-25　／**前提:** [要件定義](Phase5_現場連絡_要件定義.md) 承認済み（メッセージ＋未読バッジ）。
**範囲:** DB層（**0006 = 5a/5b 全部**）／現場連絡画面・投稿（5a）／未読バッジ・既読化（5b）。新規依存なし・service_role不使用。

---

## 0. マイグレーション `supabase/migrations/0006_site_posts.sql`（全DB層）
冪等。dev の SQL Editor で実行。既存流儀（`company_id default current_company_id()` / `author_id default auth.uid()` / 会社単位RLS）に準拠。

```sql
-- 現場連絡（メッセージ）
create table if not exists public.site_posts (
  id         uuid primary key default gen_random_uuid(),
  company_id uuid not null default public.current_company_id()
               references public.companies(id) on delete cascade,
  site_id    uuid not null references public.sites(id) on delete cascade,
  author_id  uuid default auth.uid() references public.profiles(id),
  body       text not null check (length(btrim(body)) > 0),
  created_at timestamptz not null default now()
);
create index if not exists site_posts_site_created_idx on public.site_posts(site_id, created_at);
alter table public.site_posts enable row level security;
drop policy if exists site_posts_select on public.site_posts;
create policy site_posts_select on public.site_posts for select to authenticated
  using (company_id = public.current_company_id());
drop policy if exists site_posts_insert on public.site_posts;
create policy site_posts_insert on public.site_posts for insert to authenticated
  with check (company_id = public.current_company_id());
-- update/delete は本フェーズ非対象（ポリシーを置かない＝不可）

-- 既読時刻（ユーザー×現場）
create table if not exists public.site_post_reads (
  user_id      uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  site_id      uuid not null references public.sites(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (user_id, site_id)
);
alter table public.site_post_reads enable row level security;
drop policy if exists site_post_reads_rw on public.site_post_reads;
create policy site_post_reads_rw on public.site_post_reads for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 既読化（upsert）
create or replace function public.mark_site_read(p_site_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  insert into public.site_post_reads(user_id, site_id, last_read_at)
  values (auth.uid(), p_site_id, now())
  on conflict (user_id, site_id) do update set last_read_at = now();
end $$;

-- 現場ごとの未読件数（自分の投稿は数えない）
create or replace function public.site_unread_counts()
returns table(site_id uuid, unread bigint)
language sql stable security definer set search_path = public as $$
  select p.site_id, count(*)::bigint
  from public.site_posts p
  left join public.site_post_reads r
    on r.site_id = p.site_id and r.user_id = auth.uid()
  where p.company_id = public.current_company_id()
    and p.author_id is distinct from auth.uid()
    and (r.last_read_at is null or p.created_at > r.last_read_at)
  group by p.site_id;
$$;
```

---

## 1. 追加・変更ファイル
| 区分 | パス | 内容 |
|---|---|---|
| 追加 | `supabase/migrations/0006_site_posts.sql` | 上記DB層 |
| 追加 | `lib/features/messages/data/post.dart`（+生成） | `Post` モデル（埋め込み author email） |
| 追加 | `lib/features/messages/data/post_repository.dart` | listBySite / create / markRead / unreadCounts |
| 追加 | `lib/features/messages/application/posts_providers.dart` | sitePostsProvider.family / unreadCountsProvider |
| 追加 | `lib/features/messages/application/post_controller.dart` | PostController（autoDispose）send / markRead |
| 追加 | `lib/features/messages/presentation/messages_screen.dart` | 現場連絡画面（一覧＋入力欄、開封で既読化） |
| 変更 | `lib/features/sites/presentation/site_detail_screen.dart` | 「連絡」への ListTile 導線 |
| 変更 | `lib/features/sites/presentation/site_list_screen.dart` | 各タイルに未読バッジ |
| 変更 | `lib/core/router/app_routes.dart` / `app_router.dart` | `/sites/:id/messages` |
| 追加 | テスト | PostController（send/markRead）/ Post.fromJson / unreadCounts パース |

## 2. Post モデル
```text
@freezed Post: id / siteId(site_id) / authorId(author_id) / body / createdAt(created_at) / authorEmail
fromJson: 埋め込み profiles(email) を authorEmail に展開（無ければ null）
get authorLabel => authorEmail ?? '(不明)'
```

## 3. PostRepository
```text
listBySite(siteId): from('site_posts').select('id, site_id, author_id, body, created_at, profiles(email)')
                    .eq('site_id', siteId).order('created_at')  // 時系列（古→新）
create(siteId, body): insert({'site_id', 'body'})  // company_id/author_id はDB既定
markRead(siteId): rpc('mark_site_read', {p_site_id: siteId})
unreadCounts(): rpc('site_unread_counts') → Map<String,int>{site_id: unread}
```

## 4. Riverpod
- `sitePostsProvider.family<List<Post>, String>(siteId)`：一覧。投稿成功で invalidate。
- `unreadCountsProvider`：`Future<Map<String,int>>`。現場一覧で watch、既読化・投稿で invalidate。
- `PostController`（`AsyncNotifierProvider.autoDispose`）：
  - `send(siteId, body)`：空文字は無視。create→`sitePostsProvider(siteId)`/`unreadCountsProvider` invalidate。成功 true。
  - `markRead(siteId)`：rpc→`unreadCountsProvider` invalidate（失敗は握りつぶし可＝バッジ更新のみ）。

## 5. 画面
- **MessagesScreen(siteId)**：AppBar「現場の連絡」。本体は時系列リスト（古→新、最下部が最新）。下部に入力欄＋送信。
  - `initState` 相当（ConsumerStatefulWidget）で `markRead(siteId)` を1回呼ぶ → 未読クリア。
  - 送信：`send` 成功で入力クリア・末尾へスクロール。投稿は自分も含め一覧に出る。
  - 空状態「まだ連絡はありません」。エラー時 再読み込み。各メッセージ：本文・投稿者(email)・日時（`yyyy/MM/dd HH:mm`）。
- **site_detail**：日報 ListTile の隣に「連絡」ListTile → `/sites/<id>/messages`。
- **site_list**：各タイルの trailing に未読バッジ（`unreadCountsProvider` の値>0 のとき赤丸＋件数）。

## 6. ルーティング
- `app_routes`：`siteMessages = '/sites/:id/messages'`。
- `app_router`：GoRoute 追加（`MessagesScreen(siteId: pathParameters['id']!)`）。`'/sites/:id/photos'` 等と同じ並び規則（`:id` 配下）。

## 7. テスト
- PostController（Fake PostRepository）：`send` 成功（true・create呼ばれる）／空文字（false・未送信）／失敗（false・error）。`markRead` 呼び出し。
- Post.fromJson：`profiles: {email}` を authorEmail に展開。
- unreadCounts のパース：rpc戻り（list of {site_id, unread}）→ Map。
- 既存73件は緑のまま。RLS/RPCの実強制は dev実機＋Supabase で確認。

## 8. 完了条件
1. 現場連絡を投稿・閲覧（投稿者・日時）。2. 現場一覧に未読バッジ→開くと消える。3. RLS維持。4. analyze/test/dev実機。
