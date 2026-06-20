import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';
import 'core/config/app_env.dart';

/// アプリ共通の起動処理。
///
/// 流れ: Flutterバインディング初期化 → `.env.<env>` 読込 → [AppConfig] 構築 →
/// Supabase 初期化 → `ProviderScope`（appConfigProvider を上書き）で起動。
///
/// main_dev.dart / main_prod.dart からそれぞれ [AppEnv.dev] / [AppEnv.prod] で呼ぶ。
Future<void> bootstrap(AppEnv env) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 環境ごとの .env を読み込む（鍵はソースに直書きしない）。
  await dotenv.load(fileName: env.envFileName);

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey == null ||
      supabaseAnonKey.isEmpty) {
    throw StateError(
      '${env.envFileName} に SUPABASE_URL と SUPABASE_ANON_KEY を設定してください。',
    );
  }

  final config = AppConfig(
    env: env,
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: supabaseAnonKey,
    appName: env.isDev ? '現場OS Lite Dev' : '現場OS Lite',
    showFlavorBanner: env.isDev,
  );

  // プラットフォームの Flavor（--flavor）と Dart のエントリポイント（-t）の
  // 食い違いを debug ビルドで検出する。appFlavor は web や Play Store 再署名後に
  // null/空になり得るため、null 許容にして release/web をクラッシュさせない。
  assert(
    appFlavor == null || appFlavor == env.name,
    'Flavor 不一致: appFlavor=$appFlavor, env=${env.name}。'
    '`--flavor ${env.name} -t lib/main_${env.name}.dart` の組合せを確認してください。',
  );

  // anon public key は publishableKey 引数に渡す
  // （supabase_flutter 2.15 で anonKey は非推奨。値は anon public key のまま）。
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
  );

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const App(),
    ),
  );
}
