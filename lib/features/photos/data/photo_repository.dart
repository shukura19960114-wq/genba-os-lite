import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import 'photo.dart';

/// 写真（photos テーブル + Storage）へのアクセス抽象。テストで差し替え可能。
abstract interface class PhotoRepository {
  /// 指定現場の写真一覧（新しい順）。RLS により自社分のみ返る。
  Future<List<Photo>> listPhotos(String siteId);

  /// 画像をアップロードする。Storage に保存し、photos に行を作成して返す。
  /// 保存パスは `{companyId}/{siteId}/{uuid}.jpg`。
  Future<Photo> uploadPhoto({
    required String siteId,
    required String companyId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  });

  /// private バケットの表示用・署名付きURLを生成する。
  Future<String> createSignedUrl(String path, {int expiresInSeconds = 3600});

  /// Storage から画像バイトを取得する（写真台帳PDFの画像埋め込み用）。RLSで自社のみ。
  Future<Uint8List> downloadPhoto(String path);
}

/// Supabase 実装。
class SupabasePhotoRepository implements PhotoRepository {
  SupabasePhotoRepository(this._client, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final SupabaseClient _client;
  final Uuid _uuid;

  static const _bucket = 'photos';

  @override
  Future<List<Photo>> listPhotos(String siteId) async {
    final data = await _client
        .from('photos')
        .select()
        .eq('site_id', siteId)
        .order('created_at', ascending: false);
    return data.map((row) => Photo.fromJson(row)).toList(growable: false);
  }

  @override
  Future<Photo> uploadPhoto({
    required String siteId,
    required String companyId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final photoId = _uuid.v4();
    final path = '$companyId/$siteId/$photoId.jpg';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    final row = await _client
        .from('photos')
        .insert({'site_id': siteId, 'path': path})
        .select()
        .single();
    return Photo.fromJson(row);
  }

  @override
  Future<String> createSignedUrl(String path, {int expiresInSeconds = 3600}) {
    return _client.storage.from(_bucket).createSignedUrl(path, expiresInSeconds);
  }

  @override
  Future<Uint8List> downloadPhoto(String path) {
    return _client.storage.from(_bucket).download(path);
  }
}

/// [PhotoRepository] を提供する Provider。
final photoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => SupabasePhotoRepository(ref.watch(supabaseClientProvider)),
);
