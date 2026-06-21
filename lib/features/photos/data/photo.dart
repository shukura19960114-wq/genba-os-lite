import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo.freezed.dart';
part 'photo.g.dart';

/// `photos` テーブルの1行（現場写真）。
///
/// `path` は Storage 内のパス（`{company_id}/{site_id}/{photo_id}.jpg`）。
/// 表示用の URL は private バケットの署名付きURLを別途生成する。
@freezed
abstract class Photo with _$Photo {
  const factory Photo({
    required String id,
    @JsonKey(name: 'site_id') required String siteId,
    @JsonKey(name: 'company_id') String? companyId,
    required String path,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Photo;

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);
}
