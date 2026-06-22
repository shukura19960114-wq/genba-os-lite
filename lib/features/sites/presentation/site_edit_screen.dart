import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/site_edit_controller.dart';
import '../application/sites_providers.dart';
import '../data/site.dart';

const _statuses = <String>['active', 'completed', 'suspended'];

/// 現場編集画面（S-Edit）。詳細をロードしてフォームへ既存値を渡す。
class SiteEditScreen extends ConsumerWidget {
  const SiteEditScreen({super.key, required this.siteId});

  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteDetailProvider(siteId));

    return siteAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('現場の編集')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('現場の編集')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('現場の取得に失敗しました'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(siteDetailProvider(siteId)),
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
      data: (site) {
        if (site == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('現場の編集')),
            body: const Center(child: Text('現場が見つかりませんでした')),
          );
        }
        return _SiteEditForm(site: site);
      },
    );
  }
}

class _SiteEditForm extends ConsumerStatefulWidget {
  const _SiteEditForm({required this.site});

  final Site site;

  @override
  ConsumerState<_SiteEditForm> createState() => _SiteEditFormState();
}

class _SiteEditFormState extends ConsumerState<_SiteEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.site.name);
    _addressController = TextEditingController(text: widget.site.address ?? '');
    _status = _statuses.contains(widget.site.status)
        ? widget.site.status
        : 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(siteEditControllerProvider.notifier).submit(
          id: widget.site.id,
          name: _nameController.text,
          address: _addressController.text,
          status: _status,
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('現場を更新しました')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(siteEditControllerProvider).isLoading;

    // 更新失敗時の SnackBar 通知。
    ref.listen<AsyncValue<void>>(siteEditControllerProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('更新に失敗しました。通信状況を確認して再度お試しください。'),
            ),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('現場の編集')),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('site_edit_name_field'),
                      controller: _nameController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: '現場名（必須）',
                        prefixIcon: Icon(Icons.location_city_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? '現場名を入力してください'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('site_edit_address_field'),
                      controller: _addressController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: '住所（任意）',
                        prefixIcon: Icon(Icons.place_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: const Key('site_edit_status_field'),
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'ステータス',
                        prefixIcon: Icon(Icons.flag_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: _statuses
                          .map((c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(siteStatusLabel(c)),
                              ))
                          .toList(),
                      onChanged: isLoading
                          ? null
                          : (v) => setState(() => _status = v ?? _status),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('site_edit_submit_button'),
                      onPressed: isLoading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('更新'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
