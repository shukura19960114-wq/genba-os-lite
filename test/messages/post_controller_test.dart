import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genba_os_lite/features/messages/application/post_controller.dart';
import 'package:genba_os_lite/features/messages/data/post.dart';
import 'package:genba_os_lite/features/messages/data/post_repository.dart';

class FakePostRepository implements PostRepository {
  FakePostRepository({this.failOnCreate = false});

  final bool failOnCreate;
  final List<(String, String)> created = [];
  final List<String> readMarks = [];

  @override
  Future<List<Post>> listBySite(String siteId) async => const [];

  @override
  Future<void> create({required String siteId, required String body}) async {
    if (failOnCreate) throw Exception('insert failed');
    created.add((siteId, body));
  }

  @override
  Future<void> markRead(String siteId) async => readMarks.add(siteId);

  @override
  Future<Map<String, int>> unreadCounts() async => const {};
}

ProviderContainer _container(FakePostRepository repo) {
  final container = ProviderContainer(overrides: [
    postRepositoryProvider.overrideWithValue(repo),
  ]);
  container.listen(postControllerProvider, (_, _) {}, fireImmediately: true);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('PostController.send', () {
    test('成功 → true・本文を投稿（trim）', () async {
      final repo = FakePostRepository();
      final container = _container(repo);

      final ok = await container
          .read(postControllerProvider.notifier)
          .send(siteId: 's1', body: '  集合8時  ');

      expect(ok, isTrue);
      expect(repo.created, [('s1', '集合8時')]);
      expect(container.read(postControllerProvider).hasError, isFalse);
    });

    test('空文字 → false・投稿しない', () async {
      final repo = FakePostRepository();
      final container = _container(repo);

      final ok = await container
          .read(postControllerProvider.notifier)
          .send(siteId: 's1', body: '   ');

      expect(ok, isFalse);
      expect(repo.created, isEmpty);
    });

    test('失敗 → false・state はエラー', () async {
      final repo = FakePostRepository(failOnCreate: true);
      final container = _container(repo);

      final ok = await container
          .read(postControllerProvider.notifier)
          .send(siteId: 's1', body: 'テスト');

      expect(ok, isFalse);
      expect(container.read(postControllerProvider).hasError, isTrue);
    });
  });

  group('PostController.markRead', () {
    test('リポジトリの markRead を呼ぶ', () async {
      final repo = FakePostRepository();
      final container = _container(repo);

      await container.read(postControllerProvider.notifier).markRead('s9');

      expect(repo.readMarks, ['s9']);
    });
  });

  group('Post.fromJson', () {
    test('author_email を読む・authorLabel に反映', () {
      final p = Post.fromJson({
        'id': 'p1',
        'site_id': 's1',
        'author_id': 'u1',
        'body': 'やあ',
        'created_at': '2026-06-25T09:00:00Z',
        'author_email': 'a@b.com',
      });
      expect(p.body, 'やあ');
      expect(p.authorEmail, 'a@b.com');
      expect(p.authorLabel, 'a@b.com');
    });

    test('author_email 無し → authorLabel は (不明)', () {
      final p = Post.fromJson({
        'id': 'p1',
        'site_id': 's1',
        'body': 'やあ',
      });
      expect(p.authorLabel, '(不明)');
    });
  });
}
