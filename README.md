# 現場OS Lite（genba_os_lite）

中小建設企業の現場業務をスマホで支援するアプリ。Flutter + Supabase 製。
本リポジトリは **Phase 1（基盤＋初期機能）完了**。基盤構築 + ログイン + 現場の一覧/作成/詳細 + 現場写真の撮影/アップロード/表示まで実装しています。

- 対象: iOS / Android（モバイル中心。Web は当面対象外）
- バックエンド: Supabase（**dev / prod の2環境**）。認証は Email + Password、全テーブルに `company_id` + RLS
- 詳細な進捗・設計: [docs/ROADMAP.md](docs/ROADMAP.md) ／ 基盤: [docs/SETUP.md](docs/SETUP.md) ／ 認証: [docs/SUPABASE_AUTH_SETUP.md](docs/SUPABASE_AUTH_SETUP.md)
- DBスキーマ: [supabase/migrations/](supabase/migrations/)（dev/prod の SQL Editor で順に適用）

## 認証（ログイン）

起動すると未ログインなら **ログイン画面** が出ます（go_router の認証ガード）。Email + Password でログインすると
Home 画面へ遷移し、セッションは端末に保存され**再起動後も自動ログイン**します。テーブル（companies/profiles）・
RLS・テストユーザーの作り方は [docs/SUPABASE_AUTH_SETUP.md](docs/SUPABASE_AUTH_SETUP.md) を参照。

---

## クイックスタート

```bash
flutter pub get
dart run build_runner build          # freezed 等のコード生成（初回 / pull 後）
```

`.env.dev` / `.env.prod` が無い場合は、テンプレートから作成して Supabase の値を記入:

```bash
cp .env.example .env.dev
cp .env.example .env.prod
# 各ファイルに SUPABASE_URL / SUPABASE_ANON_KEY を記入（anon public key のみ。service_role は絶対に入れない）
```

> `.env.dev` / `.env.prod` は Git 管理外です（`.env.example` のみコミット）。

---

## 起動方法

環境（dev / prod）は **Dart のエントリポイント（`-t`）** で決まり、**`--flavor`** がネイティブの
アプリ名・Bundle ID を切り替えます。両方を必ずセットで指定します。

### dev 起動

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

- アプリ名: **現場OS Lite Dev** ／ Bundle ID: `com.example.genbaOsLite.dev`
- 接続先: **dev** の Supabase（`.env.dev`）
- 起動画面に「**環境：dev**」「**Supabase接続：OK**」が表示されれば成功

### prod 起動

```bash
flutter run --flavor prod -t lib/main_prod.dart
```

- アプリ名: **現場OS Lite** ／ Bundle ID: `com.example.genbaOsLite`
- 接続先: **prod** の Supabase（`.env.prod`）
- 起動画面に「**環境：prod**」が表示される

> dev と prod は Bundle ID が異なるため、**1台の端末に同居インストール**できます。

### 特定デバイスを指定する場合

```bash
flutter devices                                   # デバイス一覧
flutter run --flavor dev -t lib/main_dev.dart -d <device-id>
```

---

## Flavor 構成

| 項目 | dev | prod |
|---|---|---|
| 起動エントリ（`-t`） | `lib/main_dev.dart` | `lib/main_prod.dart` |
| `--flavor` | `dev` | `prod` |
| アプリ表示名 | 現場OS Lite Dev | 現場OS Lite |
| Bundle ID (iOS) | `com.example.genbaOsLite.dev` | `com.example.genbaOsLite` |
| 接続環境ファイル | `.env.dev` | `.env.prod` |
| Xcode Scheme | `dev` | `prod` |

### iOS のビルド構成（Xcode）

- **Build Configurations（9種）**: `Debug` / `Release` / `Profile` に加えて、
  `Debug-dev` / `Release-dev` / `Profile-dev` / `Debug-prod` / `Release-prod` / `Profile-prod`
- 各 flavor Configuration は `ios/Flutter/<Config>-<flavor>.xcconfig` を参照し、
  表示名・Bundle ID・起動ターゲットを定義
- **共有 Scheme**: `dev` / `prod`（`Runner.xcodeproj/xcshareddata/xcschemes/`）
- iOS プラグインは **Swift Package Manager** で解決（Podfile 不要）

> Android にも `dev` / `prod` の productFlavor を定義済みですが、実機ビルド検証は後続フェーズで対応します（iOS 優先）。

---

## 品質チェック

```bash
flutter analyze     # 静的解析（エラー0であること）
flutter test        # ユニット/ウィジェットテスト
```

CI（GitHub Actions）は `main` への push / PR で **analyze + test** を自動実行します
（実鍵不要・接続テストなし）。設定は [.github/workflows/ci.yml](.github/workflows/ci.yml)。

---

## ディレクトリ構成（feature-first）

```
lib/
├── main_dev.dart / main_prod.dart   # 環境別エントリポイント
├── bootstrap.dart                    # dotenv → AppConfig → Supabase 初期化 → runApp
├── app.dart                          # MaterialApp.router
├── core/      config / supabase / router / theme   # 横断インフラ
├── shared/    再利用 UI・ヘルパー
└── features/<feature>/ presentation / application / data
```

依存方向は `presentation → application → data` の一方向。`SupabaseClient` に触れるのは data 層のみ。
