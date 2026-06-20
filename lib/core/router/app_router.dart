import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/foundation/presentation/connection_check_screen.dart';
import 'app_routes.dart';

/// アプリのルーター。
///
/// Phase 1.0（基盤）では接続確認画面1枚のみ。
/// 後続のログインフェーズで、ここに認証状態を watch する `redirect` と
/// `refreshListenable`（onAuthStateChange ブリッジ）を追加して認証ガードにする。
final goRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: RoutePaths.connectionCheck,
    routes: [
      GoRoute(
        path: RoutePaths.connectionCheck,
        name: RouteNames.connectionCheck,
        builder: (context, state) => const ConnectionCheckScreen(),
      ),
    ],
  ),
);
