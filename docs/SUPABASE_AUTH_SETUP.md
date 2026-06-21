# Supabase 認証セットアップ手順（Phase 1.1）

Phase 1.1（認証/ログイン）を動かすための **Supabase 側の手作業** をまとめます。
コードは実装済みなので、ここを終えればログインが動きます。**dev / prod の両方**に適用してください
（まずは dev だけでも可。本番運用前に prod にも同じ手順を実施）。

> 前提: `companies` / `profiles` テーブルと RLS を作る必要があります。アプリの anon key では
> テーブル作成ができないため、ダッシュボードの SQL Editor で実行します。

---

## 1. テーブル + RLS を作成

1. Supabase ダッシュボード → 対象プロジェクト（dev）→ 左メニュー **SQL Editor**
2. [supabase/migrations/0001_init_auth.sql](../supabase/migrations/0001_init_auth.sql) の中身を**全部コピーして貼り付け** → **Run**
3. エラーが出なければ完了（冪等なので再実行しても安全）

作成されるもの:
- `companies`（id / name / created_at）
- `profiles`（id / company_id / email / role / created_at）
- `current_company_id()` 関数（自社判定）
- 新規ユーザー時に `profiles` を自動作成するトリガー
- RLS ポリシー（自社データのみ閲覧可）

## 2. メール認証を有効化（確認メールはオフ推奨：検証を簡単にするため）

1. ダッシュボード → **Authentication** → **Sign In / Providers** → **Email** を有効
2. 検証を簡単にするため **Confirm email を一旦 OFF**（本番では運用方針に合わせる）

## 3. テストユーザーを作成

1. ダッシュボード → **Authentication** → **Users** → **Add user** → **Create new user**
2. Email / Password を入力し、**Auto Confirm User を ON** にして作成
   - 例: `test@example.com` / 任意のパスワード
3. 作成すると、トリガーにより `profiles` に行が自動作成されます（`company_id` は NULL）

## 4. 会社を作成してユーザーを割り当て（任意だが推奨）

SQL Editor で以下を実行（`test@example.com` は手順3のメールに置換）:

```sql
insert into public.companies (name) values ('デモ建設株式会社');
update public.profiles
  set company_id = (select id from public.companies where name = 'デモ建設株式会社' limit 1),
      role = 'owner'
  where email = 'test@example.com';
```

> これで Home 画面に会社名・ロールが表示されます。割り当てなくてもログイン自体は成功します。

## 5. アプリで確認

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

- 起動 → **ログイン画面** が出る（未ログインのため）
- 手順3のメール/パスワードでログイン → **Home 画面** に遷移
- アプリを再起動しても **ログイン状態が維持**される（セッション復元）
- Home の **ログアウト** で再びログイン画面へ

---

## トラブルシュート

| 症状 | 原因 / 対処 |
|---|---|
| 「メールアドレスまたはパスワードが違います」 | 資格情報違い、または Confirm email が ON でユーザー未確認。手順2/3を確認 |
| ログイン後 Home で会社名が出ない | 手順4の会社割り当て未実施（`company_id` が NULL）。ログイン自体は成功 |
| `relation "public.profiles" does not exist` | 手順1のSQL未実行。対象プロジェクトで実行したか確認（dev/prod 取り違え注意） |
