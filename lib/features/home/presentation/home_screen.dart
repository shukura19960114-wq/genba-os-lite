import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/current_profile_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../org/presentation/join_company_view.dart';

/// ログイン後のホーム画面。
///
/// 会社未所属なら「会社に参加/作成」（[JoinCompanyView]）を表示し、
/// 所属済みならプロフィール・現場一覧導線・（管理者のみ）メンバー管理を表示する。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(config.appName),
        actions: [
          IconButton(
            tooltip: '接続確認',
            onPressed: () => context.push(RoutePaths.connectionCheck),
            icon: const Icon(Icons.wifi_tethering),
          ),
          IconButton(
            key: const Key('home_logout_icon'),
            tooltip: 'ログアウト',
            onPressed: authState.isLoading
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _HomeBodyFallback(
          email: ref.watch(authRepositoryProvider).currentUser?.email,
          note: 'プロフィール情報を取得できませんでした（テーブル未作成の可能性）。',
        ),
        data: (profile) {
          // 会社未所属 → 参加/作成画面。
          if (profile == null || profile.companyId == null) {
            return const JoinCompanyView();
          }
          return const _HomeBody();
        },
      ),
    );
  }
}

/// 会社所属済みのホーム本体（プロフィール + 現場一覧導線）。
class _HomeBody extends ConsumerWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProfileProvider);
    final email = ref.watch(authRepositoryProvider).currentUser?.email;
    final role = ref.watch(currentRoleProvider);
    final isManager = isManagerRole(role);

    return Center(
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
                    error: (e, _) => _ProfileInfo(
                      email: email ?? '(不明)',
                      role: role,
                      companyName: null,
                      companyId: null,
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
              if (isManager) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('home_members_button'),
                  onPressed: () => context.push(RoutePaths.members),
                  icon: const Icon(Icons.group_outlined),
                  label: const Text('メンバー管理'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// プロフィール取得失敗時の最小表示（メールのみ）。
class _HomeBodyFallback extends StatelessWidget {
  const _HomeBodyFallback({required this.email, required this.note});

  final String? email;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _ProfileInfo(
                email: email ?? '(不明)',
                role: null,
                companyName: null,
                companyId: null,
                note: note,
              ),
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
        _row(context, Icons.badge_outlined, 'ロール', _roleLabel(role)),
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

  static String _roleLabel(String? role) => switch (role) {
        'owner' => 'オーナー',
        'admin' => '管理者',
        'member' => 'メンバー',
        _ => '—',
      };

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
