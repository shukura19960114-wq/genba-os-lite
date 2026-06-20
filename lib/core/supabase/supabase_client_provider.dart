import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 初期化済みの [SupabaseClient] を提供する Provider。
///
/// `Supabase.initialize(...)` は `bootstrap()` で1度だけ呼ばれる。
/// アプリ内で SupabaseClient に触れてよいのは（原則）data 層の repository だけで、
/// その repository はこの Provider から client を受け取る。
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);
