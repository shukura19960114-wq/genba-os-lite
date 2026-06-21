import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/reports/application/report_form_controller.dart';
import 'package:genba_os_lite/features/reports/application/report_providers.dart';
import 'package:genba_os_lite/features/reports/data/report.dart';
import 'package:genba_os_lite/features/reports/data/report_repository.dart';

class FakeReportRepository implements ReportRepository {
  FakeReportRepository({this.shouldThrow = false});
  bool shouldThrow;
  Report? lastCreated;
  Report? lastUpdated;

  Report _dummy(String id) => Report(
        id: id,
        companyId: 'c',
        siteId: 's',
        reportDate: DateTime(2026, 6, 21),
        weather: 'sunny',
        workContent: 'x',
        workerCount: 3,
        createdBy: 'u',
        createdAt: DateTime(2026, 6, 21),
        updatedAt: DateTime(2026, 6, 21),
      );

  @override
  Future<Report> create({
    required String siteId,
    required DateTime reportDate,
    String? weather,
    required String workContent,
    int? workerCount,
  }) async {
    if (shouldThrow) throw Exception('create failed');
    return lastCreated = _dummy('new-id');
  }

  @override
  Future<Report> update({
    required String id,
    required DateTime reportDate,
    String? weather,
    required String workContent,
    int? workerCount,
  }) async {
    if (shouldThrow) throw Exception('update failed');
    return lastUpdated = _dummy(id);
  }

  @override
  Future<List<Report>> listBySite(String siteId) async => [];

  @override
  Future<Report> fetch(String id) async => _dummy(id);

  @override
  Future<void> delete(String id) async {}
}

void main() {
  ProviderContainer makeContainer(FakeReportRepository fake) {
    final container = ProviderContainer(
      overrides: [reportRepositoryProvider.overrideWithValue(fake)],
    );
    // autoDispose を生かしたまま保持するため購読を張る。
    container.listen(reportFormControllerProvider, (_, _) {},
        fireImmediately: true);
    addTearDown(container.dispose);
    return container;
  }

  group('ReportFormController', () {
    test('submitCreate 成功 → 非nullを返し state はエラーなし', () async {
      final fake = FakeReportRepository();
      final container = makeContainer(fake);

      final result = await container
          .read(reportFormControllerProvider.notifier)
          .submitCreate(
            siteId: 's',
            reportDate: DateTime(2026, 6, 21),
            workContent: '作業',
          );

      expect(result, isNotNull);
      expect(fake.lastCreated, isNotNull);
      expect(container.read(reportFormControllerProvider).hasError, isFalse);
    });

    test('submitCreate 失敗 → null、state はエラー', () async {
      final fake = FakeReportRepository(shouldThrow: true);
      final container = makeContainer(fake);

      final result = await container
          .read(reportFormControllerProvider.notifier)
          .submitCreate(
            siteId: 's',
            reportDate: DateTime(2026, 6, 21),
            workContent: '作業',
          );

      expect(result, isNull);
      expect(container.read(reportFormControllerProvider).hasError, isTrue);
    });

    test('submitUpdate 成功 → 非nullを返し state はエラーなし', () async {
      final fake = FakeReportRepository();
      final container = makeContainer(fake);

      final result = await container
          .read(reportFormControllerProvider.notifier)
          .submitUpdate(
            id: 'r1',
            siteId: 's',
            reportDate: DateTime(2026, 6, 21),
            workContent: '作業',
          );

      expect(result, isNotNull);
      expect(fake.lastUpdated, isNotNull);
      expect(container.read(reportFormControllerProvider).hasError, isFalse);
    });

    test('submitUpdate 失敗 → null、state はエラー', () async {
      final fake = FakeReportRepository(shouldThrow: true);
      final container = makeContainer(fake);

      final result = await container
          .read(reportFormControllerProvider.notifier)
          .submitUpdate(
            id: 'r1',
            siteId: 's',
            reportDate: DateTime(2026, 6, 21),
            workContent: '作業',
          );

      expect(result, isNull);
      expect(container.read(reportFormControllerProvider).hasError, isTrue);
    });
  });
}
