import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/photos/data/photo.dart';

void main() {
  group('Photo.fromJson', () {
    test('snake_case のキーをマップする', () {
      final p = Photo.fromJson({
        'id': 'photo-1',
        'site_id': 'site-1',
        'company_id': 'company-1',
        'path': 'company-1/site-1/photo-1.jpg',
        'created_at': '2026-06-21T00:00:00Z',
      });
      expect(p.id, 'photo-1');
      expect(p.siteId, 'site-1');
      expect(p.companyId, 'company-1');
      expect(p.path, 'company-1/site-1/photo-1.jpg');
      expect(p.createdAt, isNotNull);
    });

    test('company_id / created_at は省略可', () {
      final p = Photo.fromJson({
        'id': 'photo-2',
        'site_id': 'site-2',
        'path': 'x/site-2/photo-2.jpg',
      });
      expect(p.companyId, isNull);
      expect(p.createdAt, isNull);
    });
  });
}
