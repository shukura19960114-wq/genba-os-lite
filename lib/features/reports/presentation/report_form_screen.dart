import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../application/report_form_controller.dart';
import '../data/report.dart';

final _dateFmt = DateFormat('yyyy/MM/dd');

/// S2(作成) / S4(編集) 共有フォーム。
/// initialReport == null = 作成モード、非null = 編集モード。
class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({
    super.key,
    required this.siteId,
    this.initialReport,
  });

  final String siteId;
  final Report? initialReport;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _workContentController;
  late final TextEditingController _workerCountController;
  late DateTime _reportDate;
  String? _weather;

  bool get _isEdit => widget.initialReport != null;

  @override
  void initState() {
    super.initState();
    final r = widget.initialReport;
    final now = DateTime.now();
    _reportDate = r != null
        ? r.reportDate
        : DateTime(now.year, now.month, now.day);
    _weather = r?.weather;
    _workContentController =
        TextEditingController(text: r?.workContent ?? '');
    _workerCountController =
        TextEditingController(text: r?.workerCount?.toString() ?? '');
  }

  @override
  void dispose() {
    _workContentController.dispose();
    _workerCountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reportDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _reportDate = picked);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final t = _workerCountController.text.trim();
    final workerCount = t.isEmpty ? null : int.parse(t);
    final controller = ref.read(reportFormControllerProvider.notifier);

    final Report? result;
    if (_isEdit) {
      result = await controller.submitUpdate(
        id: widget.initialReport!.id,
        siteId: widget.siteId,
        reportDate: _reportDate,
        weather: _weather,
        workContent: _workContentController.text,
        workerCount: workerCount,
      );
    } else {
      result = await controller.submitCreate(
        siteId: widget.siteId,
        reportDate: _reportDate,
        weather: _weather,
        workContent: _workContentController.text,
        workerCount: workerCount,
      );
    }

    if (result != null && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(reportFormControllerProvider).isLoading;

    // 送信失敗時の SnackBar 通知（§8.2）。
    ref.listen<AsyncValue<void>>(reportFormControllerProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        final msg = _isEdit
            ? '更新に失敗しました。通信状況を確認して再度お試しください。'
            : '保存に失敗しました。通信状況を確認して再度お試しください。';
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '日報編集' : '日報作成')),
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
                    // 作業日（必須・常に値あり）
                    ListTile(
                      key: const Key('report_date_field'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('作業日'),
                      subtitle: Text(_dateFmt.format(_reportDate)),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: isLoading ? null : _pickDate,
                    ),
                    const SizedBox(height: 8),
                    // 天候（任意）
                    DropdownButtonFormField<String?>(
                      key: const Key('report_weather_field'),
                      initialValue: _weather,
                      decoration: const InputDecoration(
                        labelText: '天候（任意）',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('未選択'),
                        ),
                        ...WeatherCode.all.map(
                          (code) => DropdownMenuItem<String?>(
                            value: code,
                            child: Text(WeatherCode.label(code)),
                          ),
                        ),
                      ],
                      onChanged:
                          isLoading ? null : (v) => setState(() => _weather = v),
                    ),
                    const SizedBox(height: 16),
                    // 作業内容（必須）
                    TextFormField(
                      key: const Key('report_work_content_field'),
                      controller: _workContentController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.multiline,
                      minLines: 4,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: '作業内容（必須）',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '作業内容を入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // 作業人数（任意）
                    TextFormField(
                      key: const Key('report_worker_count_field'),
                      controller: _workerCountController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '作業人数（任意）',
                        suffixText: '人',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final t = (value ?? '').trim();
                        if (t.isEmpty) return null; // 任意
                        final n = int.tryParse(t);
                        if (n == null || n < 0) {
                          return '作業人数は0以上の整数で入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('report_submit_button'),
                      onPressed: isLoading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isEdit ? '更新' : '保存'),
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
