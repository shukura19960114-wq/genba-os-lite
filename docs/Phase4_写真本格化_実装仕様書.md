# Phase 4 写真機能の本格化 — 実装仕様書（最小工数）

**作成日:** 2026-06-23　／　元資料: [docs/Phase4_写真本格化_要件定義.md](Phase4_写真本格化_要件定義.md)
**方針:** 既存 photos 実装を踏襲。**DB変更なし・新規依存なし**。複数選択/拡大/日時/ギャラリーをUX追加。

---

## 0. スコープ（確定）
- ✅ 複数写真（ライブラリ複数選択）／拡大表示（全画面・スワイプ・ピンチズーム）／撮影日時表示（=`created_at`）／一覧改善／現場別ギャラリー
- ❌ AI解析・GPS・動画・PDF・写真削除・オフライン同期（対象外）

## 1. 追加・変更ファイル一覧
```
変更:
  lib/features/photos/data/image_picker_service.dart        # pickMultiple() 追加
  lib/features/photos/application/photo_upload_controller.dart # addPhotos() 追加
  lib/features/sites/presentation/site_detail_screen.dart   # 写真セクション: 枚数/tap拡大/複数追加/「すべて見る」
  lib/core/router/app_routes.dart                           # gallery / viewer ルート
  lib/core/router/app_router.dart                           # ルート登録
  test/photos/fakes.dart                                    # FakeImagePickerService に pickMultiple、FakePhotoRepository に upload回数

追加:
  lib/features/photos/presentation/photo_gallery_screen.dart  # P-Gallery（現場の全写真）
  lib/features/photos/presentation/photo_viewer_screen.dart   # P-Viewer（全画面・スワイプ・ズーム）
  test/photos/photo_upload_controller_multi_test.dart         # addPhotos のテスト

DBマイグレーション: なし / 新規依存: なし / Supabase手作業: なし
```

## 2. ImagePickerService（変更）

`pickMultiple()` を追加（image_picker の `pickMultiImage`。カメラは従来どおり1枚）。

```dart
abstract interface class ImagePickerService {
  Future<Uint8List?> pick(PhotoSource source);          // 既存（カメラ/ライブラリ1枚）
  Future<List<Uint8List>> pickMultiple();               // 追加（ライブラリ複数）
}

// 実装
@override
Future<List<Uint8List>> pickMultiple() async {
  final files = await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 80);
  final result = <Uint8List>[];
  for (final f in files) {
    result.add(await f.readAsBytes());
  }
  return result; // キャンセル時は空リスト
}
```

## 3. PhotoUploadController（変更）

`addPhotos()` を追加（複数選択→`uploadPhoto` をループ→`photosProvider(siteId)` を invalidate）。既存 `addPhoto`（カメラ1枚）は維持。

```dart
/// 追加結果（追加枚数 / 失敗枚数 / キャンセル）
typedef PhotosAddResult = ({int uploaded, int failed, bool cancelled});

Future<PhotosAddResult> addPhotos({
  required String siteId,
  required String companyId,
}) async {
  state = const AsyncValue.loading();
  final bytesList = await ref.read(imagePickerServiceProvider).pickMultiple();
  if (bytesList.isEmpty) {
    state = const AsyncValue.data(null);
    return (uploaded: 0, failed: 0, cancelled: true);
  }
  var uploaded = 0, failed = 0;
  Object? lastError;
  StackTrace? lastSt;
  for (final bytes in bytesList) {
    try {
      await ref.read(photoRepositoryProvider)
          .uploadPhoto(siteId: siteId, companyId: companyId, bytes: bytes);
      uploaded++;
    } catch (e, st) {
      failed++; lastError = e; lastSt = st;
    }
  }
  ref.invalidate(photosProvider(siteId));
  state = (failed > 0 && uploaded == 0)
      ? AsyncValue.error(lastError!, lastSt!)
      : const AsyncValue.data(null);
  return (uploaded: uploaded, failed: failed, cancelled: false);
}
```
- 画面側：結果で SnackBar（例「3枚追加しました」「2枚追加・1枚失敗」「追加に失敗しました」）。

## 4. Repository（任意・性能用）
- **必須変更なし**。一覧表示は既存 `photoUrlProvider.family(path)`（タイルごとに署名URL）を継続。
- 任意最適化：`createSignedUrls(List<String> paths)`（Storage一括署名）を足し、ギャラリーで一括取得してもよい。**MVPでは不要**。

## 5. 画面仕様

### 5-1. 現場詳細の写真セクション（変更）
- ヘッダ：`写真 (N)` … N=`photosProvider(siteId)` の件数。右に「すべて見る」（→ P-Gallery）と「追加」。
- 追加ボタン → ボトムシート：
  - **カメラで撮影**（1枚）→ 既存 `addPhoto(source: camera)`
  - **フォトライブラリから選択**（複数）→ **`addPhotos()`**
- グリッド：先頭 最大6枚程度を表示（残りは「すべて見る」へ）。各タイル tap → **P-Viewer**（その index から）。
- 既存の `_PhotoTile`（署名URL→`Image.network`）を流用。

