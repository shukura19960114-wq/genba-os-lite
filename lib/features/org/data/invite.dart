import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite.freezed.dart';
part 'invite.g.dart';

/// `company_invites` テーブルの1行（招待コード）。
///
/// owner/admin が発行し、新メンバーがサインアップ後に `code` を入力して会社に参加する。
@freezed
abstract class Invite with _$Invite {
  const Invite._();

  const factory Invite({
    required String id,
    @JsonKey(name: 'company_id') required String companyId,
    required String code,
    @Default('member') String role,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    @Default(false) bool revoked,
  }) = _Invite;

  factory Invite.fromJson(Map<String, dynamic> json) => _$InviteFromJson(json);

  /// 失効しておらず、期限切れでもない（= まだ使える）。
  bool get isActive =>
      !revoked && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  /// 付与ロールの日本語ラベル。
  String get roleLabel => role == 'admin' ? '管理者' : 'メンバー';
}
