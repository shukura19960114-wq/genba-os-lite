import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/sites/data/site.dart';

void main() {
  group('Site.fromJson', () {
    test('snake_case のキーをマップする', () {
      final s = Site.fromJson({
        'id': 'site-1',
        'company_id': 'company-1',
        'name': 'A現場',
        'address': '東京都港区1-2-3',
        'status': 'completed',
        'created_at': '2026-06-21T00:00:00Z',
      });
      expect(s.id, 'site-1');
      expect(s.companyId, 'company-1');
      expect(s.name, 'A現場');
      expect(s.address, '東京都港区1-2-3');
      expect(s.status, 'completed');
      expect(s.createdAt, isNotNull);
    });

    test('status 未指定なら active、address は null 可', () {
      final s = Site.fromJson({'id': 'site-2', 'name': 'B現場'});
      expect(s.status, 'active');
      expect(s.address, isNull);
    });
  });

  group('siteStatusLabel', () {
    test('日本語ラベルに変換', () {
      expect(siteStatusLabel('active'), '進行中');
      expect(siteStatusLabel('completed'), '完了');
      expect(siteStatusLabel('suspended'), '中止');
      expect(siteStatusLabel('unknown'), 'unknown'); // フォールバック
    });
  });
}
