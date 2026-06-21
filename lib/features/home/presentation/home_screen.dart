import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/auth_repository.dart';

/// ログイン後のホーム画面（Phase 1.1 では最小構成）。
///
/// ログイン中ユーザーのメール・ロール・会社名を表示し、ログアウトできる。
/// 現場一覧などの本体機能は Phase 1.2 以降で追加する。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final homeAsync = ref.watch(homeProfileProvider);
    final authState = ref.watch(authControllerProvider);
    final email = ref.watch(authRepositoryProvider).currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: Text(config.appName),
        actions: [
          IconButton(
            tooltip: '接続確認',
            onPressed: () => context.push(RoutePaths.connectionCheck),
            icon: const Icon(Icons.wifi_tethering),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 56),
                const SizedBox(height: 12),
                Text(
                  'ログイン中',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: homeAsync.when(
                      data: (home) => _ProfileInfo(
                        email: email ?? home.profile?.email ?? '(不明)',
                        role: home.profile?.role,
                        companyName: home.companyName,
                        companyId: home.profile?.companyId,
                      ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      // プロフィール取得に失敗してもログイン自体は成功しているので、
                      // メールだけは表示する。
                      error: (e, _) => _ProfileInfo(
                        email: email ?? '(不明)',
                        role: null,
                        companyName: null,
                        companyId: null,
                        note: 'プロフィール情報を取得できませんでした（テーブル未作成の可能性）。',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('home_sites_button'),
                  onPressed: () => context.push(RoutePaths.sites),
                  icon: const Icon(Icons.location_city_outlined),
                  label: const Text('現場一覧へ'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('home_logout_button'),
                  onPressed: authState.isLoading
                      ? null
                      : () => ref.read(authControllerProvider.notifier).signOut(),
                  icon: authState.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: const Text('ログアウト'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({
    required this.email,
    required this.role,
    required this.companyName,
    required this.companyId,
    this.note,
  });

  final String email;
  final String? role;
  final String? companyName;
  final String? companyId;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(context, Icons.mail_outline, 'メール', email),
        const Divider(height: 20),
        _row(context, Icons.badge_outlined, 'ロール', role ?? '—'),
        const Divider(height: 20),
        _row(
          context,
          Icons.apartment_outlined,
          '会社',
          companyName ?? (companyId == null ? '未割当' : companyId!),
        ),
        if (note != null) ...[
          const SizedBox(height: 12),
          Text(
            note!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        SizedBox(
          width: 56,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
