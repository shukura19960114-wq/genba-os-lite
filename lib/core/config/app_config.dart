import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_env.dart';

part 'app_config.freezed.dart';

/// アプリ実行時の構成（現在の環境・Supabase接続情報・表示設定）。
///
/// `bootstrap()` で `.env.<env>` から組み立てられ、`appConfigProvider` を通じて
/// アプリ全体から参照できる「現在の環境」の単一の真実（single source of truth）。
///
/// 注意（freezed 3.x）: モデルは `abstract class ... with _$...` 形式で宣言する。
/// 生成ファイル `app_config.freezed.dart` は build_runner で作成される（Git管理外）。
///   dart run build_runner build --delete-conflicting-outputs
@freezed
abstract class AppConfig with _$AppConfig {
  const AppConfig._();

  const factory AppConfig({
    /// 現在の実行環境（dev / prod）。
    required AppEnv env,

    /// Supabase Project URL（.env から）。
    required String supabaseUrl,

    /// Supabase anon public key（.env から）。service_role は絶対に入れない。
    required String supabaseAnonKey,

    /// 表示用アプリ名（環境ごとに変える）。
    required String appName,

    /// dev のときだけ画面に環境バナーを出すフラグ。
    required bool showFlavorBanner,
  }) = _AppConfig;
}
