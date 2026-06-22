import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import 'site.dart';

/// 現場（sites）データへのアクセス抽象。テストでフェイクに差し替えられる。
abstract interface class SiteRepository {
  /// 自社の現場一覧（新しい順）。RLS により自社分のみ返る。
  Future<List<Site>> fetchSites();

  /// 現場を1件取得（無ければ null）。
  Future<Site?> fetchSite(String id);

  /// 現場を新規作成して作成後の行を返す。
  /// company_id は DB 既定値（current_company_id()）で自動設定される。
  Future<Site> createSite({required String name, String? address});

  /// 現場を更新して更新後の行を返す（company_id は変更しない＝送らない）。
  Future<Site> updateSite({
    required String id,
    required String name,
    String? address,
    required String status,
  });
}

/// Supabase 実装。
class SupabaseSiteRepository implements SiteRepository {
  SupabaseSiteRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Site>> fetchSites() async {
    final data = await _client
        .from('sites')
        .select()
        .order('created_at', ascending: false);
    return data
        .map((row) => Site.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<Site?> fetchSite(String id) async {
    final data =
        await _client.from('sites').select().eq('id', id).maybeSingle();
    return data == null ? null : Site.fromJson(data);
  }

  @override
  Future<Site> createSite({required String name, String? address}) async {
    final trimmedAddress = address?.trim();
    final data = await _client
        .from('sites')
        .insert({
          'name': name.trim(),
          if (trimmedAddress != null && trimmedAddress.isNotEmpty)
            'address': trimmedAddress,
        })
        .select()
        .single();
    return Site.fromJson(data);
  }

  @override
  Future<Site> updateSite({
    required String id,
    required String name,
    String? address,
    required String status,
  }) async {
    final trimmed = address?.trim();
    final data = await _client
        .from('sites')
        .update({
          'name': name.trim(),
          'address': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
          'status': status,
          // company_id は変更しない（送らない）
        })
        .eq('id', id)
        .select()
        .single();
    return Site.fromJson(data);
  }
}

/// [SiteRepository] を提供する Provider。
final siteRepositoryProvider = Provider<SiteRepository>(
  (ref) => SupabaseSiteRepository(ref.watch(supabaseClientProvider)),
);
