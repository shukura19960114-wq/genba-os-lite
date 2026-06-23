import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/foundation/presentation/connection_check_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/photos/presentation/photo_gallery_screen.dart';
import '../../features/photos/presentation/photo_viewer_screen.dart';
import '../../features/reports/presentation/report_detail_screen.dart';
import '../../features/reports/presentation/report_edit_screen.dart';
import '../../features/reports/presentation/report_form_screen.dart';
import '../../features/reports/presentation/report_list_screen.dart';
import '../../features/sites/presentation/site_create_screen.dart';
import '../../features/sites/presentation/site_detail_screen.dart';
import '../../features/sites/presentation/site_edit_screen.dart';
import '../../features/sites/presentation/site_list_screen.dart';
import 'app_routes.dart';

/// 認証状態に応じたリダイレクト先を返す純粋関数（テスト容易化のため分離）。
///
/// - 未ログインで login 以外 → /login
/// - ログイン済みで /login → /（home）
/// - それ以外はリダイレクトなし（null）
String? authRedirect({required bool loggedIn, required String location}) {
  final loggingIn = location == RoutePaths.login;
  if (!loggedIn) return loggingIn ? null : RoutePaths.login;
  if (loggingIn) return RoutePaths.home;
  return null;
}

/// アプリのルーター。認証ガード（redirect）付き。
///
/// セッション復元: supabase_flutter が起動時にセッションを永続化から復元するため、
/// 再起動時は `currentSession` が復元され、redirect により自動で home に入る。
final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final refresh = GoRouterRefreshStream(auth.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: RoutePaths.home,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      loggedIn: auth.currentSession != null,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.connectionCheck,
        name: RouteNames.connectionCheck,
        builder: (context, state) => const ConnectionCheckScreen(),
      ),
      GoRoute(
        path: RoutePaths.sites,
        name: RouteNames.sites,
        builder: (context, state) => const SiteListScreen(),
      ),
      // '/sites/new' は '/sites/:id' より先に登録する（new が id 扱いされないように）。
      GoRoute(
        path: RoutePaths.siteNew,
        name: RouteNames.siteNew,
        builder: (context, state) => const SiteCreateScreen(),
      ),
      GoRoute(
        path: RoutePaths.siteDetail,
        name: RouteNames.siteDetail,
        builder: (context, state) =>
            SiteDetailScreen(siteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.siteEdit,
        name: RouteNames.siteEdit,
        builder: (context, state) =>
            SiteEditScreen(siteId: state.pathParameters['id']!),
      ),
      // 写真（現場配下）。'/photos' を '/photos/:index' より先に登録する。
      GoRoute(
        path: RoutePaths.sitePhotos,
        name: RouteNames.sitePhotos,
        builder: (context, state) =>
            PhotoGalleryScreen(siteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.sitePhotoView,
        name: RouteNames.sitePhotoView,
        builder: (context, state) => PhotoViewerScreen(
          siteId: state.pathParameters['id']!,
          initialIndex: int.tryParse(state.pathParameters['index'] ?? '0') ?? 0,
        ),
      ),
      // 日報（現場配下）。'/reports/new' を '/reports/:reportId' より先に登録する。
      GoRoute(
        path: RoutePaths.siteReports,
        name: RouteNames.siteReports,
        builder: (context, state) =>
            ReportListScreen(siteId: state.pathParameters['siteId']!),
      ),
      GoRoute(
        path: RoutePaths.siteReportNew,
        name: RouteNames.siteReportNew,
        builder: (context, state) =>
            ReportFormScreen(siteId: state.pathParameters['siteId']!),
      ),
      GoRoute(
        path: RoutePaths.siteReportDetail,
        name: RouteNames.siteReportDetail,
        builder: (context, state) => ReportDetailScreen(
          siteId: state.pathParameters['siteId']!,
          reportId: state.pathParameters['reportId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.siteReportEdit,
        name: RouteNames.siteReportEdit,
        builder: (context, state) =>
            ReportEditScreen(reportId: state.pathParameters['reportId']!),
      ),
    ],
  );
});

/// Stream を [Listenable] に変換し、go_router の `refreshListenable` に渡すためのブリッジ。
/// 認証状態が変わるたびに `notifyListeners()` し、go_router に redirect を再評価させる。
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