### 5-2. P-Gallery（現場写真ギャラリー・追加）`PhotoGalleryScreen(siteId)`
- AppBar：`現場の写真`（任意で件数）。actions に「追加」。
- body：`photosProvider(siteId)` を `.when`：
  - loading: 中央スピナー
  - error: 中央「写真の取得に失敗しました」＋再読み込み（`invalidate`）
  - data 空: 「写真がありません」＋追加導線
  - data: `RefreshIndicator` + `GridView`（3列・新しい順）。タイル tap → P-Viewer（index）
- pull-to-refresh：`invalidate(photosProvider(siteId))` → `await read(...future)`。

### 5-3. P-Viewer（写真拡大ビューア・追加）`PhotoViewerScreen(siteId, initialIndex)`
- ConsumerStatefulWidget。`photosProvider(siteId)` を watch。
- 本体：`PageView.builder`（`PageController(initialPage: initialIndex)`、`onPageChanged`で`_index`更新）
  - 各ページ：`InteractiveViewer`（ピンチズーム）＋ `photoUrlProvider(photo.path)` を `.when` → `Image.network`（contain）/ローディング/エラー。
- 上部 AppBar：タイトル `${_index+1} / ${photos.length}`。
- 下部オーバーレイ：**撮影日時** `DateFormat('yyyy/MM/dd HH:mm').format(photo.createdAt!.toLocal())`（null は `—`）。
- 背景は黒（`Scaffold(backgroundColor: Colors.black)`）。

## 6. ルート（app_routes.dart / app_router.dart）
```dart
// RoutePaths
static const sitePhotos     = '/sites/:id/photos';
static const sitePhotoView  = '/sites/:id/photos/:index';   // index = 一覧内の位置
// RouteNames: sitePhotos / sitePhotoView

// app_router.dart（siteEdit の後あたり。'/photos' を '/photos/:index' より先に登録）
GoRoute(path: RoutePaths.sitePhotos, name: RouteNames.sitePhotos,
  builder: (c, s) => PhotoGalleryScreen(siteId: s.pathParameters['id']!)),
GoRoute(path: RoutePaths.sitePhotoView, name: RouteNames.sitePhotoView,
  builder: (c, s) => PhotoViewerScreen(
    siteId: s.pathParameters['id']!,
    initialIndex: int.tryParse(s.pathParameters['index'] ?? '0') ?? 0,
  )),
```
- 遷移：詳細/ギャラリーのタイル tap → `context.push('/sites/$siteId/photos/$index')`。「すべて見る」→ `context.push('/sites/$siteId/photos')`。
- 既存 `/sites/:siteId/reports...`・`/sites/:id/edit` とはリテラルが異なり衝突なし。

## 7. テスト（test/photos/）
- `fakes.dart`：
  - `FakeImagePickerService` に `pickMultiple()`（`multi` リストを返す。空も設定可）。
  - `FakePhotoRepository`：`uploadPhoto` 呼び出し回数（`uploadCount`）と `failOnUpload`。
- `photo_upload_controller_multi_test.dart`：
  - 複数成功 → `uploaded == 件数`・`failed==0`・`uploadCount==件数`
  - 空選択 → `cancelled==true`・`uploadCount==0`
  - 全失敗（failOnUpload）→ `failed==件数`・state エラー
- 既存テスト（43件）が緑のまま。
- 拡大ビューア/ギャラリーの画像描画は dev 実機確認に委ねる。

## 8. 実装手順（推奨順）
1. `ImagePickerService.pickMultiple()` 追加 → Fake 更新（analyzeが通る状態）
2. `PhotoUploadController.addPhotos()` 追加
3. `PhotoGalleryScreen` / `PhotoViewerScreen` 追加
4. ルート追加（app_routes / app_router）
5. 現場詳細の写真セクション改修（枚数・tap拡大・複数追加・すべて見る）
6. テスト（addPhotos）
7. `flutter analyze` / `flutter test` 緑
8. iOSビルド → 実機で 複数追加 / 拡大スワイプ / 日時 / ギャラリー を確認
9. commit/push（**DB作業なし**＝ユーザーのSQL不要）

## 9. 完了条件
複数追加成功 / 拡大表示成功（スワイプ・ズーム）/ 撮影日時表示 / 現場別ギャラリー / RLS維持 / analyze・test / dev実機。

## 10. 工数見積もり
| タスク | 人日 | 実時間目安 |
|---|---|---|
| pickMultiple + Fake | 0.2 | 🤖 |
| addPhotos（ループupload） | 0.3 | 🤖 |
| P-Gallery | 0.4 | 🤖 |
| P-Viewer（PageView+Zoom+日時） | 0.6 | 🤖 |
| 詳細セクション改修 | 0.4 | 🤖 |
| ルート | 0.1 | 🤖 |
| テスト | 0.3 | 🤖 |
| analyze/test/ビルド/実機 | 0.5 | 🤖+🧑 |
| **合計** | **約2.8人日** | 🤖 実装 **約35〜50分** ＋ 🧑 実機確認 **約5分**（DB作業なし） |
