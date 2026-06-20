import 'dart:async';
import 'dart:io';

import '../config/app_config.dart';

/// 接続確認の結果。
class ConnectionStatus {
  const ConnectionStatus._(this.isOk, this.errorMessage);

  /// 接続OK。
  const ConnectionStatus.ok() : this._(true, null);

  /// 接続NG（画面に出すエラー内容付き）。
  const ConnectionStatus.ng(String message) : this._(false, message);

  final bool isOk;
  final String? errorMessage;
}

/// Supabase への疎通をテーブルに依存せず確認する。
///
/// 判定には GoTrue（認証API）のヘルスチェック `/auth/v1/health` を anon key 付きで
/// GET する。認証不要・テーブル不要で 200 が返るため、まだテーブルが無い
/// Phase 1 の「土台の接続確認」に最適（仕様書 1-8）。
///
/// 注意: `dart:io` を使うため対象は iOS / Android（モバイル）。Web は Phase 1 では非対象。
Future<ConnectionStatus> checkSupabaseConnection(
  AppConfig config, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final uri = Uri.parse('${config.supabaseUrl}/auth/v1/health');
  HttpClient? client;
  try {
    client = HttpClient()..connectionTimeout = timeout;
    final request = await client.getUrl(uri);
    request.headers.set('apikey', config.supabaseAnonKey);
    final response = await request.close().timeout(timeout);
    // ボディを読み切ってコネクションを解放する（途中で停止しても固まらないよう timeout）。
    await response.drain<void>().timeout(timeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return const ConnectionStatus.ok();
    }
    return ConnectionStatus.ng(
      'HTTP ${response.statusCode} が返りました。URL と anon key を確認してください。',
    );
  } on SocketException catch (e) {
    return ConnectionStatus.ng('ネットワーク接続エラー: ${e.message}');
  } on TimeoutException {
    return const ConnectionStatus.ng(
      'タイムアウトしました。URL・ネットワーク接続を確認してください。',
    );
  } on FormatException catch (e) {
    return ConnectionStatus.ng('URL の形式が不正です: ${e.message}');
  } catch (e) {
    return ConnectionStatus.ng('予期しないエラー: $e');
  } finally {
    client?.close(force: true);
  }
}
