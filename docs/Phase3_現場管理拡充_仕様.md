# Phase 3 現場管理の拡充 — 要件定義 & 実装仕様書（MVP・最小工数）

**作成日:** 2026-06-22（改訂: 削除機能を除外）　／　**対象:** Phase 3「現場管理の拡充」
**目的:** 「現場CRUD完成」ではなく **「顧客ヒアリング可能な現場運用MVP完成」**
**方針:** 最小工数。DB変更なし。**削除機能は実装しない**（事故リスク回避）。

---

## スコープ確定（このフェーズの線引き）

### ✅ 実装する
1. **現場編集** — 現場名の変更・住所の変更
2. **現場ステータス変更** — 進行中（active）／完了（completed）／中止（suspended）
3. **既存RLS維持** — 自社の現場のみ編集可（company_id 制御）
4. **テスト追加** — 編集・ステータス変更まわり

### ❌ 実装しない（明確に対象外）
- 現場**削除**（Delete API / Delete UI / Delete テスト）
- メンバー割当 / `site_members` テーブル
- 招待機能 / 権限管理 / ロール（owner/admin/member）
- 通知 / PDF

### 除外理由（記録）
- **削除**：顧客価値より**事故リスク**が大きい。`sites` 削除は FK `on delete cascade` により
  **現場に紐づく日報・写真まで連鎖削除**されるため、Phase 3 では実装しない（将来、論理削除や権限制御とセットで再検討）。
- **メンバー割当**：`site_members` テーブルと権限制御設計が必要 → **Phase 7（権限管理）へ延期**。

---

## 現状サマリ（実装確認の結果）

| 既存 | 状態 |
|---|---|
| `sites` テーブル / RLS | ✅ あり。update の RLS ポリシー（`sites_update_company`）も既存。`status` カラムあり（active/completed/suspended） |
| `Site` モデル | ✅ id / companyId / name / address / status / createdAt。`siteStatusLabel()`（進行中/完了/中止）実装済み |
| `SiteRepository` | `fetchSites` / `fetchSite` / `createSite` のみ（**updateSite 未実装**） |
| 画面 | 一覧 / 作成 / 詳細（詳細にステータス表示・日報導線・写真あり） |

> 結論：Phase 3 の実装は **Update（編集＝名称/住所/ステータス）のみ**。**DB変更不要**（RLS・`status` カラムが既存）でコードのみ。**Supabase 手作業（SQL）も不要**。

---

# Part 1. 要件定義

## 1. ユーザーストーリー
1. 監督として、登録済み現場の**名称・住所を後から修正**したい。
2. 現場の進捗に応じて**ステータスを「進行中／完了／中止」に変更**したい。
3. 自社の現場だけを編集でき、**他社の現場は編集できない**（RLS）。

## 2. DB変更有無
**変更なし（マイグレーション不要）** ✅
- `sites.status` カラム・update の RLS は 0002_sites.sql に既存。
- 追加テーブル・追加カラム・トリガ等は**一切なし**。Supabase での SQL 実行も**不要**。

## 3. 画面一覧
| # | 画面 | 区分 | 主な要素 |
|---|---|---|---|
| S-Edit | **現場編集** | 追加 | 名称（必須）・住所（任意）・**ステータス（ドロップダウン）**・更新ボタン |
| S-Detail | 現場詳細 | 変更 | AppBar に **編集（鉛筆）アイコン** を追加（**削除は無し**） |
| S-List | 現場一覧 | 変更なし | ステータス Chip は既存（編集後に反映） |
| S-Create | 現場作成 | 変更なし | 既存のまま（作成時 status は active 既定） |

### 画面遷移
```
現場詳細(S-Detail) ─[鉛筆]→ S-Edit ─更新→ 詳細に戻る（詳細・一覧は再フェッチで反映）
```

## 4. Repository構成
既存 `SiteRepository`（抽象interface + Supabase実装）に **1メソッド追加**：

