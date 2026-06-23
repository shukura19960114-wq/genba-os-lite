import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/photos/application/photo_upload_controller.dart';
import 'package:genba_os_lite/features/photos/data/image_picker_service.dart';
import 'package:genba_os_lite/features/photos/data/photo_repository.dart';

import 'fakes.dart';

Uint8List _b(int n) => Uint8List.fromList(List.filled(n, 1));

void main() {
  group('PhotoUploadController.addPhotos（複数）', () {
    test('複数選択 → 全枚数アップロードされ uploaded=件数', () async {
      final repo = FakePhotoRepository();
      final picker = FakeImagePickerService(multi: [_b(1), _b(2), _b(3)]);
      final container = ProviderContainer(overrides: [
        photoRepositoryProvider.overrideWithValue(repo),
        imagePickerServiceProvider.overrideWithValue(picker),
      ]);
      addTearDown(container.dispose);

      final result = await container
          .read(photoUploadControllerProvider.notifier)
          .addPhotos(siteId: 's1', companyId: 'c1');

      expect(result.uploaded, 3);
      expect(result.failed, 0);
      expect(result.cancelled, isFalse);
      expect(repo.uploadCount, 3);
      expect(container.read(photoUploadControllerProvider).hasError, isFalse);
    });

    test('空選択（キャンセル）→ アップロードされない', () async {
      final repo = FakePhotoRepository();
      final picker = FakeImagePickerService(multi: const []);
      final container = ProviderContainer(overrides: [
        photoRepositoryProvider.overrideWithValue(repo),
        imagePickerServiceProvider.overrideWithValue(picker),
      ]);
      addTearDown(container.dispose);

      final result = await container
          .read(photoUploadControllerProvider.notifier)
          .addPhotos(siteId: 's1', companyId: 'c1');

      expect(result.cancelled, isTrue);
      expect(result.uploaded, 0);
      expect(repo.uploadCount, 0);
    });

    test('全失敗 → failed=件数・state はエラー', () async {
      final repo = FakePhotoRepository(failOnUpload: true);
      final picker = FakeImagePickerService(multi: [_b(1), _b(2)]);
      final container = ProviderContainer(overrides: [
        photoRepositoryProvider.overrideWithValue(repo),
        imagePickerServiceProvider.overrideWithValue(picker),
      ]);
      addTearDown(container.dispose);

      final result = await container
          .read(photoUploadControllerProvider.notifier)
          .addPhotos(siteId: 's1', companyId: 'c1');

      expect(result.uploaded, 0);
      expect(result.failed, 2);
      expect(container.read(photoUploadControllerProvider).hasError, isTrue);
    });
  });
}
