import 'package:genba_os_lite/features/sites/data/site.dart';
import 'package:genba_os_lite/features/sites/data/site_repository.dart';

/// テスト用の [SiteRepository] フェイク。
class FakeSiteRepository implements SiteRepository {
  FakeSiteRepository({
    List<Site> initial = const [],
    this.failOnCreate = false,
    this.failOnUpdate = false,
  }) : _sites = [...initial];

  final List<Site> _sites;
  final bool failOnCreate;
  final bool failOnUpdate;

  bool createCalled = false;
  String? lastCreatedName;
  Site? lastUpdated;

  @override
  Future<List<Site>> fetchSites() async => List.unmodifiable(_sites);

  @override
  Future<Site?> fetchSite(String id) async {
    for (final s in _sites) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Future<Site> createSite({required String name, String? address}) async {
    createCalled = true;
    lastCreatedName = name;
    if (failOnCreate) {
      throw Exception('作成に失敗（テスト）');
    }
    final site = Site(
      id: 'generated-${_sites.length + 1}',
      companyId: 'company-1',
      name: name,
      address: address,
      status: 'active',
    );
    _sites.insert(0, site);
    return site;
  }

  @override
  Future<Site> updateSite({
    required String id,
    required String name,
    String? address,
    required String status,
  }) async {
    if (failOnUpdate) {
      throw Exception('更新に失敗（テスト）');
    }
    final site = Site(
      id: id,
      companyId: 'company-1',
      name: name,
      address: address,
      status: status,
    );
    lastUpdated = site;
    return site;
  }
}
