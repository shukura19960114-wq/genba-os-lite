/// 実行環境（dev / prod）。
///
/// どちらの環境で起動しているかは Dart のエントリポイント
/// （main_dev.dart / main_prod.dart）が決め、[AppConfig] を通じてアプリ全体に伝わる。
enum AppEnv {
  dev,
  prod;

  /// `.env.dev` / `.env.prod` のファイル名。
  String get envFileName => switch (this) {
        AppEnv.dev => '.env.dev',
        AppEnv.prod => '.env.prod',
      };

  /// 画面表示用ラベル（「環境：dev」等）。
  String get label => switch (this) {
        AppEnv.dev => 'dev',
        AppEnv.prod => 'prod',
      };

  bool get isDev => this == AppEnv.dev;
  bool get isProd => this == AppEnv.prod;
}
