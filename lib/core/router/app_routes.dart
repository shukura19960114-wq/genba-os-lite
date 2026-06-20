/// ルートのパス定義。
///
/// Phase 1.0（基盤）では接続確認画面のみ。後続フェーズで /login・/sites 等を追加する。
abstract final class RoutePaths {
  static const connectionCheck = '/';

  // --- 後続フェーズで有効化（プレースホルダ）---
  // static const login = '/login';
  // static const sites = '/sites';
}

/// ルート名（go_router の name 指定用）。
abstract final class RouteNames {
  static const connectionCheck = 'connectionCheck';

  // static const login = 'login';
  // static const sites = 'sites';
}
