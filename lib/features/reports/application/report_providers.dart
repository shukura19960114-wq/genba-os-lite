import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../data/report.dart';
import '../data/report_repository.dart';

/// Repository本体。§4.4: 既存の supabaseClientProvider を使用（Phase 1 と統一）。
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return SupabaseReportRepository(ref.watch(supabaseClientProvider));
});

/// 現場別 日報一覧（`AsyncValue<List<Report>>`）。
/// 再読み込み / 作成・編集成功時に ref.invalidate されて再フェッチ。
final reportsBySiteProvider =
    FutureProvider.family<List<Report>, String>((ref, siteId) async {
  return ref.watch(reportRepositoryProvider).listBySite(siteId);
});

/// 日報1件（`AsyncValue<Report>`）。S3 / S4(ラッパ) が watch。
final reportDetailProvider =
    FutureProvider.family<Report, String>((ref, id) async {
  return ref.watch(reportRepositoryProvider).fetch(id);
});
