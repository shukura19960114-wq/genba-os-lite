import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config_provider.dart';
import '../application/connection_check_provider.dart';
import 'widgets/connection_status_card.dart';

/// 仕様書 1-8 の接続確認画面。
/// 「現在の環境（dev/prod）」と「Supabase接続：OK / NG」を表示し、
/// 失敗時はエラー内容を画面に出す。再試行ボタン付き。
class ConnectionCheckScreen extends ConsumerWidget {
  const ConnectionCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final statusAsync = ref.watch(connectionCheckProvider);

    return Scaffold(
      appBar: AppBar(title: Text(config.appName)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EnvChip(label: config.env.label),
                const SizedBox(height: 24),
                ConnectionStatusCard(statusAsync: statusAsync),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: statusAsync.isLoading
                      ? null
                      : () => ref.invalidate(connectionCheckProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('再接続を試す'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnvChip extends StatelessWidget {
  const _EnvChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.center,
      child: Chip(
        avatar: const Icon(Icons.layers_outlined, size: 18),
        label: Text(
          '環境：$label',
          style: theme.textTheme.titleMedium,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
