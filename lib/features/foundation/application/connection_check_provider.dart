import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/supabase/supabase_health_check.dart';

/// Supabase 接続確認の結果を非同期に提供する。
///
/// 再試行は `ref.invalidate(connectionCheckProvider)` で行う。
final connectionCheckProvider = FutureProvider<ConnectionStatus>((ref) async {
  final config = ref.watch(appConfigProvider);
  return checkSupabaseConnection(config);
});
