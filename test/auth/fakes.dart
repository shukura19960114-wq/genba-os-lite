import 'dart:async';

import 'package:genba_os_lite/core/config/app_config.dart';
import 'package:genba_os_lite/core/config/app_env.dart';
import 'package:genba_os_lite/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// テスト用の [AuthRepository] フェイク。Supabase に触れずに挙動を制御する。
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failWith});

  /// signIn 時に投げる例外（null なら成功）。
  final Object? failWith;
  Session? _session;

  bool signInCalled = false;
  bool signOutCalled = false;

  final _controller = StreamController<AuthState>.broadcast();

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    if (failWith != null) throw failWith!;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    _session = null;
  }

  @override
  Session? get currentSession => _session;

  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> authStateChanges() => _controller.stream;
}

/// テスト用の [AppConfig]（画面が appConfigProvider を watch するため）。
final testAppConfig = AppConfig(
  env: AppEnv.dev,
  supabaseUrl: 'https://example.supabase.co',
  supabaseAnonKey: 'test-anon-key',
  appName: 'テストアプリ',
  showFlavorBanner: false,
);
