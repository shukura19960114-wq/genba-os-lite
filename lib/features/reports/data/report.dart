import 'package:freezed_annotation/freezed_annotation.dart';

part 'report.freezed.dart';
part 'report.g.dart';

/// 天候コードと日本語ラベルのヘルパー。
/// DBはtext。アプリ側で値を固定する。
class WeatherCode {
  static const sunny = 'sunny';
  static const cloudy = 'cloudy';
  static const rainy = 'rainy';
  static const snowy = 'snowy';

  /// フォームのDropdown用（先頭=未選択を別途nullで追加）
  static const all = <String>[sunny, cloudy, rainy, snowy];

  static String label(String? code) {
    switch (code) {
      case sunny:
        return '晴れ';
      case cloudy:
        return 'くもり';
      case rainy:
        return '雨';
      case snowy:
        return '雪';
      default:
        return '—';
    }
  }
}

/// `reports` テーブルの1行（日報）。
///
/// JSONは snake_case（@JsonKeyで固定）。生成ファイルは build_runner で作成（Git管理外）。
/// 注意（freezed 3.x）: モデルは `abstract class ... with _$...`。
@freezed
abstract class Report with _$Report {
  const Report._();

  const factory Report({
    required String id,
    @JsonKey(name: 'company_id') required String companyId,
    @JsonKey(name: 'site_id') required String siteId,
    @JsonKey(name: 'report_date') required DateTime reportDate,
    String? weather,
    @JsonKey(name: 'work_content') required String workContent,
    @JsonKey(name: 'worker_count') int? workerCount,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Report;

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);

  String get weatherLabel => WeatherCode.label(weather);
}
