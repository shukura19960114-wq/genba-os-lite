import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile.dart';
import '../data/profile_repository.dart';

/// ログイン中ユーザーのプロフィール（未ログイン/未作成なら null）。
///
/// 各画面のロールゲート（`.value?.role`）と会社未所属判定（`companyId == null`）に使う。
/// 参加/作成・ロール変更の成功後は `ref.invalidate(currentProfileProvider)` で再取得する。
final currentProfileProvider = FutureProvider<Profile?>(
  (ref) => ref.watch(profileRepositoryProvider).fetchCurrentProfile(),
);

/// ログイン中ユーザーのロール（取得前/未所属は null）。
final currentRoleProvider = Provider<String?>(
  (ref) => ref.watch(currentProfileProvider).value?.role,
);

/// owner / admin は「管理者」。招待発行・ロール変更・現場の担当割当が可能。
bool isManagerRole(String? role) => role == 'owner' || role == 'admin';
