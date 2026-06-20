import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// 現在の [AppConfig] を提供する Provider。
///
/// ここでは「未実装の置き場」として宣言し、`bootstrap()` の `ProviderScope` で
/// `appConfigProvider.overrideWithValue(config)` により実際の値で上書きする。
/// これにより、秘密情報（URL/anon key）を含む構成を起動時に1か所だけで注入できる。
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider は bootstrap() の ProviderScope.overrides で '
    '上書きする必要があります。',
  ),
);
