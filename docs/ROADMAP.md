# 現場OS Lite 開発ロードマップ（開発〜ローンチ）

> このドキュメントは **AIへの引き継ぎ（メモリ）用**です。新しいAI（ChatGPT等）に貼って
> 「続きから始めます」と言えば、現在地から再開できるように作っています。
> **再開時のお願い（AIへ）**: まず「★現在地」を確認し、未完了の直近ステップから1つずつ案内すること。
> ユーザーは開発初心者。**一度に1手順だけ**提示する。

最終更新: 2026-06-21

---

## 0. このプロジェクトは何か

- **プロダクト名**: 現場OS Lite（仮称） / リポジトリ名 `genba_os_lite`
- **対象ユーザー**: 中小建設企業（現場で働く職人・監督）
- **目的**: 建設現場の業務をスマホで支援するアプリ。全10フェーズの開発ロードマップの土台から作る。
- **プラットフォーム**: iOS / Android（モバイル中心。Webは当面非対象）
- **バックエンド**: Supabase（dev / prod の2環境）
- **最優先要件**: `docs/Phase1_基盤構築_詳細仕様.pdf`（Phase1=基盤構築の詳細仕様）

---

## 1. 技術スタックと確定バージョン（pub.dev 2026-06 検証済み）

| パッケージ | バージョン | 用途 |
|---|---|---|
| supabase_flutter | ^2.15.0 | Supabase SDK。初期化は `Supabase.initialize(url:, publishableKey:)`（`anonKey`は非推奨） |
| flutter_riverpod | ^3.3.2 | 状態管理（**3.x**: AsyncNotifier前提。`.map/.when`はfreezed側で廃止） |
| go_router | ^17.3.0 | ルーティング（認証リダイレクト） |
| flutter_dotenv | ^6.0.1 | `.env.dev`/`.env.prod` 読込 |
| freezed / freezed_annotation | ^3.2.5 / ^3.1.0 | モデル生成（**3.x**: `abstract`/`sealed`必須） |
| json_serializable / json_annotation | ^6.14.0 / ^4.12.0 | JSON変換 |
| build_runner | ^2.15.0 | コード生成ランナー |
| （写真）image_picker / flutter_image_compress / cached_network_image / path_provider / uuid / connectivity_plus | 1.2.2 / 2.4.0 / 3.4.1 / 2.1.6 / 4.5.3 / 7.1.1 | Phase 1.3 で追加 |
| intl | ^0.20.2 | 日本語日付（現場一覧） |

- Dart SDK 制約: `^3.12.2`
- **採用しない**: hooks_riverpod / flutter_hooks（plain `ConsumerWidget` で統一）
- Riverpod codegen（@riverpod）は任意（必要になれば導入）

---

## 2. アーキテクチャ方針（feature-first）

```
lib/
├── main_dev.dart / main_prod.dart   # 環境別エントリポイント（main.dartはdevフォールバック）
├── bootstrap.dart                    # dotenv→AppConfig→Supabase.initialize→runApp
├── app.dart                          # MaterialApp.router
├── core/      config / supabase / router / theme / error / logging   # 横断インフラ
├── shared/    widgets / extensions / utils                            # 再利用UI・ヘルパー
└── features/<feature>/
    ├── presentation/  画面・ウィジェット（ConsumerWidget。ロジック/Supabase直叩き禁止）
    ├── application/   Riverpod Provider / Notifier（状態・オーケストレーション）
    └── data/          repository（抽象+Supabase実装）+ freezedモデル
```
- 依存方向は `presentation → application → data` の一方向。
- **SupabaseClientに触れるのはdata層のrepositoryだけ**（Providerで注入→テスト差し替え可）。

---

## 3. 重要な決定事項（変えないこと）

1. **スコープ=レイヤー方式**: PDFのPhase1は「基盤のみ」。ログイン/現場/写真は後続層として基盤の上に積む。
2. **フェーズごとにGitコミットを分割**する。
3. **写真は最小・楽観的**: 撮影→端末保存で即時表示→オンライン時アップロード→オフラインは後で再送。
   SQLite/driftの永続キュー・バックグラウンド同期・geo・resumableは **Phase 1.3では作らず後送り**。
4. **秘密情報**: アプリに入れるのは anon/publishable key のみ。**service_role は絶対に入れない**。
   `.env.dev`/`.env.prod` はGit管理外（`.env.example`のみコミット）。
5. **マルチテナント**: 全テーブルに `company_id` + RLS（`current_company_id()` security-definer関数）。
   写真Storageパスは必ず `{company_id}/{site_id}/{photo_id}.jpg`。

---

## 4. 全体ロードマップ（Phase 1 → ローンチ）

