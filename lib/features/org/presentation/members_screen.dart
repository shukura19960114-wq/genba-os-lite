import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/application/current_profile_provider.dart';
import '../../auth/data/profile.dart';
import '../application/invite_controller.dart';
import '../application/member_controller.dart';
import '../application/members_providers.dart';
import '../data/invite.dart';

final _expiryFmt = DateFormat('yyyy/MM/dd HH:mm');

String _roleLabel(String? role) => switch (role) {
      'owner' => 'オーナー',
      'admin' => '管理者',
      'member' => 'メンバー',
      _ => '—',
    };

/// S-Members: メンバー管理（一覧・ロール変更）＋ 招待コード（発行・失効）。
/// owner/admin のみ到達する想定（ホーム導線で出し分け）。権限のない操作は RLS/RPC でも拒否。
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final isManager = isManagerRole(profile?.role);
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('メンバー管理')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(membersProvider);
          ref.invalidate(invitesProvider);
          await ref.read(membersProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isManager) ...[
              _InviteSection(companyId: profile?.companyId),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
            ],
            Text('メンバー', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            membersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('メンバーの取得に失敗しました：$e',
                    style: const TextStyle(color: Colors.grey)),
              ),
              data: (members) => Column(
                children: [
                  for (final m in members)
                    _MemberTile(
                      member: m,
                      isSelf: m.id == profile?.id,
                      canEdit: isManager,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 招待コードの発行・一覧・失効（owner/admin 用）。
class _InviteSection extends ConsumerWidget {
  const _InviteSection({required this.companyId});

  final String? companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(invitesProvider);
    final busy = ref.watch(inviteControllerProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('招待コード', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            FilledButton.icon(
              key: const Key('invite_create_button'),
              onPressed: (busy || companyId == null)
                  ? null
                  : () => _showCreateSheet(context, ref, companyId!),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('発行'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('新メンバーはサインアップ後、このコードを入力して参加します。',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        invitesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('招待コードの取得に失敗しました：$e',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          data: (invites) {
            if (invites.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('発行済みの招待コードはありません',
                    style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              children: [for (final inv in invites) _InviteTile(invite: inv)],
            );
          },
        ),
      ],
    );
  }

  Future<void> _showCreateSheet(
      BuildContext context, WidgetRef ref, String companyId) async {
    final messenger = ScaffoldMessenger.of(context);
    final role = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('どのロールで招待しますか？',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              key: const Key('invite_role_member'),
              leading: const Icon(Icons.person_outline),
              title: const Text('メンバーとして招待'),
              subtitle: const Text('現場・日報・写真の利用'),
              onTap: () => Navigator.pop(context, 'member'),
            ),
            ListTile(
              key: const Key('invite_role_admin'),
              leading: const Icon(Icons.shield_outlined),
              title: const Text('管理者（admin）として招待'),
              subtitle: const Text('メンバー管理・招待・担当割当も可能'),
              onTap: () => Navigator.pop(context, 'admin'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (role == null) return;
    final ok = await ref
        .read(inviteControllerProvider.notifier)
        .create(companyId: companyId, role: role);
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? '招待コードを発行しました' : '発行に失敗しました'),
    ));
  }
}

class _InviteTile extends ConsumerWidget {
  const _InviteTile({required this.invite});

  final Invite invite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = invite.isActive;
    final busy = ref.watch(inviteControllerProvider).isLoading;
    final subtitle = invite.revoked
        ? '失効済み'
        : (active
            ? '${invite.roleLabel}・期限 ${invite.expiresAt != null ? _expiryFmt.format(invite.expiresAt!.toLocal()) : "—"}'
            : '期限切れ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.vpn_key_outlined),
        title: Text(
          invite.code,
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
            color: active ? null : Colors.grey,
            decoration: active ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'コピー',
              icon: const Icon(Icons.copy, size: 20),
              onPressed: active
                  ? () {
                      Clipboard.setData(ClipboardData(text: invite.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('コードをコピーしました')),
                      );
                    }
                  : null,
            ),
            if (active)
              TextButton(
                key: Key('invite_revoke_${invite.id}'),
                onPressed: busy
                    ? null
                    : () => ref
                        .read(inviteControllerProvider.notifier)
                        .revoke(invite.id),
                child: const Text('失効'),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.member,
    required this.isSelf,
    required this.canEdit,
  });

  final Profile member;
  final bool isSelf;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = member.role == 'owner';
    // 自分・owner は変更不可。それ以外を owner/admin が変更できる。
    final editable = canEdit && !isSelf && !isOwner;
    final busy = ref.watch(memberControllerProvider).isLoading;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(isOwner ? Icons.star : Icons.person, size: 20),
        ),
        title: Text(member.email ?? '(メール未設定)'),
        subtitle: Text(
          isSelf ? '${_roleLabel(member.role)}・あなた' : _roleLabel(member.role),
        ),
        trailing: editable
            ? PopupMenuButton<String>(
                key: Key('member_role_menu_${member.id}'),
                enabled: !busy,
                onSelected: (role) async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await ref
                      .read(memberControllerProvider.notifier)
                      .changeRole(targetId: member.id, role: role);
                  messenger.showSnackBar(SnackBar(
                    content: Text(ok ? 'ロールを変更しました' : '変更に失敗しました'),
                  ));
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'member', child: Text('メンバーにする')),
                  const PopupMenuItem(
                      value: 'admin', child: Text('管理者にする')),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text('変更'), Icon(Icons.arrow_drop_down)],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
