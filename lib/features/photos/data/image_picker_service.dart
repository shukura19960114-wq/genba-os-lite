import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// 写真の取得元。
enum PhotoSource { camera, gallery }

/// 画像取得の抽象（テストでフェイクに差し替え可能にし、image_picker を直接触らせない）。
abstract interface class ImagePickerService {
  /// 撮影/選択した画像のバイト列を返す。キャンセル時は null。
  Future<Uint8List?> pick(PhotoSource source);

  /// フォトライブラリから複数選択した画像のバイト列を返す。キャンセル時は空リスト。
  Future<List<Uint8List>> pickMultiple();
}

/// image_picker 実装。撮影時に幅・画質を抑えて軽量化する（別パッケージの圧縮は不要）。
class ImagePickerServiceImpl implements ImagePickerService {
  ImagePickerServiceImpl([ImagePicker? picker])
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  @override
  Future<List<Uint8List>> pickMultiple() async {
    final files = await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 80);
    final result = <Uint8List>[];
    for (final file in files) {
      result.add(await file.readAsBytes());
    }
    return result; // キャンセル時は空リスト
  }
}

final imagePickerServiceProvider = Provider<ImagePickerService>(
  (ref) => ImagePickerServiceImpl(),
);
