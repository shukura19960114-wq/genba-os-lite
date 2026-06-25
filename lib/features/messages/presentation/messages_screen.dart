import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/async_value_widget.dart';
import '../application/post_controller.dart';
import '../application/posts_providers.dart';
import '../data/post.dart';

final _timeFmt = DateFormat('yyyy/MM/dd HH:mm');

/// S-Messages: 現場連絡（メッセージ）。時系列リスト＋下部に入力欄。
/// 画面を開いたら既読化し、現場一覧の未読バッジを消す。
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key, required this.siteId});

  final String siteId;

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 開いた時点で既読化（未読バッジを消す）。
    Future.microtask(
        () => ref.read(postControllerProvider.notifier).markRead(widget.siteId));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(postControllerProvider.notifier)
        .send(siteId: widget.siteId, body: text);
    if (ok) {
      _controller.clear();
      _scrollToBottom();
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('送信に失敗しました')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(sitePostsProvider(widget.siteId));
    final sending = ref.watch(postControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('現場の連絡')),
      body: Column(
        children: [
          Expanded(
            child: AsyncValueWidget<List<Post>>(
              value: postsAsync,
              data: (posts) {
                if (posts.isEmpty) {
                  return const Center(
                    child: Text('まだ連絡はありません',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: posts.length,
                  itemBuilder: (context, i) => _PostBubble(post: posts[i]),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('連絡の取得に失敗しました'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(sitePostsProvider(widget.siteId)),
                      child: const Text('再読み込み'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('message_input'),
                      controller: _controller,
                      enabled: !sending,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: '連絡を入力…',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('message_send_button'),
                    onPressed: sending ? null : _send,
                    icon: sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostBubble extends StatelessWidget {
  const _PostBubble({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_circle, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  post.authorLabel,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                post.createdAt != null
                    ? _timeFmt.format(post.createdAt!.toLocal())
                    : '',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(post.body),
        ],
      ),
    );
  }
}
