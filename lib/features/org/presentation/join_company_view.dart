import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/join_controller.dart';
import '../data/org_repository.dart';

/// 会社未所属のユーザーに表示する「会社に参加 / 作成」画面（ホーム内に埋め込む）。
///
/// ① 招待コードで参加（owner/admin が発行したコードを入力）
/// ② 会社を新規作成（自分が owner になる）
/// 成功すると currentProfileProvider が invalidate され、ホーム本体に切り替わる。
class JoinCompanyView extends ConsumerStatefulWidget {
  const JoinCompanyView({super.key});

  @override
  ConsumerState<JoinCompanyView> createState() => _JoinCompanyViewState();
}

class _JoinCompanyViewState extends ConsumerState<JoinCompanyView> {
  final _codeController = TextEditingController();
  final _companyController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _snack('招待コードを入力してください');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final ok =
        await ref.read(joinControllerProvider.notifier).joinWithCode(code);
    if (!ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(orgErrorMessage(
            ref.read(joinControllerProvider).error ?? '参加に失敗しました')),
      ));
    }
  }

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    final name = _companyController.text.trim();
    if (name.isEmpty) {
      _snack('会社名を入力してください');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final ok =
        await ref.read(joinControllerProvider.notifier).createCompany(name);
    if (!ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(orgErrorMessage(
            ref.read(joinControllerProvider).error ?? '作成に失敗しました')),
      ));
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(joinControllerProvider).isLoading;

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.groups_outlined, size: 56, color: Colors.blueGrey),
                const SizedBox(height: 12),
                Text(
                  'まだ会社に参加していません',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  '招待コードで参加するか、新しい会社を作成してください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // ① 招待コードで参加
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.vpn_key_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text('招待コードで参加',
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const Key('join_code_field'),
                          controller: _codeController,
                          enabled: !isBusy,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: '招待コード',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          key: const Key('join_submit_button'),
                          onPressed: isBusy ? null : _join,
                          child: const Text('参加する'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ② 会社を新規作成
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.add_business_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text('会社を新しく作る',
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('あなたが owner（管理者）になります。',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 12),
                        TextField(
                          key: const Key('create_company_field'),
                          controller: _companyController,
                          enabled: !isBusy,
                          decoration: const InputDecoration(
                            labelText: '会社名',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          key: const Key('create_company_button'),
                          onPressed: isBusy ? null : _create,
                          child: const Text('作成して始める'),
                        ),
                      ],
                    ),
                  ),
                ),

                if (isBusy) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
