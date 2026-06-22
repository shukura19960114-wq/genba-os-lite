# Phase 3 現場管理の拡充 — 要件定義 & 実装仕様書（MVP・最小工数）

**作成日:** 2026-06-22　／　**対象:** Phase 3「現場管理の拡充」　／　**方針:** 最小工数で「現場CRUD一通り完成」。DB変更なし。

---

## 現状サマリ（実装確認の結果）

| 既存 | 状態 |
|---|---|
| `sites` テーブル / RLS | ✅ あり。**update / delete の RLS ポリシーも既存**（0002_sites.sql）。`status` カラムあり（active/completed/suspended） |
| `Site` モデル | ✅ id / companyId / name / address / status / createdAt。`siteStatusLabel()`（進行中/完了/中止）も実装済み |
| `SiteRepository` | `fetchSites` / `fetchSite` / `createSite` のみ（**update/delete 未実装**） |
| 画面 | 一覧 / 作成 / 詳細（詳細にステータス表示・日報導線・写真あり） |
| CRUD 充足度 | Create ✅ / Read ✅ / **Update ❌ / Delete ❌** |

> 結論：Phase 3 の核は **Update（編集＝名称/住所/ステータス）と Delete**。これは **DB変更不要**（RLS・カラムが既にあるため）でコードのみ。

---

# Part 1. 要件定義

## スコープ（やること / やらないこと）

| やること（Phase 3 MVP） | やらないこと（理由） |
|---|---|
| 現場の**編集**（名称・住所・ステータス） | **メンバー割当** → 新テーブル `site_members` 要・Phase 7（権限/招待）と統合が自然。本MVPでは対象外 |
| **ステータス変更**（進行中→完了→中止 等） | 招待フロー・ロール（owner/admin/member）・管理画面 → Phase 7 |
| 現場の**削除**（確認ダイアログ付き） | 並べ替え・検索・絞り込み → 後続 |
| 自社のみ編集/削除（RLS） | 写真の本格化（Phase 4）・PDF（Phase 6）・通知（Phase 5） |

> ※「メンバー割当」は ROADMAP の Phase 3 に含まれるが、**最小工数MVPでは外す**（新DB＋メンバー一覧UI＋権限の議論が必要なため）。必要なら Phase 3.5 として別途仕様化する（本書 付録B）。

## 1. ユーザーストーリー

1. 監督として、登録済みの現場の**名称・住所を後から修正**したい。
2. 現場の進捗に応じて**ステータスを「進行中／完了／中止」に変更**したい。
3. 誤って登録した現場や終わった現場を**削除**したい（確認のうえ）。
4. 自社の現場だけを編集・削除でき、**他社の現場は操作できない**（RLS）。

## 2. DB変更有無

**変更なし（マイグレーション不要）** ✅
- `sites` の `status` カラム・update/delete の RLS は 0002_sites.sql に既存。
- 削除時は FK `on delete cascade` により、その現場の **reports / photos も連動削除**される（仕様として許容。UIの確認ダイアログで「関連する日報・写真も削除されます」と明記）。
- ストレージ実体（写真ファイル）の削除は本MVPでは行わない（DB行のみ。孤児ファイルの掃除は後続フェーズ）。

## 3. 画面一覧

| # | 画面 | 区分 | 主な要素 |
|---|---|---|---|
| S-Edit | **現場編集** | 追加 | 名称（必須）・住所（任意）・**ステータス（ドロップダウン）**。更新ボタン |
| S-Detail | 現場詳細 | 変更 | AppBar に **編集（鉛筆）アイコン** と **削除（メニュー/アイコン）** を追加。削除は確認ダイアログ |
| S-List | 現場一覧 | 変更なし | ステータス Chip は既存（編集後に反映） |
| S-Create | 現場作成 | 変更なし | 既存のまま（status は作成時 active 既定） |

### 画面遷移
```
現場詳細(S-Detail) ─[鉛筆]→ S-Edit ─更新→ 詳細に戻る（詳細・一覧は再フェッチ）
現場詳細(S-Detail) ─[削除]→ 確認ダイアログ ─削除→ 一覧に戻る（一覧は再フェッチ）
```

## 4. Repository構成

既存 `SiteRepository`（抽象interface + Supabase実装）に **2メソッド追加**：

```dart
/// 現場を更新して更新後の行を返す。
Future<Site> updateSite({
  required String id,
  required String name,
  String? address,
  required String status,
});

/// 現場を削除（関連 reports/photos は FK cascade で連動削除）。
Future<void> deleteSite(String id);
```
- `company_id` は変更しない（送らない）。RLS が自社のみに制限。
- 既存 `FakeSiteRepository`（テスト）にも同2メソッドの実装追加が**必須**（IF変更のため）。

## 5. Riverpod構成

- 既存 `sitesListProvider` / `siteDetailProvider.family(id)` を流用（追加なし）。
- **追加: `SiteEditController`**（`AsyncNotifierProvider.autoDispose`、Phase 2 の Form Controller と同方針）
  - `Future<bool> update({required id, required name, address, required status})`
    - 成功時：`sitesListProvider` と `siteDetailProvider(id)` を invalidate → true
  - `Future<bool> delete(String id)`
    - 成功時：`sitesListProvider` を invalidate → true
  - 失敗時：state をエラーにし false（画面はSnackBar表示）

