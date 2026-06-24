import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';

/// 会社への参加・作成（security definer な RPC を呼ぶ）。
///
/// `redeem_invite` / `create_company` は 0005 マイグレーションで定義。
/// 会社未所属の本人だけが成功する（多重所属は DB 側で拒否）。
abstract interface class OrgRepository {
  /// 招待コードで会社に参加する。失敗時は [PostgrestException] を投げる。
  Future<void> redeemInvite(String code);

  /// 会社を新規作成し、自分が owner になる。失敗時は [PostgrestException] を投げる。
  Future<void> createCompany(String name);
}

/// Supabase 実装（RPC 呼び出し）。
class SupabaseOrgRepository implements OrgRepository {
  SupabaseOrgRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> redeemInvite(String code) async {
    await _client.rpc('redeem_invite', params: {'p_code': code.trim()});
  }

  @override
  Future<void> createCompany(String name) async {
    await _client.rpc('create_company', params: {'p_name': name.trim()});
  }
}

/// [OrgRepository] を提供する Provider（テストで差し替え可能）。
final orgRepositoryProvider = Provider<OrgRepository>(
  (ref) => SupabaseOrgRepository(ref.watch(supabaseClientProvider)),
);

/// 会社参加・作成の RPC 例外を、画面表示用の日本語メッセージに変換する。
String orgErrorMessage(Object error) {
  final raw = error is PostgrestException ? error.message : error.toString();
  final m = raw.toLowerCase();
  if (m.contains('invalid_code')) {
    return '招待コードが正しくないか、有効期限切れ・失効済みです。';
  }
  if (m.contains('already_in_company')) {
    return 'すでに会社に所属しています。';
  }
  if (m.contains('empty_name')) {
    return '会社名を入力してください。';
  }
  if (m.contains('not_authenticated')) {
    return 'ログインが必要です。';
  }
  return '処理に失敗しました：$raw';
}
