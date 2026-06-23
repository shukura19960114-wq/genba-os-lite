# Phase 4 写真機能の本格化 — 要件定義書

**作成日:** 2026-06-23　／　**対象:** Phase 4「写真機能の本格化」
**目的:** 建設会社が**現場写真を実用レベルで管理**できるようにする（複数追加・拡大表示・日時・整理）。

> ※ ROADMAP の元 Phase 4（永続オフラインキュー／バックグラウンド同期／geo）は、本ブリーフにより
> **「写真管理UXの本格化」へ再スコープ**。オフライン同期・geo は後続フェーズへ送る（GPSは明示的に対象外）。

---

## スコープ

### ✅ 実装する（候補より確定）
- **複数写真対応**：ライブラリから**一度に複数選択**してまとめてアップロード
- **写真拡大表示**：タップで**全画面ビューア**（左右スワイプで切替・ピンチズーム）
- **撮影日時表示**：各写真に日時を表示（= `photos.created_at` ＝**アップロード日時**。後述）
- **写真一覧改善**：枚数表示・新しい順・読み込み/空/エラー状態の整備
- **現場別整理**：現場ごとの**写真ギャラリー画面**（全件をまとめて閲覧）

### ❌ 実装しない（指示）
- AI解析 ／ GPS（位置情報・EXIF GPS） ／ 動画 ／ PDF
- （再スコープにより）オフライン永続キュー・バックグラウンド同期も本フェーズ対象外

### 「撮影日時」についての確定事項（重要）
- 現テーブルは `created_at`（**サーバ保存＝アップロード日時**）のみ保持。
- **MVPでは `created_at` を「撮影日時」として表示**する（DB変更なし・新規依存なし）。
- 真の撮影日時（EXIF `DateTimeOriginal`）は、新カラム `captured_at` ＋ EXIF解析パッケージが必要で、
  GPS等の「メタデータ抽出」領域に踏み込むため**本フェーズでは行わない**（将来オプション。付録）。

---

## 現状サマリ（既存実装）

| 既存 | 内容 |
|---|---|
| `photos` テーブル / RLS / Storage(private) | ✅ あり（id/site_id/company_id/path/created_at）。現場別・複数行で保存済み |
| `PhotoRepository` | `listPhotos(siteId)` / `uploadPhoto(単写真)` / `createSignedUrl(path)` |
| `ImagePickerService` | `pick(source)` … **1枚ずつ**（`pickImage`、maxWidth1600/quality80） |
| Provider | `photosProvider.family(siteId)` / `photoUrlProvider.family(path)` |
| Controller | `PhotoUploadController.addPhoto(...)` … 1枚 |
| UI | 現場詳細の写真セクション（3列グリッド＋追加ボタン。タップ拡大なし） |

> 不足：複数選択・全画面拡大・日時表示・専用ギャラリー。**DBは十分**（複数写真は既に表現可能）。

---

# 要件定義（指定7項目）

## 1. ユーザーストーリー
1. 監督として、**ライブラリから複数枚をまとめて**現場に追加したい（1枚ずつは面倒）。
2. 一覧の写真を**タップで大きく表示**し、**左右スワイプで次々確認**したい（細部を見たい）。
3. 各写真が**いつのものか（日時）**を知りたい。
4. 現場の写真が増えても、**現場ごとに整理されたギャラリー**で見返したい（枚数も把握）。
5. これらは引き続き**自社の写真のみ**（他社の写真は見えない／RLS維持）。

## 2. DB変更有無
**変更なし（マイグレーション不要）** ✅
- 複数写真：既存テーブルに複数行で対応済み。
- 拡大表示・日時・整理：すべて既存カラム（`path` / `created_at`）と署名付きURLで実現。
- 新規カラム・新規テーブル・トリガ：なし。Supabase での SQL 実行も**不要**。
- （EXIF `captured_at` を採用する場合のみ DB変更が発生するが、本フェーズは**非採用**）

## 3. 画面一覧

| # | 画面 | 区分 | 主な要素 |
|---|---|---|---|
| P-Section | 現場詳細の写真セクション | 変更 | 枚数表示／タイルtapで拡大ビューアへ／追加ボタンを**カメラ＝1枚・ライブラリ＝複数**に拡張／「すべて見る」→ギャラリー |
| P-Gallery | **現場写真ギャラリー** | 追加 | 現場の全写真をグリッド表示（新しい順・枚数・空/エラー・pull-to-refresh）。タイルtapで拡大 |
| P-Viewer | **写真拡大ビューア** | 追加 | 全画面。`PageView`で左右スワイプ切替＋`InteractiveViewer`でピンチズーム。上部/下部に**撮影日時（created_at）**と「n/N」表示 |