```dart
/// 現場を更新して更新後の行を返す（company_id は変更しない＝送らない）。
Future<Site> updateSite({
  required String id,
  required String name,
  String? address,
  required String status,
});
```
- **delete 系メソッドは追加しない。**
- 既存 `FakeSiteRepository`（テスト）にも `updateSite` の実装追加が**必須**（IF変更のため）。

## 5. Riverpod構成
- 既存 `sitesListProvider` / `siteDetailProvider.family(id)` を流用（追加なし）。
- **追加: `SiteEditController`**（`AsyncNotifierProvider.autoDispose`、Phase 2 Form Controller と同方針）
  - `Future<bool> update({required id, required name, address, required status})`
    - 成功時：`sitesListProvider` と `siteDetailProvider(id)` を invalidate → true
    - 失敗時：state をエラーにし false（画面は SnackBar 表示）
  - **delete メソッドは持たせない。**

## 6. 完了条件
| # | 完了条件 | 確認方法 |
|---|---|---|
| 1 | 現場編集成功 | 名称/住所を変更→更新→詳細・一覧に反映 |
| 2 | ステータス変更成功 | 進行中→完了 に変更→一覧Chip・詳細が変わる |
| 3 | RLS確認 | 自社の現場のみ更新可（company_id 制御） |
| 4 | analyze成功 | `flutter analyze` → No issues |
| 5 | test成功 | `flutter test` → 全件パス |
| 6 | dev実機確認成功 | iOSシミュレータで 1〜2 を目視確認 |

## 7. テスト条件
- **SiteEditController（必須）**: fake repo を override し
  - update 成功 → true・state エラーなし
  - update 失敗 → false・state エラー
- **FakeSiteRepository**: `updateSite` を実装（lastUpdated / shouldThrow を記録）
- **delete のテストは作らない**（機能が存在しないため）。
- 既存テスト（41件）が**引き続き緑**であること。

---

# Part 2. 実装仕様書（最小工数）

## 追加・変更ファイル一覧

```
変更:
  lib/features/sites/data/site_repository.dart        # updateSite 追加（IF + 実装）※delete無し
  lib/features/sites/presentation/site_detail_screen.dart  # AppBar に編集アイコン追加（削除は無し）
  lib/core/router/app_routes.dart                     # siteEdit パス/名追加
  lib/core/router/app_router.dart                     # /sites/:id/edit 登録
  test/sites/fakes.dart                               # FakeSiteRepository に updateSite

追加:
  lib/features/sites/application/site_edit_controller.dart  # SiteEditController（update のみ）
  lib/features/sites/presentation/site_edit_screen.dart    # S-Edit（名称/住所/ステータス）
  test/sites/site_edit_controller_test.dart

DBマイグレーション: なし
新規依存: なし
Supabase 手作業: なし
```

## 1) Repository（site_repository.dart）

抽象IFに追記し、`SupabaseSiteRepository` に実装：

```dart
// interface に追加
Future<Site> updateSite({
  required String id,
  required String name,
  String? address,
  required String status,
});

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
}
```

## 3) 画面（site_edit_screen.dart・新規）

- `SiteEditScreen(String siteId)` = ConsumerWidget。`ref.watch(siteDetailProvider(siteId)).when(...)`：
  - loading: Scaffold(AppBar「現場の編集」)+ 中央スピナー
  - error: Scaffold(AppBar「現場の編集」)+「現場の取得に失敗しました」+ 再読み込み（`ref.invalidate(siteDetailProvider(siteId))`）
  - data(site): `_SiteEditForm(site: site)` を返す
- `_SiteEditForm` = ConsumerStatefulWidget。initState で `site` から controllers / `_status` を初期化：
  - 名称 TextFormField（必須・validator「現場名を入力してください」。key `site_edit_name_field`）
  - 住所 TextFormField（任意。key `site_edit_address_field`）
  - **ステータス** `DropdownButtonFormField<String>`（初期=site.status。key `site_edit_status_field`）
    - 選択肢：`active`/`completed`/`suspended`（表示は `siteStatusLabel(code)`）
  - 更新ボタン FilledButton（key `site_edit_submit_button`）：`isLoading` でスピナー化＆無効化
    - onPressed：`validate()` → `controller.update(id: site.id, name, address, status)` → true なら SnackBar「現場を更新しました」+ `context.pop()`
  - エラー監視：`ref.listen(siteEditControllerProvider, ...)` で AsyncError 時 SnackBar「更新に失敗しました。通信状況を確認して再度お試しください。」

