import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/reports/data/report.dart';

void main() {
  final fullJson = {
    'id': '11111111-1111-1111-1111-111111111111',
    'company_id': '22222222-2222-2222-2222-222222222222',
    'site_id': '33333333-3333-3333-3333-333333333333',
    'report_date': '2026-06-21',
    'weather': 'sunny',
    'work_content': '基礎配筋',
    'worker_count': 5,
    'created_by': '44444444-4444-4444-4444-444444444444',
    'created_at': '2026-06-21T01:23:45.000Z',
    'updated_at': '2026-06-21T02:34:56.000Z',
  };

  group('Report.fromJson', () {
    test('全項目あり: snake_case を各フィールドへマップ', () {
      final r = Report.fromJson(fullJson);
      expect(r.id, '11111111-1111-1111-1111-111111111111');
      expect(r.companyId, '22222222-2222-2222-2222-222222222222');
      expect(r.siteId, '33333333-3333-3333-3333-333333333333');
      expect(r.reportDate.year, 2026);
      expect(r.reportDate.month, 6);
      expect(r.reportDate.day, 21);
      expect(r.weather, 'sunny');
      expect(r.workContent, '基礎配筋');
      expect(r.workerCount, 5);
      expect(r.createdBy, '44444444-4444-4444-4444-444444444444');
      expect(r.createdAt, isNotNull);
      expect(r.updatedAt, isNotNull);
    });

    test('null項目: weather/worker_count/created_by が null でも生成できる', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..['weather'] = null
        ..['worker_count'] = null
        ..['created_by'] = null;
      final r = Report.fromJson(json);
      expect(r.weather, isNull);
      expect(r.workerCount, isNull);
      expect(r.createdBy, isNull);
    });
  });

  group('weatherLabel', () {
    test('コード→日本語ラベル', () {
      expect(WeatherCode.label('sunny'), '晴れ');
      expect(WeatherCode.label('cloudy'), 'くもり');
      expect(WeatherCode.label('rainy'), '雨');
      expect(WeatherCode.label('snowy'), '雪');
      expect(WeatherCode.label(null), '—');
    });

    test('Report.weatherLabel が機能する', () {
      final r = Report.fromJson(fullJson);
      expect(r.weatherLabel, '晴れ');
    });
  });
}
