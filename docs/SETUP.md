# 現場OS Lite — Phase 1.0 基盤 セットアップ手順

このドキュメントは、Claude Code が作成した **Phase 1.0（基盤）** を実際に動かすための手順です。
コード（Claude Code 担当タスク）は作成済みなので、ここでは **あなたの環境での手作業**（仕様書 1-1〜1-4, 1-10, iOS Flavor）を中心にまとめます。

> 前提: この PC には `flutter` / `dart` が必要です。`flutter doctor` がすべて緑になっていることを先に確認してください（仕様書 1-1）。

---

## 0. 完成イメージ（Phase 1.0 のゴール）

- `flutter run --flavor dev -t lib/main_dev.dart` でアプリが起動する
- 起動画面に「**環境：dev**」「**Supabase接続：OK**」が表示される
- `--flavor prod -t lib/main_prod.dart` で「**環境：prod**」に切り替わる
- APIキーがソースに直書きされておらず、`.env` が Git 管理外
- `flutter analyze` がエラー0
- GitHub に push すると CI が緑

---

## 1. Supabase プロジェクト作成（手作業 / 仕様書 1-2〜1-4）

1. <https://supabase.com> でアカウント作成
2. **dev 用**プロジェクト作成（例: `genba-os-dev`）
3. **prod 用**プロジェクト作成（例: `genba-os-prod`）— 面倒でも必ず2つ作る（ここが Phase 1 の肝）
4. 各プロジェクトの **Project Settings > API** から以下を控える:
   - `Project URL` → `SUPABASE_URL`
   - `Project API keys > anon public` → `SUPABASE_ANON_KEY`
   - ⚠️ **`service_role` key はアプリに絶対入れない**（全権限が漏れる。サーバ/Edge Function 専用）

## 2. .env に鍵を貼る

リポジトリ直下にある（Git 管理外の）以下2ファイルにそれぞれの値を貼ります。

> ⚠️ **clone 直後でこの2ファイルが無い場合**は、先にテンプレートから作成してください
> （`.env.dev` / `.env.prod` は assets 必須なので、両方とも存在しないと `flutter test` / `build` が失敗します）:
> ```bash
> cp .env.example .env.dev && cp .env.example .env.prod
> ```

```
.env.dev    ← dev プロジェクトの URL / anon key
.env.prod   ← prod プロジェクトの URL / anon key
```

```env
SUPABASE_URL=https://xxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...（anon public key）
```

> `.env.example` はテンプレートとして Git にコミットされます。`.env.dev` / `.env.prod` は `.gitignore` 済みでコミットされません（`git status` で確認）。

## 3. 依存取得 & コード生成

```bash
flutter pub get
dart run build_runner build   # freezed の生成（AppConfig）
```

> `*.freezed.dart` は Git 管理外です。clone 直後や pull 後は build_runner を回してください（CI も自動で回します）。

## 4. Android で起動確認（仕様書 1-10）

Android は Flavor 設定済みなので、**必ず `--flavor` を付けて**起動します。

```bash
flutter run --flavor dev  -t lib/main_dev.dart    # 「環境：dev」
flutter run --flavor prod -t lib/main_prod.dart   # 「環境：prod」
```

- dev はアプリ名「現場OS Lite Dev」、applicationId `...genba_os_lite.dev` で prod と同居インストール可能。
- 接続が **NG** でも、画面にエラー内容が出ていれば仕組みとしては前進です。URL/anon key のタイプミスを潰して **OK** にしてからクローズしてください。

---

## 5. iOS Flavor 設定（手作業 / 最難関）

xcconfig ファイルは作成済み（`ios/Flutter/{Debug,Release,Profile}-{dev,prod}.xcconfig`）。
残りは **Xcode GUI での Build Configuration と Scheme の作成**です。先に `flutter pub get` → `cd ios && pod install` を済ませてから、**`ios/Runner.xcworkspace`**（.xcodeproj ではない）を開いて作業します。

### 5-1. Build Configuration を6つ作る
1. 左ペインで **Runner プロジェクト（青アイコン）** を選択 > **Info** タブ > **Configurations**
2. 既定の `Debug` / `Release` / `Profile` をそれぞれ複製（Duplicate）して、次の **6つ**にする（名前は厳密に）:
   - `Debug-dev` / `Release-dev` / `Profile-dev`
   - `Debug-prod` / `Release-prod` / `Profile-prod`

### 5-2. 各 Configuration に xcconfig を紐付ける
各 Configuration 行を展開し、**Runner ターゲット**の "Based on Configuration File" を、対応する `ios/Flutter/*.xcconfig` に設定:
- `Debug-dev` → `Debug-dev.xcconfig`、`Release-dev` → `Release-dev.xcconfig` … という対応で6つすべて