凡例: ✅完了 / 🔄進行中 / ⬜未着手 / 💤後送り

### ■ Phase 1：基盤＋初期機能（あなたの「Phase1」＝レイヤー方式）

| サブ | 内容 | 完了条件 | 状態 |
|---|---|---|---|
| **1.0 基盤構築** | Supabase接続・dev/prod Flavor・主要ライブラリ・CI・接続OK画面 | 下の「Phase1.0 完了判定」全YES | ✅ **完了**（iOSで dev/prod とも起動・接続OK確認済み 2026-06-21） |
| **1.1 認証/ログイン** | companies/profiles + RLS + ログイン画面 + go_router認証ガード | ログイン→Homeへ遷移、未ログインは/loginへ | ✅ **完了**（dev実機でログイン/ログアウト/セッション維持を確認 2026-06-21。prodは本番化前に同手順を適用） |
| **1.2 現場一覧** | sitesテーブル+RLS、Siteモデル、一覧/作成/詳細画面 | 自社の現場のみ一覧表示・タップで詳細 | ✅ **完了**（dev実機で 現場作成/一覧/詳細/RLS を確認 2026-06-21） |
| **1.3 写真管理** | photosテーブル+プライベートバケット+Storage RLS、撮影/選択→アップロード→一覧表示 | 現場に写真を保存・表示（自社のみ） | ✅ **完了**（dev実機で 写真アップロード/表示/RLS を確認 2026-06-21。MVP=楽観的アップロード。永続キュー等はPhase 4） |

### ■ Phase 2〜10：ローンチまで（想定。PDF未定義のため、各Phase着手時に詳細化）

| Phase | 内容 | 主なゴール | 状態 |
|---|---|---|---|
| **2. 日報機能** | reports+RLS、日報の作成・一覧・詳細・編集（現場ごと） | 現場ごとに日報を記録・閲覧 | ✅ **完了**（dev実機で 作成/一覧/詳細/編集/RLS を確認 2026-06-22。詳細仕様書準拠） |
| **3. 現場管理の拡充** | 現場の登録/編集/状態管理、メンバー割当 | 現場CRUDが一通り完成 | ⬜ |
| **4. 写真の本格化** | 永続オフラインキュー、バックグラウンド同期、アルバム/タグ、geo | 電波が悪い現場でも確実に同期 | ⬜（💤の機能を回収） |
| **5. 通知・連携** | プッシュ通知、現場内コミュニケーション | 重要更新を通知 | ⬜ |
| **6. 帳票・出力** | 報告書/写真台帳のPDF出力・共有 | 現場記録を成果物として出力 | ⬜ |
| **7. 組織・権限管理** | 招待フロー、ロール（owner/admin/member）、管理画面 | 会社単位で安全に運用 | ⬜ |
| **8. 品質強化** | テスト網羅、クラッシュ監視、パフォーマンス、アクセシビリティ | リリース品質に到達 | ⬜ |
| **9. ベータ検証** | TestFlight / Google Play内部テスト配信、社内ドッグフード | 実機ベータで重大バグ0 | ⬜ |
| **10. ストア公開・ローンチ** | アイコン/署名/ストア申請（App Store・Google Play）、運用体制 | 本番リリース | ⬜ |

---

## 5. ★現在地（YOU ARE HERE）

- **🎉 Phase 1 ＋ Phase 2（日報機能）完了 ✅** — 1.0 基盤 / 1.1 認証 / 1.2 現場一覧 / 1.3 写真管理 / 2. 日報 すべて dev実機で検証済み。次は **Phase 3（現場管理の拡充）**。
- Phase 2（日報機能・詳細仕様書準拠）: dev に reports テーブル+RLS+updated_atトリガを適用済み。**dev実機で 日報の作成→一覧→詳細→編集（2人→3人で更新日時更新）→RLS を目視確認**（2026-06-22）。`flutter analyze`=No issues / `flutter test`=41件緑。
- **本番化前の残タスク（運用・コード変更不要）**: prod の Supabase に 0001(認証) / 0002(sites) / 0003(photos+bucket) / 0004(reports) を順に適用（[docs/SUPABASE_AUTH_SETUP.md](SUPABASE_AUTH_SETUP.md) + [supabase/migrations/](../supabase/migrations/)）。
- **実装メモ**: feature-first。Repositoryは抽象interface＋Supabase実装でテスト差し替え可。日報フォームは S2作成/S4編集を共有、autoDispose Controller、書き込みは toJson 不使用でマップ明示構築（report_date は yyyy-MM-dd 送信）。company_id/created_by はサーバ既定値に任せる。
- **次にやること**: Phase 3（現場管理の拡充）。現場の編集/状態管理・メンバー割当 等。着手時に詳細化。
- **チャットが切れた時の再開方法**: 新しいClaudeチャットで「`docs/ROADMAP.md` を読んで、続きから1ステップずつ案内して」と言う。

