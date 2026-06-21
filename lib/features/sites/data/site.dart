import 'package:freezed_annotation/freezed_annotation.dart';

part 'site.freezed.dart';
part 'site.g.dart';

/// `sites` テーブルの1行（現場）。
///
/// DB は snake_case（`company_id` / `created_at`）。生成ファイルは build_runner で作成（Git管理外）。
@freezed
abstract class Site with _$Site {
  const factory Site({
    required String id,
    @JsonKey(name: 'company_id') String? companyId,
    required String name,
    String? address,
    @Default('active') String status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Site;

  factory Site.fromJson(Map<String, dynamic> json) => _$SiteFromJson(json);
}

/// ステータスの日本語表示ラベル。
String siteStatusLabel(String status) => switch (status) {
      'active' => '進行中',
      'completed' => '完了',
      'suspended' => '中止',
      _ => status,
    };
