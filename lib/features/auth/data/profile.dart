import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// `profiles` テーブルの1行（= ログインユーザーのプロフィール）。
///
/// DB のカラムは snake_case（`company_id` 等）なので `@JsonKey` で対応付ける。
/// 生成ファイル（profile.freezed.dart / profile.g.dart）は build_runner で作成（Git管理外）。
///   dart run build_runner build --delete-conflicting-outputs
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    @JsonKey(name: 'company_id') String? companyId,
    String? email,
    @Default('member') String role,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}