## 6. 完了条件

| # | 完了条件 | 確認方法 |
|---|---|---|
| 1 | 現場編集成功 | 名称/住所/ステータスを変更→更新→詳細・一覧に反映 |
| 2 | ステータス変更成功 | 進行中→完了 に変更→一覧Chip・詳細が変わる |
| 3 | 現場削除成功 | 削除→確認→一覧から消える |
| 4 | RLS確認 | 自社の現場のみ更新/削除可（company_id 制御） |
| 5 | analyze成功 | `flutter analyze` → No issues |
| 6 | test成功 | `flutter test` → 全件パス |
| 7 | dev実機検証 | iOSシミュレータで 1〜3 を目視確認 |

## 7. テスト条件

- **SiteEditController（必須）**: fake repo を override し
  - update 成功 → true・state エラーなし
  - update 失敗 → false・state エラー
  - delete 成功 → true
  - delete 失敗 → false・state エラー
- **FakeSiteRepository**: `updateSite` / `deleteSite` を実装（lastUpdated / deleteCalled / shouldThrow を記録）
- **（任意）S-Edit ウィジェット**: 既存値プリフィル、名称空でバリデーションエラー
- 既存テスト（Site.fromJson 等・41件）が**引き続き緑**であること

---

# Part 2. 実装仕様書（最小工数）

## 追加・変更ファイル一覧

```
変更:
  lib/features/sites/data/site_repository.dart        # updateSite / deleteSite 追加（IF + 実装）
  lib/features/sites/presentation/site_detail_screen.dart  # AppBar に編集/削除導線 + 確認ダイアログ
  lib/core/router/app_routes.dart                     # siteEdit パス/名追加
  lib/core/router/app_router.dart                     # /sites/:id/edit 登録
  test/sites/fakes.dart                               # FakeSiteRepository に update/delete

追加:
  lib/features/sites/application/site_edit_controller.dart  # SiteEditController（update/delete）
  lib/features/sites/presentation/site_edit_screen.dart    # S-Edit（名称/住所/ステータス）
  test/sites/site_edit_controller_test.dart

DBマイグレーション: なし
新規依存: なし
```

## 1) Repository（site_repository.dart）

抽象IFに追記し、`SupabaseSiteRepository` に実装：

```dart
// interface
Future<Site> updateSite({
  required String id,
  required String name,
  String? address,
  required String status,
});
Future<void> deleteSite(String id);

// SupabaseSiteRepository 実装
@override
Future<Site> updateSite({
  required String id,
  required String name,
  String? address,
  required String status,
}) async {
  final trimmed = address?.trim();
  final data = await _client
      .from('sites')
      .update({
        'name': name.trim(),
        'address': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        'status': status,
        // company_id は変更しない（送らない）
      })
      .eq('id', id)
      .select()
      .single();
  return Site.fromJson(data);
}

@override
Future<void> deleteSite(String id) async {
  await _client.from('sites').delete().eq('id', id);
}
```

## 2) Controller（site_edit_controller.dart・新規）

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/site_repository.dart';
import 'sites_providers.dart';

final siteEditControllerProvider =
    AsyncNotifierProvider.autoDispose<SiteEditController, void>(
  SiteEditController.new,
);

