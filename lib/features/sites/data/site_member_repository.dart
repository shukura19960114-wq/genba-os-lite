import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';

/// 現場に割り当てられたメンバー1人（site_members ＋ profiles の埋め込み）。
class AssignedMember {
  const AssignedMember({
    required this.profileId,
    this.email,
    this.role = 'member',
    this.assignedAt,
  });

  final String profileId;
  final String? email;
  final String role;
  final DateTime? assignedAt;

  factory AssignedMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return AssignedMember(
      profileId: json['profile_id'] as String,
      email: profile?['email'] as String?,
      role: (profile?['role'] as String?) ?? 'member',
      assignedAt: json['assigned_at'] == null
          ? null
          : DateTime.parse(json['assigned_at'] as String),
    );
  }
}

/// 現場の担当メンバー（site_members）の閲覧と割当/解除。
///
/// 閲覧は自社の現場なら可（RLS）。割当/解除は owner/admin のみ（RLS で強制）。
abstract interface class SiteMemberRepository {
  /// 現場の担当メンバー一覧（プロフィール情報付き）。
  Future<List<AssignedMember>> listForSite(String siteId);

  /// メンバーを現場に割り当てる。
  Future<void> assign({required String siteId, required String profileId});

  /// 割当を解除する。
  Future<void> unassign({required String siteId, required String profileId});
}

/// Supabase 実装。
class SupabaseSiteMemberRepository implements SiteMemberRepository {
  SupabaseSiteMemberRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'site_members';

  @override
  Future<List<AssignedMember>> listForSite(String siteId) async {
    final rows = await _client
        .from(_table)
        .select('profile_id, assigned_at, profiles(id, email, role)')
        .eq('site_id', siteId)
        .order('assigned_at', ascending: true);
    return rows
        .map((e) => AssignedMember.fromJson(e))
        .toList(growable: false);
  }

  @override
  Future<void> assign({
    required String siteId,
    required String profileId,
  }) async {
    await _client.from(_table).insert({
      'site_id': siteId,
      'profile_id': profileId,
      'assigned_by': _client.auth.currentUser?.id,
    });
  }

  @override
  Future<void> unassign({
    required String siteId,
    required String profileId,
  }) async {
    await _client
        .from(_table)
        .delete()
        .eq('site_id', siteId)
        .eq('profile_id', profileId);
  }
}

/// [SiteMemberRepository] を提供する Provider。
final siteMemberRepositoryProvider = Provider<SiteMemberRepository>(
  (ref) => SupabaseSiteMemberRepository(ref.watch(supabaseClientProvider)),
);
