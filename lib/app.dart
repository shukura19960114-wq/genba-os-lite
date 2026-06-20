import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// アプリのルートウィジェット。go_router と Material 3 テーマを束ねる。
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: ref.watch(appThemeProvider),
      darkTheme: ref.watch(appDarkThemeProvider),
      routerConfig: router,
    );
  }
}