class SiteEditController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> update({
    required String id,
    required String name,
    String? address,
    required String status,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      await ref.read(siteRepositoryProvider).updateSite(
            id: id, name: name, address: address, status: status,
          );
    });
    state = result;
    if (result.hasError) return false;
    ref.invalidate(sitesListProvider);
    ref.invalidate(siteDetailProvider(id));
    return true;
  }

  Future<bool> delete(String id) async {
    state = const AsyncValue.loading();
    final result =
        await AsyncValue.guard(() => ref.read(siteRepositoryProvider).deleteSite(id));
    state = result;
    if (result.hasError) return false;
    ref.invalidate(sitesListProvider);
    return true;
  }
}
```

## 3) 画面（site_edit_screen.dart・新規）

- `SiteEditScreen(String siteId)` = ConsumerWidget。`ref.watch(siteDetailProvider(siteId)).when(...)`：
  - loading: Scaffold(AppBar「現場の編集」)+ 中央スピナー
  - error: Scaffold(AppBar「現場の編集」)+「現場の取得に失敗しました」+ 再読み込み（`ref.invalidate(siteDetailProvider(siteId))`）
  - data(site): `_SiteEditForm(site: site)` を返す（フォーム本体）
- `_SiteEditForm` = ConsumerStatefulWidget。initState で `site` から controllers / `_status` を初期化：
  - 名称 TextFormField（必須・既存 create と同じ validator「現場名を入力してください」）
  - 住所 TextFormField（任意）
  - **ステータス** `DropdownButtonFormField<String>`（初期=site.status）
    - 選択肢：`active`/`completed`/`suspended`（表示は `siteStatusLabel(code)`）
  - 更新ボタン FilledButton：`ref.watch(siteEditControllerProvider).isLoading` でスピナー化＆無効化
    - onPressed：`validate()` → `controller.update(id: site.id, name, address, status)` → true なら SnackBar「現場を更新しました」+ `context.pop()`
  - エラー監視：`ref.listen(siteEditControllerProvider, ...)` で AsyncError 時 SnackBar「更新に失敗しました。通信状況を確認して再度お試しください。」
  - キー：`Key('site_edit_name_field')` / `('site_edit_status_field')` / `('site_edit_submit_button')`

## 4) 現場詳細への導線（site_detail_screen.dart 変更）

- `AppBar(actions: [...])` に追加：
  - **編集**：`IconButton(Icons.edit)` → `context.push('/sites/$siteId/edit')`
  - **削除**：`IconButton(Icons.delete_outline)`（または PopupMenu）→ 確認ダイアログ
- 削除確認ダイアログ（`showDialog<bool>`）：
  - タイトル「現場を削除しますか？」本文「この現場に紐づく日報・写真も削除されます。元に戻せません。」
  - アクション：キャンセル / 削除（赤）
  - 「削除」選択時：`messenger` を退避 → `await ref.read(siteEditControllerProvider.notifier).delete(siteId)` → true なら `context.pop()`（一覧へ）+ SnackBar「現場を削除しました」/ false なら SnackBar「削除に失敗しました。…」
- `BuildContext` を await 跨ぎで使わない（messenger/navigator を事前退避）。go_router は import 済み。

## 5) ルート（app_routes.dart / app_router.dart）

```dart
// app_routes.dart
static const siteEdit = '/sites/:id/edit';      // RoutePaths
static const siteEdit = 'siteEdit';             // RouteNames

// app_router.dart（siteDetail の後に登録。segment数が違うため順序非依存）
GoRoute(
  path: RoutePaths.siteEdit,
  name: RouteNames.siteEdit,
  builder: (context, state) =>
      SiteEditScreen(siteId: state.pathParameters['id']!),
),
```
> 既存の `/sites/:siteId/reports...`（3〜4セグメント）とは別リテラルのため衝突なし。

## 6) テスト（test/sites/）

- `fakes.dart` の `FakeSiteRepository` に追加：
  ```dart
  bool deleteCalled = false;
  Site? lastUpdated;
  bool failOnUpdate = false; // or 共通 shouldThrow
  @override Future<Site> updateSite({required id, required name, address, required status}) async {
    if (failOnUpdate) throw Exception('update failed');
    return lastUpdated = Site(id: id, companyId: 'c', name: name, address: address, status: status);
  }
  @override Future<void> deleteSite(String id) async {
    if (failOnDelete) throw Exception('delete failed');
    deleteCalled = true;
  }
  ```
- `site_edit_controller_test.dart`：update 成功/失敗・delete 成功/失敗（ProviderContainer + override、autoDispose は listen で保持）。

## 7) 実装手順（推奨順）

1. Repository に update/delete 追加（IF+実装）→ `FakeSiteRepository` も更新（ここで analyze が通る状態に）
2. `SiteEditController` 追加
3. `SiteEditScreen` 追加
4. ルート追加（app_routes / app_router）
5. 現場詳細に 編集/削除 導線 + 確認ダイアログ
6. テスト追加（controller）
7. `flutter analyze` / `flutter test` 緑
8. iOSビルド → 実機で 編集/ステータス変更/削除 を確認
9. commit/push（DB変更なしなのでユーザーのSQL作業は**不要**）

## 工数見積もり

| タスク | 人日 | 本プロジェクト実時間目安 |
|---|---|---|
| Repository update/delete + fake | 0.25 | 🤖 |
| SiteEditController | 0.25 | 🤖 |
| SiteEditScreen | 0.5 | 🤖 |
| 詳細の編集/削除導線+ダイアログ | 0.25 | 🤖 |
| ルート | 0.1 | 🤖 |
| テスト | 0.25 | 🤖 |
| analyze/test/ビルド/実機 | 0.4 | 🤖 + 🧑実機タップ |
| **合計** | **約2人日** | 🤖 実装 **約25〜35分** ＋ 🧑 実機確認 **約5分**（**DB作業なし**） |

> Phase 1.2/1.3/2 と違い **Supabase 側の手作業（SQL適用）は不要**。コードのみで完結し、実機確認だけで完了します。

---

## 付録A：完了後の状態
- 現場 CRUD：Create / Read / **Update / Delete** が揃い「現場管理が一通り完成」。
- 全体ロードマップ進捗：Phase 3 完了で **3/10**。

## 付録B：メンバー割当（Phase 3 では非対象・将来仕様の素案）
- 新テーブル `site_members(site_id, profile_id, created_at)` + RLS（company_id 経由）
- 会社メンバー一覧（profiles）から選択して割当/解除、詳細にメンバー表示
- 権限（誰が割当できるか）は Phase 7 のロールと統合して設計するのが自然 → **Phase 7 直前 or Phase 7 で実施を推奨**
