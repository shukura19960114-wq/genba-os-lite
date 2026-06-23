// Phase 4 写真機能の本格化 — 要件定義＋実装仕様書（共有用）— typst
// 生成: typst compile docs/reports/Phase4_写真本格化_仕様書.typ docs/reports/Phase4_写真本格化_仕様書.pdf

#set document(title: "Phase 4 写真機能の本格化 仕様書", author: "開発チーム")
#set page(
  paper: "a4",
  margin: (x: 1.7cm, top: 1.7cm, bottom: 1.4cm),
  numbering: "1 / 1",
  footer: context [
    #set text(size: 8pt, fill: luma(130))
    #line(length: 100%, stroke: 0.4pt + luma(210))
    #v(2pt)
    現場OS Lite ・ Phase 4 写真機能の本格化 仕様書 ・ 2026-06-23
    #h(1fr)
    #counter(page).display("1 / 1", both: true)
  ],
)
#set text(font: "Hiragino Sans", size: 9.5pt, lang: "ja")
#set par(leading: 0.72em, justify: true)
#show raw.where(block: true): it => block(
  fill: luma(245), inset: 8pt, radius: 5pt, width: 100%, text(size: 8pt, it),
)

#let cmain = rgb("#1f6feb")
#let cok = rgb("#1a7f37")
#let cwarn = rgb("#bf3e3e")
#let ctodo = rgb("#57606a")
#let th(s) = text(weight: "bold", size: 9pt, s)
#let headfill(c) = (_, row) => if row == 0 { c.lighten(86%) } else { white }

#show heading.where(level: 1): it => block(below: 0.6em, above: 1.0em)[
  #set text(size: 13pt, weight: "bold", fill: cmain)
  #box(fill: cmain, width: 4pt, height: 0.95em, baseline: 0.12em, radius: 1pt)
  #h(6pt) #it.body
]
#show heading.where(level: 2): it => block(below: 0.4em, above: 0.65em)[
  #set text(size: 10.5pt, weight: "bold", fill: ctodo.darken(20%)); #it.body
]

// ===== 表紙 =====
#align(center)[
  #v(2pt)
  #text(size: 20pt, weight: "bold", fill: cmain)[Phase 4 写真機能の本格化 仕様書]
  #v(3pt)
  #text(size: 11pt)[現場OS Lite ／ 要件定義 ＋ 実装仕様書（最小工数）]
  #v(4pt)
  #text(size: 10pt, fill: ctodo)[作成日：2026年6月23日　／　目的：建設会社が現場写真を実用レベルで管理できる]
]
#v(3pt)
#line(length: 100%, stroke: 1pt + cmain.lighten(35%))
#v(5pt)

#block(fill: cmain.lighten(93%), inset: 10pt, radius: 6pt, width: 100%, stroke: 0.5pt + cmain.lighten(55%))[
  #text(weight: "bold", fill: cmain.darken(5%))[概要] \
  #v(2pt)
  既存の写真機能（現場別アップロード・グリッド表示）を、*複数選択・全画面拡大・撮影日時・現場別ギャラリー*まで
  引き上げる。*DB変更なし・新規依存なし*で実装でき、Supabase の手作業も不要。
]
#v(6pt)

= スコープ
#table(columns: (1fr, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: (col, row) => if row == 0 { (cok, cwarn).at(col).lighten(86%) } else { white },
  table.header(th("実装する"), th("実装しない")),
  [複数写真（ライブラリ複数選択）], [AI解析],
  [写真拡大表示（スワイプ・ピンチズーム）], [GPS / 位置情報],
  [撮影日時表示（= created_at）], [動画],
  [写真一覧改善（枚数・新しい順）], [PDF],
  [現場別ギャラリー], [写真削除・オフライン同期（別フェーズ）],
)
#v(2pt)
#text(size: 8.5pt, fill: ctodo)[
  ※「撮影日時」は `created_at`（=アップロード日時）で表示。真のEXIF撮影日時は新カラム＋解析が必要なため本フェーズ非対象。
  ※ ROADMAP元Phase 4のオフライン同期/geoは再スコープで除外。
]

