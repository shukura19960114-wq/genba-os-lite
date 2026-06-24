import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/core/router/app_router.dart';
import 'package:genba_os_lite/core/router/app_routes.dart';

void main() {
  group('authRedirect（認証ガードの分岐）', () {
    test('未ログインで home → /login へ', () {
      expect(
        authRedirect(loggedIn: false, location: RoutePaths.home),
        RoutePaths.login,
      );
    });

    test('未ログインで login → リダイレクトなし', () {
      expect(
        authRedirect(loggedIn: false, location: RoutePaths.login),
        isNull,
      );
    });

    test('ログイン済みで login → /（home）へ', () {
      expect(
        authRedirect(loggedIn: true, location: RoutePaths.login),
        RoutePaths.home,
      );
    });

    test('ログイン済みで home → リダイレクトなし', () {
      expect(
        authRedirect(loggedIn: true, location: RoutePaths.home),
        isNull,
      );
    });

    // Phase 7: サインアップページの扱い
    test('未ログインで signup → リダイレクトなし（登録できる）', () {
      expect(
        authRedirect(loggedIn: false, location: RoutePaths.signup),
        isNull,
      );
    });

    test('ログイン済みで signup → /（home）へ', () {
      expect(
        authRedirect(loggedIn: true, location: RoutePaths.signup),
        RoutePaths.home,
      );
    });
  });
}
