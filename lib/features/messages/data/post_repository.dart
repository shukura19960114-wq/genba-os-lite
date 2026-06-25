import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import 'post.dart';

/// 現場連絡（site_posts）と未読（site_post_reads / RPC）へのアクセス。
abstract interface class PostRepository {
  /// 現場のメッセージ一覧（時系列・古い順）。投稿者メール付き。
  Future<List<Post>> listBySite(String siteId);

  /// メッセージを投稿する（company_id / author_id は DB 既定）。
  Future<void> create({required String siteId, required String body});

  /// この現場を既読にする（現在時刻で last_read_at を更新）。
  Future<void> markRead(String siteId);

  /// 現場ごとの未読件数 `{site_id: 件数}` を返す。
  Future<Map<String, int>> unreadCounts();
}

/// Supabase 実装。
class SupabasePostRepository implements PostRepository {
  SupabasePostRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'site_posts';

  @override
  Future<List<Post>> listBySite(String siteId) async {
    final rows = await _client
        .from(_table)
        .select('id, site_id, author_id, body, created_at, profiles(email)')
        .eq('site_id', siteId)
        .order('created_at', ascending: true);
    return rows.map((e) {
      // Supabase の埋め込み（profiles(email)）を author_email に展開。
      final profile = e['profiles'] as Map<String, dynamic>?;
      return Post.fromJson({...e, 'author_email': profile?['email']});
    }).toList(growable: false);
  }

  @override
  Future<void> create({required String siteId, required String body}) async {
    await _client.from(_table).insert({'site_id': siteId, 'body': body});
  }

  @override
  Future<void> markRead(String siteId) async {
    await _client.rpc('mark_site_read', params: {'p_site_id': siteId});
  }

  @override
  Future<Map<String, int>> unreadCounts() async {
    final rows = await _client.rpc('site_unread_counts') as List<dynamic>;
    final result = <String, int>{};
    for (final row in rows) {
      final m = row as Map<String, dynamic>;
      result[m['site_id'] as String] = (m['unread'] as num).toInt();
    }
    return result;
  }
}

/// [PostRepository] を提供する Provider。
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => SupabasePostRepository(ref.watch(supabaseClientProvider)),
);
