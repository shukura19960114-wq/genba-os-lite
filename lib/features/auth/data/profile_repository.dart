import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import 'profile.dart';

/// `profiles` / `companies` テーブルへの読み取り（RLS により自社データのみ取得）。
class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  /// ログイン中ユーザーのプロフィールを取得（未ログイン/未作成なら null）。
  Future<Profile?> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromJson(data);
  }

  /// 会社名を取得（見つからなければ null）。
  Future<String?> fetchCompanyName(String companyId) async {
    final data = await _client
        .from('companies')
        .select('name')
        .eq('id', companyId)
        .maybeSingle();
    return data?['name'] as String?;
  }
}

/// [ProfileRepository] を提供する Provider。
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);
