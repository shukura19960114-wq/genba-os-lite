import 'bootstrap.dart';
import 'core/config/app_env.dart';

/// prod 環境のエントリポイント。
/// 起動: `flutter run --flavor prod -t lib/main_prod.dart`
Future<void> main() => bootstrap(AppEnv.prod);
