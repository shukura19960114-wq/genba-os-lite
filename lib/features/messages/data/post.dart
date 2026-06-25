import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

/// `site_posts` テーブルの1行（現場連絡メッセージ）。
///
/// 一覧取得時は `profiles(email)` を埋め込んで投稿者メールを取得する。
@freezed
abstract class Post with _$Post {
  const Post._();

  const factory Post({
    required String id,
    @JsonKey(name: 'site_id') required String siteId,
    @JsonKey(name: 'author_id') String? authorId,
    required String body,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'author_email') String? authorEmail,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  /// 表示用の投稿者ラベル。
  String get authorLabel => authorEmail ?? '(不明)';
}
