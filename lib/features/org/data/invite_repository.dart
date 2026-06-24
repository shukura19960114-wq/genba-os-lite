import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import 'invite.dart';

/// 招待コード（company_invites）へのアクセス。RLS により owner/admin かつ自社のみ。
abstract interface class InviteRepository {
  /// 自社の招待コード一覧（新しい順）。
  Future<List<Invite>> listInvites();

  /// 招待コードを発行する（role: 'member' | 'admin'）。
  Future<Invite> createInvite({required String companyId, required String role});

  /// 招待コードを失効する。
  Future<void> revokeInvite(String id);
}

/// Supabase 実装。
class SupabaseInviteRepository implements InviteRepository {
  SupabaseInviteRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'company_invites';

  // 読み間違いの少ない文字集合（0/O, 1/I/L などを除外）。
  static const _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  @override
  Future<List<Invite>> listInvites() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return rows.map((e) => Invite.fromJson(e)).toList(growable: false);
  }

  @override
  Future<Invite> createInvite({
    required String companyId,
    required String role,
  }) async {
    // 一意制約に衝突したら数回までコードを変えて再試行する。
    final rng = Random.secure();
    PostgrestException? last;
    for (var attempt = 0; attempt < 4; attempt++) {
      final code = _generateCode(rng);
      try {
        final row = await _client
            .from(_table)
            .insert({'company_id': companyId, 'code': code, 'role': role})
            .select()
            .single();
        return Invite.fromJson(row);
      } on PostgrestException catch (e) {
        // 23505 = unique_violation。コードを変えて再試行。
        if (e.code == '23505') {
          last = e;
          continue;
        }
        rethrow;
      }
    }
    throw last ?? Exception('招待コードの発行に失敗しました');
  }

  @override
  Future<void> revokeInvite(String id) async {
    await _client.from(_table).update({'revoked': true}).eq('id', id);
  }

  String _generateCode(Random rng) => List.generate(
        8,
        (_) => _alphabet[rng.nextInt(_alphabet.length)],
      ).join();
}

/// [InviteRepository] を提供する Provider。
final inviteRepositoryProvider = Provider<InviteRepository>(
  (ref) => SupabaseInviteRepository(ref.watch(supabaseClientProvider)),
);
