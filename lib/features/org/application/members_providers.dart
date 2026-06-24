import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/profile.dart';
import '../data/invite.dart';
import '../data/invite_repository.dart';
import '../data/member_repository.dart';

/// 自社メンバー一覧。ロール変更成功時に invalidate される。
final membersProvider = FutureProvider<List<Profile>>(
  (ref) => ref.watch(memberRepositoryProvider).listMembers(),
);

/// 自社の招待コード一覧（owner/admin のみ取得可）。発行/失効で invalidate。
final invitesProvider = FutureProvider<List<Invite>>(
  (ref) => ref.watch(inviteRepositoryProvider).listInvites(),
);
