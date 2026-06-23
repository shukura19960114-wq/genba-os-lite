import 'dart:typed_data';

import 'package:genba_os_lite/features/photos/data/image_picker_service.dart';
import 'package:genba_os_lite/features/photos/data/photo.dart';
import 'package:genba_os_lite/features/photos/data/photo_repository.dart';

/// テスト用 [PhotoRepository] フェイク。
class FakePhotoRepository implements PhotoRepository {
  FakePhotoRepository({List<Photo> initial = const [], this.failOnUpload = false})
      : _photos = [...initial];

  final List<Photo> _photos;
  final bool failOnUpload;

  bool uploadCalled = false;
  String? lastUploadedSiteId;
  int uploadCount = 0;

  @override
  Future<List<Photo>> listPhotos(String siteId) async =>
      _photos.where((p) => p.siteId == siteId).toList();

  @override
  Future<Photo> uploadPhoto({
    required String siteId,
    required String companyId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    uploadCalled = true;
    uploadCount++;
    lastUploadedSiteId = siteId;
    if (failOnUpload) throw Exception('アップロード失敗（テスト）');
    final photo = Photo(
      id: 'photo-${_photos.length + 1}',
      siteId: siteId,
      companyId: companyId,
      path: '$companyId/$siteId/photo-${_photos.length + 1}.jpg',
    );
    _photos.insert(0, photo);
    return photo;
  }

  @override
  Future<String> createSignedUrl(String path, {int expiresInSeconds = 3600}) async =>
      'https://example.com/signed/$path';
}

/// テスト用 [ImagePickerService] フェイク。bytes が null ならキャンセル相当。
class FakeImagePickerService implements ImagePickerService {
  FakeImagePickerService({this.bytes, this.multi = const []});

  final Uint8List? bytes;
  final List<Uint8List> multi;
  PhotoSource? lastSource;

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    lastSource = source;
    return bytes;
  }

  @override
  Future<List<Uint8List>> pickMultiple() async => multi;
}
