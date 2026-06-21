import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/photos/application/photo_upload_controller.dart';
import 'package:genba_os_lite/features/photos/application/photos_providers.dart';
import 'package:genba_os_lite/features/photos/data/image_picker_service.dart';
import 'package:genba_os_lite/features/photos/data/photo_repository.dart';

import 'fakes.dart';

void main() {
  group('PhotoUploadController', () {
    test('画像取得成功 → アップロードされ uploaded を返す', () async {
      final repo = FakePhotoRepository();
      final picker = FakeImagePickerService(bytes: Uint8List.fromList([1, 2, 3]));
      final container = ProviderContainer(overrides: [
        photoRepositoryProvider.overrideWithValue(repo),
        imagePickerServiceProvider.overrideWithValue(picker),
      ]);
      addTearDown(container.dispose);

      final result = await container
          .read(photoUploadControllerProvider.notifier)
          .addPhoto(siteId: 's1', companyId: 'c1', source: PhotoSource.gallery);

      expect(result, PhotoUploadResult.uploaded);
      expect(repo.uploadCalled, isTrue);
      expect(repo.lastUploadedSiteId, 's1');
      expect(picker.lastSource, PhotoSource.gallery);
      expect(container.read(photoUploadControllerProvider).hasError, isFalse);

      final photos = await container.read(photosProvider('s1').future);
      expect(photos, isNotEmpty);
    });

    test('キャンセル（null）→ アップロードせず cancelled', () async {
      final repo = FakePhotoRepository();
      final picker = FakeImagePickerService(bytes: null);
      final container = ProviderContainer(overrides: [
        photoRepositoryProvider.overrideWithValue(repo),
        imagePickerServiceProvider.overrideWithValue(picker),
      ]);
      addTearDown(container.dispose);

      final result = await container
          .read(photoUploadControllerProvider.notifier)
          .addPhoto(siteId: 's1', companyId: 'c1', source: PhotoSource.camera);

      expect(result, PhotoUploadResult.cancelled);
      expect(repo.uploadCalled, isFalse);
    });

    test('アップロード失敗 → failed、state はエラー', () async {
      final repo = FakePhotoRepository(failOnUpload: true);
      final picker = FakeImagePickerService(bytes: Uint8List.fromList([9]));
      final container = ProviderContainer(overrides: [
        photoRepositoryProvider.overrideWithValue(repo),
        imagePickerServiceProvider.overrideWithValue(picker),
      ]);
      addTearDown(container.dispose);

      final result = await container
          .read(photoUploadControllerProvider.notifier)
          .addPhoto(siteId: 's1', companyId: 'c1', source: PhotoSource.gallery);

      expect(result, PhotoUploadResult.failed);
      expect(container.read(photoUploadControllerProvider).hasError, isTrue);
    });
  });
}