= 1. ユーザーストーリー
+ ライブラリから*複数枚をまとめて*現場に追加したい。
+ 写真を*タップで拡大*し、*左右スワイプ*で次々確認したい。
+ 各写真が*いつのものか（日時）*を知りたい。
+ 現場ごとの*ギャラリー*で整理して見返したい（枚数も把握）。
+ 引き続き*自社の写真のみ*（RLS維持）。

= 2. DB変更有無
*変更なし（マイグレーション不要・Supabase手作業なし）*。複数写真は既存テーブルに複数行で対応済み、拡大/日時/整理は
既存カラム（`path` / `created_at`）と署名付きURLで実現。新規カラム・テーブル・依存なし。

= 3. 画面一覧
#table(columns: (auto, auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 6pt, y: 5pt),
  fill: headfill(cmain),
  table.header(th("画面"), th("区分"), th("主な要素")),
  [現場詳細の写真セクション], [変更],
  [枚数表示／タイルtapで拡大／追加（カメラ=1枚・ライブラリ=複数）／「すべて見る」→ギャラリー],
  [写真ギャラリー（現場別）], [追加],
  [現場の全写真をグリッド表示（新しい順・枚数・空/エラー・pull-to-refresh）],
  [写真拡大ビューア], [追加],
  [全画面。PageViewで左右スワイプ＋InteractiveViewerでピンチズーム。日時と「n / N」表示],
)

= 4. Repository構成
既存 `listPhotos / uploadPhoto(1枚) / createSignedUrl` を流用。*複数アップロードは Controller で uploadPhoto をループ*（Repositoryは増やさない）。
`createSignedUrls`(一括署名) は任意・性能用でMVP不要。
`ImagePickerService` に `pickMultiple()`（image_picker の `pickMultiImage`）を追加 ＝ *新規依存なし*。

= 5. Riverpod構成
既存 `photosProvider.family(siteId)` / `photoUrlProvider.family(path)` を流用。
`PhotoUploadController` に `addPhotos()` 追加（複数選択→ループupload→invalidate、結果に追加/失敗枚数）。既存 `addPhoto`（カメラ1枚）は維持。
ビューアの現在indexは画面ローカル（`PageController`）。

= 6. 完了条件
#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  fill: headfill(cok),
  table.header(th("#"), th("条件")),
  [1], [複数写真を一度に追加できる],
  [2], [写真をタップで全画面表示・スワイプ切替・ピンチズーム],
  [3], [各写真に日時（created_at）が表示される],
  [4], [現場別ギャラリーで新しい順＋枚数表示],
  [5], [RLS維持（自社のみ表示・アップロード）],
  [6], [flutter analyze / flutter test 緑],
  [7], [dev実機確認成功],
)

= 7. テスト条件
- `ImagePickerService(Fake)`：`pickMultiple()` が複数/空を返す
- `PhotoUploadController.addPhotos`：複数成功（upload回数=件数）／空（未アップロード）／全失敗（state エラー）
- `PhotoRepository(Fake)`：`uploadPhoto` 呼び出し回数・一覧反映
- 既存43件が緑のまま。拡大/ギャラリーの画像描画は実機確認。

#pagebreak()

= 実装仕様（最小工数）

== 追加・変更ファイル
#table(columns: (auto, 1fr), stroke: 0.5pt + luma(215), inset: (x: 6pt, y: 4.5pt),
  fill: headfill(luma(180)),
  table.header(th("区分"), th("ファイル")),
  [変更], [`image_picker_service.dart`（pickMultiple）/ `photo_upload_controller.dart`（addPhotos）/ `site_detail_screen.dart`（写真セクション）/ `app_routes.dart`・`app_router.dart`（ルート）/ `test/photos/fakes.dart`],
  [追加], [`photo_gallery_screen.dart`（P-Gallery）/ `photo_viewer_screen.dart`（P-Viewer）/ `test/photos/photo_upload_controller_multi_test.dart`],
  [なし], [DBマイグレーション / 新規依存 / Supabase手作業],
)

