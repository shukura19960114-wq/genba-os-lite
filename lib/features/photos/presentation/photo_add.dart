import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/photo_upload_controller.dart';
import '../data/image_picker_service.dart';

enum _AddChoice { camera, library }

/// 写真追加のボトムシート（カメラ=1枚 / フォトライブラリ=複数）。
/// 現場詳細・ギャラリーの両方から呼ぶ共通フロー（新Providerなし・既存Controller流用）。
Future<void> showAddPhotoSheet(
  BuildContext context,
  WidgetRef ref, {
  required String siteId,
  required String companyId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final choice = await showModalBottomSheet<_AddChoice>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('カメラで撮影'),
            onTap: () => Navigator.of(context).pop(_AddChoice.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('フォトライブラリから選択（複数可）'),
            onTap: () => Navigator.of(context).pop(_AddChoice.library),
          ),
        ],
      ),
    ),
  );
  if (choice == null) return;

  final controller = ref.read(photoUploadControllerProvider.notifier);

  if (choice == _AddChoice.camera) {
    final result = await controller.addPhoto(
      siteId: siteId,
      companyId: companyId,
      source: PhotoSource.camera,
    );
    final msg = switch (result) {
      PhotoUploadResult.uploaded => '写真をアップロードしました',
      PhotoUploadResult.cancelled => null,
      PhotoUploadResult.failed => 'アップロードに失敗しました',
    };
    if (msg != null) {
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
  } else {
    final result = await controller.addPhotos(siteId: siteId, companyId: companyId);
    if (result.cancelled) return;
    final msg = result.failed == 0
        ? '${result.uploaded}枚追加しました'
        : '${result.uploaded}枚追加・${result.failed}枚失敗しました';
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }
}
