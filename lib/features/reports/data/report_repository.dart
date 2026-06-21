import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'report.dart';

/// 日報（reports）データへのアクセス抽象。テストで Fake に差し替え可能。
abstract interface class ReportRepository {
  /// 現場の日報を新しい順（report_date desc, created_at desc）で取得。
  Future<List<Report>> listBySite(String siteId);

  /// 1件取得。
  Future<Report> fetch(String id);

  /// 新規作成。company_id / created_by はサーバ既定値に任せ送らない。
  Future<Report> create({
    required String siteId,
    required DateTime reportDate,
    String? weather,
    required String workContent,
    int? workerCount,
  });

  /// 編集。更新対象は report_date / weather / work_content / worker_count のみ。
  Future<Report> update({
    required String id,
    required DateTime reportDate,
    String? weather,
    required String workContent,
    int? workerCount,
  });

  /// 削除（UI導線は本フェーズでは作らない）。
  Future<void> delete(String id);
}

/// Supabase 実装。
class SupabaseReportRepository implements ReportRepository {
  SupabaseReportRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'reports';
  static final _dateFmt = DateFormat('yyyy-MM-dd'); // date型送信用

  @override
  Future<List<Report>> listBySite(String siteId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('site_id', siteId)
        .order('report_date', ascending: false)
        .order('created_at', ascending: false); // 同日内の安定した新しい順
    return rows
        .map((e) => Report.fromJson(e))
        .toList(growable: false);
  }

  @override
  Future<Report> fetch(String id) async {
    final row = await _client.from(_table).select().eq('id', id).single();
    return Report.fromJson(row);
  }

  @override
  Future<Report> create({
    required String siteId,
    required DateTime reportDate,
    String? weather,
    required String workContent,
    int? workerCount,
  }) async {
    final row = await _client
        .from(_table)
        .insert({
          'site_id': siteId,
          'report_date': _dateFmt.format(reportDate),
          'weather': weather, // null可
          'work_content': workContent,
          'worker_count': workerCount, // null可
          // company_id / created_by はDB既定値に任せる（送らない）
        })
        .select()
        .single();
    return Report.fromJson(row);
  }

  @override
  Future<Report> update({
    required String id,
    required DateTime reportDate,
    String? weather,
    required String workContent,
    int? workerCount,
  }) async {
    final row = await _client
        .from(_table)
        .update({
          'report_date': _dateFmt.format(reportDate),
          'weather': weather,
          'work_content': workContent,
          'worker_count': workerCount,
          // site_id / company_id / created_by は変更しない（送らない）
        })
        .eq('id', id)
        .select()
        .single();
    return Report.fromJson(row);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