### 5-3. Bundle ID と表示名を xcconfig 参照にする
- Runner ターゲット > **Build Settings** > `Product Bundle Identifier` を `$(PRODUCT_BUNDLE_IDENTIFIER)` に
  - ⚠️ 既定の `project.pbxproj` には `PRODUCT_BUNDLE_IDENTIFIER = com.example.genbaOsLite` が**直書き**されています。
    これが残っていると xcconfig の `.dev` サフィックスが効かず dev/prod が同じ bundle id になります。
    Build Settings の該当値を `$(PRODUCT_BUNDLE_IDENTIFIER)` にして直書きを上書きしてください。
- `ios/Runner/Info.plist` の `CFBundleDisplayName` は `$(APP_DISPLAY_NAME)` に設定済み

### 5-4. Scheme を2つ作る
1. **Product > Scheme > Manage Schemes**
2. `+` で Scheme を追加。名前は **`dev`** と **`prod`**（= `--flavor` の値と完全一致、大文字小文字も）
3. 両方とも **Shared** にチェック（CI から見えるように）
4. 既定の `Runner` Scheme は削除 or 無視（混乱回避）

### 5-5. 各 Scheme のアクションに Configuration を割り当てる
**Edit Scheme** で、`dev` Scheme:
- Run → `Debug-dev` / Test → `Debug-dev` / Profile → `Profile-dev` / Analyze → `Debug-dev` / Archive → `Release-dev`

`prod` Scheme も同様に `*-prod` を割り当て。

### 5-6. Podfile に Configuration マッピングを追加
`cd ios && pod install` を最初に走らせると `ios/Podfile` が生成されます。
カスタム Configuration（`Debug-dev` 等）を CocoaPods が `:debug` / `:release` に対応づけられるよう、
生成された Podfile の先頭付近に**プロジェクトの config マッピング**を追記してください:

```ruby
project 'Runner', {
  'Debug'        => :debug,
  'Debug-dev'    => :debug,
  'Debug-prod'   => :debug,
  'Profile'      => :release,
  'Profile-dev'  => :release,
  'Profile-prod' => :release,
  'Release'      => :release,
  'Release-dev'  => :release,
  'Release-prod' => :release,
}
```
追記後に再度 `pod install`。これが無いと `pod install` がカスタム config を扱えず iOS ビルドが失敗します。

### 5-7. 検証
```bash
flutter run   --flavor dev  -t lib/main_dev.dart
flutter build ipa --flavor prod -t lib/main_prod.dart
```
> 「could not find a scheme matching the flavor」が出たら、Scheme 名 or `Debug-<flavor>` Configuration 名のスペルミス。大文字小文字まで一致させること。

---

## 6. .gitignore とコミット（仕様書 1-11）

`.gitignore` は秘密情報（`.env` / `.env.*`、ただし `.env.example` は残す）と生成物（`*.freezed.dart` / `*.g.dart`）を除外済み。

```bash
git status   # .env.dev / .env.prod が「追跡対象に入っていない」ことを必ず確認
```

問題なければコミット（フェーズごとに分割する方針）:
```bash
git add -A
git commit -m "Phase 1.0: 基盤構築（Supabase接続・dev/prod Flavor・CI）"
```

## 7. CI（仕様書 1-12）

`.github/workflows/ci.yml` を配置済み。GitHub に push すると、`main` への push / PR で
**analyze → test → debug ビルド** が走ります（実鍵不要・接続テストなし）。

- GitHub 側の追加設定は基本不要（Secrets も不要）。
- CI では `.env.example` をダミーの `.env.dev/.env.prod` にコピーしてビルドします。

---

## 完了判定チェックリスト

- [ ] Supabase に dev / prod の2プロジェクトが存在する
- [ ] `flutter run --flavor dev -t lib/main_dev.dart` で起動する
- [ ] 起動画面に「環境：dev」「Supabase接続：OK」
- [ ] `--flavor prod` で「環境：prod」に切り替わる
- [ ] APIキーがソース直書きでなく、`.env` が Git 管理外（`git status` で確認）
- [ ] `flutter analyze` がエラー0
- [ ] GitHub push で CI が緑
- [ ] `lib/core` / `lib/features` / `lib/shared` のフォルダ構成がある

---

## 既知の留意点（本番化前に対応）

- **パッケージID**: 現在 `com.example.*` のまま（Phase 1.0 ではビルド安全性を優先）。本番化前に
  Android（`namespace`/`applicationId` + `MainActivity.kt` の package・配置）と iOS（bundle id）を
  独自ドメインに変更してください。
- **Web 非対象**: 接続確認は `dart:io` を使うため Phase 1 は iOS/Android 想定です。
- 次フェーズ（1.1 ログイン → 1.2 現場一覧 → 1.3 写真管理）は、この基盤が緑になってから着手します。
