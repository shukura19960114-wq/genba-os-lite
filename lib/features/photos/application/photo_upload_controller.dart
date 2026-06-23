import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/image_picker_service.dart';
import '../data/photo_repository.dart';
import 'photos_providers.dart';

/// アップロード結果（1枚）。
enum PhotoUploadResult { uploaded, cancelled, failed }

/// 複数追加の結果（追加枚数 / 失敗枚数 / キャンセル）。
typedef PhotosAddResult = ({int uploaded, int failed, bool cancelled});

/// 写真の撮影/選択 → アップロードを実行し、進行状態（loading/error）を保持する。
class PhotoUploadController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// 指定ソースから画像を取得してアップロードする。
  Future<PhotoUploadResult> addPhoto({
    required String siteId,
    required String companyId,
    required PhotoSource source,
  }) async {
    state = const AsyncValue.loading();
    try {
      final bytes = await ref.read(imagePickerServiceProvider).pick(source);
      if (bytes == null) {
        // ユーザーがキャンセル。エラーではないので待機状態に戻す。
        state = const AsyncValue.data(null);
        return PhotoUploadResult.cancelled;
      }
      await ref.read(photoRepositoryProvider).uploadPhoto(
            siteId: siteId,
            companyId: companyId,
            bytes: bytes,
          );
      state = const AsyncValue.data(null);
      ref.invalidate(photosProvider(siteId));
      return PhotoUploadResult.uploaded;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return PhotoUploadResult.failed;
    }
  }

  /// フォトライブラリから複数選択してまとめてアップロードする。
  /// 既存 [uploadPhoto] をループ呼び出し（Repository は増やさない）。
  Future<PhotosAddResult> addPhotos({
    required String siteId,
    required String companyId,
  }) async {
    state = const AsyncValue.loading();
    final bytesList = await ref.read(imagePickerServiceProvider).pickMultiple();
    if (bytesList.isEmpty) {
      state = const AsyncValue.data(null);
      return (uploaded: 0, failed: 0, cancelled: true);
    }
    var uploaded = 0;
    var failed = 0;
    Object? lastError;
    StackTrace? lastStack;
    for (final bytes in bytesList) {
      try {
        await ref.read(photoRepositoryProvider).uploadPhoto(
              siteId: siteId,
              companyId: companyId,
              bytes: bytes,
            );
        uploaded++;
      } catch (e, st) {
        failed++;
        lastError = e;
        lastStack = st;
      }
    }
    ref.invalidate(photosProvider(siteId));
    state = (failed > 0 && uploaded == 0)
        ? AsyncValue.error(lastError!, lastStack!)
        : const AsyncValue.data(null);
    return (uploaded: uploaded, failed: failed, cancelled: false);
  }
}

final photoUploadControllerProvider =
    AsyncNotifierProvider<PhotoUploadController, void>(PhotoUploadController.new);