== ImagePickerService（追加メソッド）
```dart
Future<List<Uint8List>> pickMultiple() async {
  final files = await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 80);
  final out = <Uint8List>[];
  for (final f in files) { out.add(await f.readAsBytes()); }
  return out; // キャンセル時は空
}
```

== PhotoUploadController（追加メソッド）
```dart
typedef PhotosAddResult = ({int uploaded, int failed, bool cancelled});

Future<PhotosAddResult> addPhotos({required String siteId, required String companyId}) async {
  state = const AsyncValue.loading();
  final list = await ref.read(imagePickerServiceProvider).pickMultiple();
  if (list.isEmpty) { state = const AsyncValue.data(null); return (uploaded:0, failed:0, cancelled:true); }
  var ok = 0, ng = 0; Object? err; StackTrace? st;
  for (final bytes in list) {
    try { await ref.read(photoRepositoryProvider)
            .uploadPhoto(siteId: siteId, companyId: companyId, bytes: bytes); ok++; }
    catch (e, s) { ng++; err = e; st = s; }
  }
  ref.invalidate(photosProvider(siteId));
  state = (ng > 0 && ok == 0) ? AsyncValue.error(err!, st!) : const AsyncValue.data(null);
  return (uploaded: ok, failed: ng, cancelled: false);
}
```

== 画面
- *現場詳細セクション*：ヘッダ `写真 (N)`＋「すべて見る」＋「追加」。追加ボトムシート＝カメラ(1枚`addPhoto`)/ライブラリ(複数`addPhotos`)。タイルtap→ビューア。
- *P-Gallery* `PhotoGalleryScreen(siteId)`：`photosProvider(siteId)` を `.when`。RefreshIndicator+GridView（3列・新しい順）。空/エラー対応。タイルtap→ビューア。
- *P-Viewer* `PhotoViewerScreen(siteId, initialIndex)`：黒背景。`PageView.builder`（initialPage=initialIndex, onPageChangedでindex更新）＋各ページ `InteractiveViewer`＋`photoUrlProvider(path)`→`Image.network`。AppBar=「n / N」、下部に `yyyy/MM/dd HH:mm`（created_at.toLocal、nullは —）。

== ルート
```dart
static const sitePhotos    = '/sites/:id/photos';
static const sitePhotoView = '/sites/:id/photos/:index';
// '/photos' を '/photos/:index' より先に登録。遷移は context.push('/sites/$siteId/photos[/$index]')
```

== 実装手順
+ pickMultiple 追加 → Fake更新（analyze緑） → addPhotos 追加
+ P-Gallery / P-Viewer 追加 → ルート登録
+ 現場詳細セクション改修（枚数・tap拡大・複数追加・すべて見る）
+ テスト（addPhotos） → analyze / test 緑
+ iOSビルド → 実機で 複数追加 / 拡大スワイプ / 日時 / ギャラリー 確認 → commit/push

== 工数見積もり
#table(columns: (1fr, auto), stroke: 0.5pt + luma(215), inset: (x: 7pt, y: 5pt),
  align: (left, center + horizon), fill: headfill(luma(180)),
  table.header(th("区分"), th("目安")),
  [🤖 実装（コード一式＋テスト＋analyze/test緑＋push）], [約35〜50分],
  [🧑 実機確認（複数追加・拡大・ギャラリー）], [約5分],
  [DB / Supabase 手作業], [なし],
  [合計（壁時計）], [*約1時間以内*],
)

#v(8pt)
#line(length: 100%, stroke: 0.4pt + luma(210))
#v(2pt)
#text(size: 8pt, fill: ctodo)[関連: docs/Phase4_写真本格化_要件定義.md ／ docs/Phase4_写真本格化_実装仕様書.md ／ 踏襲元 = Phase 1.3 写真管理。]
