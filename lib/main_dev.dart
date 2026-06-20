import 'bootstrap.dart';
import 'core/config/app_env.dart';

/// dev 環境のエントリポイント。
/// 起動: `flutter run --flavor dev -t lib/main_dev.dart`
Future<void> main() => bootstrap(AppEnv.dev);
