/// ルートのパス定義。
///
/// Phase 1.1（認証）で /（home）・/login を追加。接続確認は /connection に移設。
abstract final class RoutePaths {
  static const home = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const members = '/members';
  static const connectionCheck = '/connection';
  static const sites = '/sites';
  static const siteNew = '/sites/new';
  static const siteDetail = '/sites/:id'; // 実遷移は '/sites/<id>'
  static const siteEdit = '/sites/:id/edit';

  // Phase 4 写真（現場配下）。実遷移は '/sites/<id>/photos[/<index>]'
  static const sitePhotos = '/sites/:id/photos';
  static const sitePhotoView = '/sites/:id/photos/:index';

  // Phase 2 日報（現場配下）。実遷移は '/sites/<siteId>/reports[/...]'
  static const siteReports = '/sites/:siteId/reports';
  static const siteReportNew = '/sites/:siteId/reports/new';
  static const siteReportDetail = '/sites/:siteId/reports/:reportId';
  static const siteReportEdit = '/sites/:siteId/reports/:reportId/edit';
}

/// ルート名（go_router の name 指定用）。
abstract final class RouteNames {
  static const home = 'home';
  static const login = 'login';
  static const signup = 'signup';
  static const members = 'members';
  static const connectionCheck = 'connectionCheck';
  static const sites = 'sites';
  static const siteNew = 'siteNew';
  static const siteDetail = 'siteDetail';
  static const siteEdit = 'siteEdit';

  static const sitePhotos = 'sitePhotos';
  static const sitePhotoView = 'sitePhotoView';

  static const siteReports = 'siteReports';
  static const siteReportNew = 'siteReportNew';
  static const siteReportDetail = 'siteReportDetail';
  static const siteReportEdit = 'siteReportEdit';
}
