import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/auth/data/profile.dart';

void main() {
  group('Profile.fromJson', () {
    test('snake_case のキーを正しくマップする', () {
      final p = Profile.fromJson({
        'id': 'user-1',
        'company_id': 'company-1',
        'email': 'test@example.com',
        'role': 'owner',
        'created_at': '2026-06-21T00:00:00Z',
      });
      expect(p.id, 'user-1');
      expect(p.companyId, 'company-1');
      expect(p.email, 'test@example.com');
      expect(p.role, 'owner');
      expect(p.createdAt, isNotNull);
    });

    test('role 未指定なら member、company_id 未割当なら null', () {
      final p = Profile.fromJson({'id': 'user-2'});
      expect(p.role, 'member');
      expect(p.companyId, isNull);
      expect(p.email, isNull);
    });
  });
}
