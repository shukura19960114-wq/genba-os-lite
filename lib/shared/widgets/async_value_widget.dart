import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `AsyncValue<T>` を「データ / ローディング / エラー」の3状態で
/// 統一的に描画する共通ウィジェット。後続フェーズの一覧・詳細画面で再利用する。
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: loading ?? () => const Center(child: CircularProgressIndicator()),
      error: error ??
          (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('エラー: $e', textAlign: TextAlign.center),
                ),
              ),
    );
  }
}
