import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_health_check.dart';

/// 接続状態（確認中 / OK / NG＋エラー）を表示するカード。
class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({super.key, required this.statusAsync});

  final AsyncValue<ConnectionStatus> statusAsync;

  @override
  Widget build(BuildContext context) {
    return statusAsync.when(
      loading: () => const _StatusBody(
        icon: Icons.sync,
        color: Colors.blueGrey,
        title: 'Supabase接続：確認中…',
      ),
      data: (status) => status.isOk
          ? const _StatusBody(
              icon: Icons.check_circle,
              color: Colors.green,
              title: 'Supabase接続：OK',
            )
          : _StatusBody(
              icon: Icons.error,
              color: Colors.red,
              title: 'Supabase接続：NG',
              detail: status.errorMessage,
            ),
      error: (error, _) => _StatusBody(
        icon: Icons.error,
        color: Colors.red,
        title: 'Supabase接続：NG',
        detail: error.toString(),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({
    required this.icon,
    required this.color,
    required this.title,
    this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(
                detail!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
