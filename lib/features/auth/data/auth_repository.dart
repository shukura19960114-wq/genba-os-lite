import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';

/// 認証の抽象インターフェース。
///
/// プレゼンテーション/アプリケーション層はこの抽象にのみ依存し、Supabase に直接触れない。
/// 将来 Google ログインを足す場合は、ここに `signInWithGoogle()` を追加し
/// [SupabaseAuthRepository] で `signInWithOAuth(OAuthProvider.google)` を実装する
/// （画面/コントローラ側の修正を最小化できる設計）。
abstract interface class AuthRepository {
  /// Email + Password でサインインする。失敗時は [AuthException] を投げる。
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// Email + Password で新規登録する。失敗時は [AuthException] を投げる。
  /// Supabase の Email confirmation が OFF なら即セッションが張られる。
  Future<void> signUp({
    required String email,
    required String password,
  });

  /// サインアウトする。
  Future<void> signOut();

  /// 現在のセッション（未ログインなら null）。アプリ起動時は永続化から復元される。
  Session? get currentSession;

  /// 現在のユーザー（未ログインなら null）。
  User? get currentUser;

  /// 認証状態の変化ストリーム（ログイン/ログアウト/トークン更新など）。
  Stream<AuthState> authStateChanges();
}

/// Supabase Auth による [AuthRepository] 実装。
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;
}

/// [AuthRepository] を提供する Provider（テストでは override で差し替え可能）。
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider)),
);

/// 認証エラーを画面表示用の日本語メッセージに変換する。
String authErrorMessage(Object error) {
  if (error is AuthException) {
    final m = error.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'メールアドレスまたはパスワードが違います。';
    }
    if (m.contains('email not confirmed')) {
      return 'メールアドレスが未確認です。管理者に確認してください。';
    }
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'このメールアドレスは既に登録されています。ログインしてください。';
    }
    if (m.contains('password') && m.contains('6')) {
      return 'パスワードは6文字以上で入力してください。';
    }
    return error.message;
  }
  return '予期しないエラーが発生しました：$error';
}
