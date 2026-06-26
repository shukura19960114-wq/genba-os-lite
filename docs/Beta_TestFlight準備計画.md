# ベータ配信（TestFlight）準備計画

**作成日:** 2026-06-26　／　**前提:** Apple Developer Program 保有済み。iOS優先（Androいずれ）。
**目的:** 社内/関係者に **TestFlight** でベータ配信できる状態にする。
**凡例:** 🤖=Claudeがコードで実施 ／ 🧑=あなたがApple/Supabase画面で実施（代行不可）

---

## 0. 前提と決定事項
| 項目 | 状態 |
|---|---|
| Apple Developer Program | 🧑 ✅ 保有済み |
| 本物の Bundle ID（逆ドメイン） | 🧑 **要決定**（現状 `com.example.genbaOsLite` は仮）→ 値をもらい次第 🤖 反映 |
| アプリアイコン | 🤖 ✅ 仮アイコン作成済み（`assets/icon/app_icon.png`・現場OS Lite）。本アイコンは後で差し替え |
| アプリ表示名 | 現場OS Lite（prod）。変更可 |

## 1. ⚠️ 最優先：DBを実機で確認（壊れたベータを配らない）
- 🧑 **dev** に `0005`→`0006` を適用 → 招待/ロール/担当割当・連絡/未読 が動くことを確認（Phase 7・5 のクローズ）。
- 🧑 **prod** Supabase に `0001`〜`0006` を順に適用 ＋ `.env.prod` に prod の URL/anon鍵。
  - ベータは **prod 環境**に接続するのが基本（テスターの実データはdevと分離）。

## 2. Bundle ID を本物に変更（🤖／値待ち）
- dev / prod の xcconfig を更新：
  - dev: `<あなたのID>.dev` ／ prod: `<あなたのID>`
  - 例（おすすめ案）: dev `com.genbaos.lite.dev` ／ prod `com.genbaos.lite`
- 変更箇所：`ios/Flutter/{Debug,Release,Profile}-{dev,prod}.xcconfig` の `PRODUCT_BUNDLE_IDENTIFIER`。
- Android の applicationId も合わせる（任意・iOS優先なら後で）。

## 3. アプリアイコン（🤖 ✅ 済）
- `flutter_launcher_icons` 導入済み。`dart run flutter_launcher_icons` で iOS/Android 全サイズ生成済み（iOSはアルファ除去）。
- 本アイコン入手後：`assets/icon/app_icon.png` を差し替え → 上記コマンド再実行 → 再ビルド。

## 4. バージョン / ビルド番号（🤖）
- `pubspec.yaml` の `version: 1.0.0+1`。**TestFlightは同じビルド番号を再利用できない**。
- 運用：アップロードのたびに **ビルド番号（+の後）を+1**。例 `1.0.0+1` → `1.0.0+2`。
- ビルド時に上書きも可：`flutter build ipa --build-number=2`。

## 5. App Store Connect 準備（🧑・クリック手順は後述で詳細化）
1. [Apple Developer] Certificates, Identifiers & Profiles → **Identifiers** で App ID（= prod Bundle ID）を登録。
2. [App Store Connect] My Apps → **＋ 新規App** → プラットフォームiOS・名前・**Bundle ID選択**・SKU入力。
3. アプリのプライバシー：**プライバシーポリシーURL**（TestFlight外部テストで必要）。

## 6. 署名（🧑・Xcode）
- `open ios/Runner.xcworkspace`（SPMなので .xcodeproj でも可）→ Runner ターゲット → **Signing & Capabilities**。
- **Automatically manage signing** を ON、**Team** に自分のApple Developerチームを選択（prod/dev 両方の Configuration）。
- これで配布用プロビジョニングは自動生成。

## 7. リリースビルド & アップロード（🤖ビルド準備 / 🧑アップロード）
- ビルド（IPA）:
  ```bash
  flutter build ipa --flavor prod -t lib/main_prod.dart --build-number=<n>
  ```
  → `build/ios/ipa/*.ipa` が出力。
- アップロード方法（どちらか）:
  - **Transporter.app**（Mac App Store・無料）に .ipa をドラッグ → Deliver。
  - または Xcode の **Organizer**（Archive → Distribute App → TestFlight）。
- アップロード後、App Store Connect の TestFlight に数分〜で表示。

## 8. TestFlight 配信（🧑）
- **暗号化申告**：Info.plist に `ITSAppUsesNonExemptEncryption=false`（標準HTTPSのみなら通常 false）を入れておくと毎回の質問を省略 → 🤖 で設定可。
- **内部テスター**（App Store Connectのユーザー）：審査なしで即配信。最大100人。
- **外部テスター**（メール招待・公開リンク）：初回のみ簡易**Beta App Review**が必要。
- テスターは iPhone に **TestFlight アプリ**を入れて招待リンクから参加。

## 9. 仕上げ（任意・品質）
- スプラッシュ（起動画面）：`flutter_native_splash`（任意）。
- クラッシュ監視（Phase 8 と重複）：Sentry 等は後続でも可。
- 文言/権限説明（カメラ・写真）：Info.plist の利用目的文言を日本語で。

---

## いま私（🤖）が待っているもの
- **本物の Bundle ID**（例 `com.あなたの会社.genbaoslite`）。もらえれば xcconfig を更新し、`ITSAppUsesNonExemptEncryption` 設定とビルド番号運用まで一気に整えます。
- 並行して 🧑 は **dev に 0005/0006 適用 → 動作確認** を進めてください（壊れたベータを配らないため）。

> この計画書は随時更新。クリックレベルの詳細手順（App Store Connect / Xcode 署名）は、Bundle ID 確定後に画面に沿って一手順ずつ案内します。
