import 'bootstrap.dart';
import 'core/config/app_env.dart';

/// 既定エントリポイント。
///
/// 通常は Flavor を明示して起動する:
///   flutter run --flavor dev  -t lib/main_dev.dart
///   flutter run --flavor prod -t lib/main_prod.dart
///
/// Flavor を指定しない `flutter run`（IDEの既定など）は dev として起動する。
Future<void> main() => bootstrap(AppEnv.dev);
