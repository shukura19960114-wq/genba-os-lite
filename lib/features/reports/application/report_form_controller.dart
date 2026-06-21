import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/report.dart';
import 'report_providers.dart';

/// 日報の作成/編集の送信進行（loading/完了/失敗）を保持するコントローラ。
/// 結果 [Report] は戻り値で画面へ返す（ナビゲーション用）。
/// autoDispose: フォームを離れると状態をリセットする（Riverpod 3.x の正式API）。
final reportFormControllerProvider =
    AsyncNotifierProvider.autoDispose<ReportFormController, void>(
  ReportFormController.new,
);

class ReportFormController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // 初期処理なし
  }

  /// 作成。成功時: 一覧をinvalidateし、生成Reportを返す。失敗時: stateをエラーにしnullを返す。
  Future<Report?> submitCreate({
    required String siteId,
    required DateTime reportDate,
    String? weather,
    required String workContent,
    int? workerCount,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(reportRepositoryProvider).create(
            siteId: siteId,
            reportDate: reportDate,
            weather: weather,
            workContent: workContent,
            workerCount: workerCount,
          );
    });
    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      return null;
    }
    ref.invalidate(reportsBySiteProvider(siteId));
    state = const AsyncData(null);
    return result.value;
  }

  /// 編集。成功時: 該当詳細と現場一覧をinvalidateし、更新Reportを返す。失敗時: stateをエラーにしnullを返す。
  Future<Report?> submitUpdate({
    required String id,
    required String siteId,
    required DateTime reportDate,
    String? weather,
    required String workContent,
    int? workerCount,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(reportRepositoryProvider).update(
            id: id,
            reportDate: reportDate,
            weather: weather,
            workContent: workContent,
            workerCount: workerCount,
          );
    });
    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      return null;
    }
    ref.invalidate(reportDetailProvider(id));
    ref.invalidate(reportsBySiteProvider(siteId));
    state = const AsyncData(null);
    return result.value;
  }
}