### 画面遷移
```
現場詳細 ─[写真タイルtap]→ P-Viewer（その写真から開始・スワイプ切替）
現場詳細 ─[すべて見る]→ P-Gallery ─[タイルtap]→ P-Viewer
現場詳細/ギャラリー ─[追加]→ カメラ(1枚) / ライブラリ(複数) → アップロード → 一覧更新
```

## 4. Repository構成
既存 `PhotoRepository` を流用し、**バッチ署名URLのみ追加（任意・性能用）**：

```dart
// 既存（変更なし）
Future<List<Photo>> listPhotos(String siteId);
Future<Photo> uploadPhoto({required siteId, required companyId, required bytes, ...}); // 1枚
Future<String> createSignedUrl(String path, {int expiresInSeconds});

// 追加（任意・ギャラリーで多数表示時の効率化）
Future<Map<String,String>> createSignedUrls(List<String> paths, {int expiresInSeconds});
```
- **複数アップロードは Repository を増やさず、Controller で `uploadPhoto` をループ**呼び出し（最小実装）。
- `createSignedUrls`（Supabase Storage の一括署名）は任意。未採用なら既存 `photoUrlProvider.family(path)` を継続使用。

### ImagePickerService（変更）
```dart
// 既存
Future<Uint8List?> pick(PhotoSource source);          // 1枚（カメラ/ライブラリ）
// 追加
Future<List<Uint8List>> pickMultiple();               // ライブラリ複数（image_picker の pickMultiImage）
```
> `pickMultiImage` は image_picker 既存機能 → **新規依存なし**。ピンチズーム＝`InteractiveViewer`、スワイプ＝`PageView`（いずれも標準）。

## 5. Riverpod構成
**新規Providerは追加しない（既存構成の再利用を最優先）。** ギャラリー/ビューアとも既存2つだけで実装可能。
- `photosProvider.family(siteId)`：一覧・PageViewの元データ・**枚数（`photos.length`）**・日時（`createdAt`）・pull-to-refresh の invalidate 対象。
- `photoUrlProvider.family(path)`：各タイル/各ページの署名付きURL。
- `PhotoUploadController` に **`addPhotos(...)` をメソッド追加**（複数選択→ループupload→`photosProvider(siteId)` を invalidate）。※既存 `photoUploadControllerProvider` を流用、新Providerではない。既存 `addPhoto`（カメラ1枚）は維持。
- ビューアの現在indexは**画面ローカル state（`PageController`）**で保持（Providerにしない）。
- 枚数用の `photoCountProvider` は**作らない**（`photosProvider` のデータ件数で表示）。

## 6. 完了条件
| # | 完了条件 | 確認方法 |
|---|---|---|
| 1 | 複数写真追加成功 | ライブラリで複数選択→一括アップロード→グリッドに反映 |
| 2 | 写真拡大表示成功 | タイルtap→全画面、左右スワイプで切替、ピンチズーム可 |
| 3 | 撮影日時表示成功 | ビューア（および一覧）に各写真の日時が出る |
| 4 | 現場別整理成功 | ギャラリーで現場の全写真を新しい順＋枚数表示 |
| 5 | RLS確認 | 自社の写真のみ表示・アップロード（company_id制御維持） |
| 6 | analyze成功 / test成功 | `flutter analyze` No issues ／ `flutter test` 全件パス |
| 7 | dev実機確認成功 | iOSシミュレータで 1〜4 を目視確認（複数選択・拡大はライブラリで） |

## 7. テスト条件
- **ImagePickerService（Fake）**：`pickMultiple()` が複数バイト列を返す／空（キャンセル）。
- **PhotoUploadController.addPhotos**：
  - 複数成功 → `uploadPhoto` が選択枚数ぶん呼ばれ、結果が成功枚数を返す
  - 空選択（キャンセル）→ アップロードされない
  - 一部/全失敗 → 失敗が結果に反映、state がエラー
- **PhotoRepository（Fake）**：`uploadPhoto` 呼び出し回数・`listPhotos` 反映を検証。
- **（任意）ギャラリー widget**：data（複数）でタイル数一致／empty 表示。
- 既存テスト（43件）が**引き続き緑**であること。
- ＊全画面ビューアの画像描画（`Image.network`＋署名URL）は実機確認に委ね、ユニットは data 層・Controller を中心にする。

---

## 付録：将来オプション（本フェーズ非対象）
- **真の撮影日時（EXIF DateTimeOriginal）**：`photos.captured_at` 追加 ＋ EXIF解析。表示は created_at から captured_at に切替。
- **写真削除**：Storage実体＋DB行の削除（現場削除と同様、事故/巻き添えに配慮して権限とセットで検討）。
- **アルバム/タグ・オフライン永続キュー・バックグラウンド同期**：後続フェーズ。

---

> 次ステップ：この要件で良ければ、Phase 2/3 と同様に**最小工数の実装仕様書**（ファイル一覧・各メソッド・画面詳細）を作成 → 承認後に実装。
