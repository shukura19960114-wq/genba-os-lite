import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/data/profile.dart';

/// 自社メンバー（profiles）の閲覧とロール変更。
///
/// 閲覧は RLS（同一会社）で自社のみ。ロール変更は security definer な
/// `set_member_role` RPC（owner/admin・他人・非owner のみ成功）。
abstract interface class MemberRepository {
  /// 自社メンバー一覧（登録順）。
  Future<List<Profile>> listMembers();

  /// メンバーのロールを変更する（role: 'member' | 'admin'）。
  Future<void> setMemberRole({required String targetId, required String role});
}

/// Supabase 実装。
class SupabaseMemberRepository implements MemberRepository {
  SupabaseMemberRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Profile>> listMembers() async {
    final rows = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: true);
    return rows.map((e) => Profile.fromJson(e)).toList(growable: false);
  }

  @override
  Future<void> setMemberRole({
    required String targetId,
    required String role,
  }) async {
    await _client.rpc('set_member_role', params: {
      'p_target': targetId,
      'p_role': role,
    });
  }
}

/// [MemberRepository] を提供する Provider。
final memberRepositoryProvider = Provider<MemberRepository>(
  (ref) => SupabaseMemberRepository(ref.watch(supabaseClientProvider)),
);
