import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import '../data/profile.dart';
import '../data/profile_repository.dart';

/// 認証状態の変化を流す Stream（ログイン/ログアウト/トークン更新）。
/// go_router の `refreshListenable` のトリガー元として使う。
final authStateChangesProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// 現在ログイン中かどうか（同期的に判定。redirect から参照）。
final isLoggedInProvider = Provider<bool>(
  (ref) => ref.watch(authRepositoryProvider).currentSession != null,
);

/// Home 画面用の表示データ（プロフィール + 会社名）。
typedef HomeProfile = ({Profile? profile, String? companyName});

/// ログイン中ユーザーのプロフィールと会社名をまとめて取得する。
final homeProfileProvider = FutureProvider<HomeProfile>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  final profile = await repo.fetchCurrentProfile();
  String? companyName;
  final companyId = profile?.companyId;
  if (companyId != null) {
    companyName = await repo.fetchCompanyName(companyId);
  }
  return (profile: profile, companyName: companyName);
});
