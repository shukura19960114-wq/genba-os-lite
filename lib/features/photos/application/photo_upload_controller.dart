import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/image_picker_service.dart';
import '../data/photo_repository.dart';
import 'photos_providers.dart';

/// アップロード結果。
enum PhotoUploadResult { uploaded, cancelled, failed }

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
}

final photoUploadControllerProvider =
    AsyncNotifierProvider<PhotoUploadController, void>(PhotoUploadController.new);
