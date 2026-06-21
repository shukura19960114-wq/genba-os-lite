/// ルートのパス定義。
///
/// Phase 1.1（認証）で /（home）・/login を追加。接続確認は /connection に移設。
abstract final class RoutePaths {
  static const home = '/';
  static const login = '/login';
  static const connectionCheck = '/connection';

  // static const sites = '/sites'; // Phase 1.2
}

/// ルート名（go_router の name 指定用）。
abstract final class RouteNames {
  static const home = 'home';
  static const login = 'login';
  static const connectionCheck = 'connectionCheck';

  // static const sites = 'sites';
}