### Phase 1.0 手作業チェックリスト（これを全部 ✅ にすれば 1.0 完了）

| # | 手順 | 状態 |
|---|---|---|
| 1 | Supabase dev プロジェクト作成（genba-os-dev） | ✅ |
| 2 | dev の Project URL と 公開鍵(anon/publishable) を取得 | ✅ |
| 3 | Supabase prod プロジェクト作成（genba-os-prod） | ✅ |
| 4 | prod の Project URL と 公開鍵 を取得 | ✅ |
| 5 | `.env.dev` / `.env.prod` に値を貼る → `git status`で漏れ確認 | ✅ |
| 6 | `flutter doctor`（Flutter✓ / Xcode✓ / device✓。Androidは未導入＝iOS優先で飛ばす） | ✅ |
| 7 | `flutter pub get` | ✅ |
| 8 | `dart run build_runner build`（freezed生成） | ✅ |
| 9 | analyze エラー0 → `dart analyze` で `No issues found!` ✅（`flutter analyze`はローカルの日本語パス不具合でクラッシュ／CIは英語パスで通る） | ✅ |
| 10 | `flutter test`（緑） | ✅ All tests passed!（6件） |
| 11 | （Android）`flutter run --flavor dev` 起動確認 | 💤 後回し（Android SDK未導入／iOS優先） |
| 12 | （Android）`--flavor prod` 切替確認 | 💤 後回し |
| 13 | iOS: 依存解決は **Swift Package Manager**（Podfile不要と判明。flavor xcconfigは`#include?`でPods無しでも安全） | ✅ |
| 14 | iOS: Build Configuration 6つ作成（`xcodeproj` gem で自動化。計9種） | ✅ |
| 15 | iOS: 各configに xcconfig 紐付け＋bundle id直書きを削除（xcconfigの`.dev`が効く） | ✅ |
| 16 | iOS: 共有 scheme `dev`/`prod` 作成＋アクション割当（`xcodeproj` gem で自動化） | ✅ |
| 17 | iOS: `flutter run --flavor dev/prod` → dev/prod とも「接続OK」目視確認 | ✅ |
| 18 | Phase 1.0 を Git コミット＆ push（`55f9a8a Phase 1.0: 基盤構築`） | ✅ 2026-06-21 push済み。**CIゲートはAnalyze+Testのみ**（Androidビルドは後回し方針に合わせCIから除外。Android着手時に`ci.yml`のコメントから復活させる） |

> 詳しい手順は [docs/SETUP.md](SETUP.md) を参照。iOS（13〜17）が最難関。

> ⚠️ **既知の環境問題（日本語パス）**: プロジェクトが `/Users/shukura/建設AI/...` という**日本語フォルダ名**配下にあるため、
> `flutter analyze` とVSCodeの解析サーバーがクラッシュする（`dart analyze` は回避可）。**iOSビルド（CocoaPods/Xcode）でも
> トラブルになりやすい**ため、#13（pod install）の前に **`建設AI` を英語名（例 `kensetsu-ai`）にリネーム**するのを推奨。
> リネーム後は VSCode で新パスのフォルダを開き直し、新しいターミナルから再実行する。この ROADMAP.md が進捗の引き継ぎ元。

---

## 6. Phase 1.0 完了判定（PDF準拠）

- [ ] Supabaseに dev / prod の2プロジェクトが存在
- [ ] `flutter run --flavor dev` で起動
- [ ] 起動画面に「環境：dev」「Supabase接続：OK」
- [ ] `--flavor prod` で「環境：prod」に切替
- [ ] APIキー直書きなし・`.env`がGit管理外（`git status`で確認）
- [ ] `flutter analyze` エラー0
- [ ] GitHub push で CI が緑
- [ ] `lib/core / features / shared` のフォルダ構成

---

## 7. 現状サマリ（コード側）

- ✅ Phase 1.0 のコードは実装＆レビュー済み。flutter導入済みで `analyze`/`test` 緑を実機再検証済み。
- ✅ 2026-06-21 に GitHub へ push 済み（`55f9a8a`）。残りは iOS設定(#13〜#17)のみで Phase 1.0 完了。
- ⬜ Phase 1.1 以降は未着手。
- リポジトリ: `/Users/shukura/kensetsu-ai/genba_os_lite`（gitはこのディレクトリがルート）。リモート: github.com/shukura19960114-wq/genba-os-lite