## 4) 現場詳細への導線（site_detail_screen.dart 変更）

- `AppBar(actions: [...])` に **編集のみ** 追加：
  - `IconButton(key: Key('site_edit_button'), icon: Icon(Icons.edit))` → `context.push('/sites/$siteId/edit')`
- **削除アイコン・削除メニュー・確認ダイアログは追加しない。**

## 5) ルート（app_routes.dart / app_router.dart）

```dart
// app_routes.dart
static const siteEdit = '/sites/:id/edit';   // RoutePaths
static const siteEdit = 'siteEdit';          // RouteNames

// app_router.dart（siteDetail の後に登録）
GoRoute(
  path: RoutePaths.siteEdit,
  name: RouteNames.siteEdit,
  builder: (context, state) =>
      SiteEditScreen(siteId: state.pathParameters['id']!),
),
```
> 既存の `/sites/:siteId/reports...` とはセグメント構成が異なるため衝突なし。

## 6) テスト（test/sites/）

- `fakes.dart` の `FakeSiteRepository` に追加（**updateSite のみ**）：
  ```dart
  Site? lastUpdated;
  bool failOnUpdate = false;
  @override
  Future<Site> updateSite({required String id, required String name,
      String? address, required String status}) async {
    if (failOnUpdate) throw Exception('update failed');
    return lastUpdated =
        Site(id: id, companyId: 'c', name: name, address: address, status: status);
  }
  ```
- `site_edit_controller_test.dart`：update 成功 / update 失敗（ProviderContainer + override、autoDispose は listen で保持）。
- **delete 系テストは作らない。**

## 7) 実装手順（推奨順）
1. Repository に `updateSite` 追加（IF+実装）→ `FakeSiteRepository` も更新（analyze が通る状態に）
2. `SiteEditController` 追加
3. `SiteEditScreen` 追加
4. ルート追加（app_routes / app_router）
5. 現場詳細に **編集アイコン** 追加
6. テスト追加（controller：update 成功/失敗）
7. `flutter analyze` / `flutter test` 緑
8. iOSビルド → 実機で 編集・ステータス変更 を確認
9. commit/push（**DB作業なし**＝ユーザーのSQL作業不要）

## 工数見積もり
| タスク | 人日 | 実時間目安 |
|---|---|---|
| Repository updateSite + fake | 0.2 | 🤖 |
| SiteEditController | 0.2 | 🤖 |
| SiteEditScreen | 0.5 | 🤖 |
| 詳細に編集アイコン | 0.1 | 🤖 |
| ルート | 0.1 | 🤖 |
| テスト（update のみ） | 0.2 | 🤖 |
| analyze/test/ビルド/実機 | 0.4 | 🤖 + 🧑実機タップ |
| **合計** | **約1.7人日** | 🤖 実装 **約20〜30分** ＋ 🧑 実機確認 **約5分**（**DB作業なし**） |

---

## 付録A：完了後の状態
- 現場操作：Create / Read / **Update（編集・ステータス）** が揃い、**顧客ヒアリング可能な現場運用MVP**が完成。
  （Delete は事故リスク回避のため意図的に未実装。論理削除/権限とセットで将来検討）
- 全体ロードマップ進捗：Phase 3 完了で **3/10**。

## 付録B：将来の延期項目
- **削除**：論理削除（`deleted_at`）や権限制御とセットで再設計（Cascade による日報/写真の巻き添えを防ぐ設計を含む）。
- **メンバー割当**：`site_members` テーブル + RLS + メンバー一覧UI。権限（誰が割当可能か）は **Phase 7（ロール/招待/管理画面）** と統合して実施を推奨。
