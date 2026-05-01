import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ai_insight_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/services/google_api_service.dart';
import '../../../core/services/app_launcher_service.dart';
import '../../../core/services/email_analyzer_service.dart';
import '../../../core/services/transit_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import '../../../core/services/chat_service.dart';
import '../../../core/constants/api_constants.dart';
import 'package:intl/intl.dart';

// --- Service Status ---

enum ServiceStatus { success, error, loading, idle }

final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  return await ref.read(notificationServiceProvider).checkPermission();
});

final serviceStatusProvider = Provider<Map<String, ServiceStatus>>((ref) {
  final ai = ref.watch(aiInsightProvider);
  final weather = ref.watch(weatherProvider);
  final transit = ref.watch(transitProvider);
  final calendar = ref.watch(calendarEventsProvider);
  final user = ref.watch(googleUserProvider);
  final hasNotificationPermission = ref.watch(notificationPermissionProvider).maybeWhen(
    data: (d) => d,
    orElse: () => true, // デフォルトはtrueとしておく（エラー時は別途）
  );
  final notifications = ref.watch(notificationListProvider);

  return {
    'Gemini AI': ai.when(
      data: (d) => d.contains('エラー') || d.contains('不具合') ? ServiceStatus.error : ServiceStatus.success,
      error: (_, __) => ServiceStatus.error,
      loading: () => ServiceStatus.loading,
    ),
    'Weather': weather.when(
      data: (_) => ServiceStatus.success,
      error: (_, __) => ServiceStatus.error,
      loading: () => ServiceStatus.loading,
    ),
    'Transit': transit.when(
      data: (_) => ServiceStatus.success,
      error: (_, __) => ServiceStatus.error,
      loading: () => ServiceStatus.loading,
    ),
    'Google': user == null 
      ? ServiceStatus.idle 
      : calendar.when(
          data: (_) => ServiceStatus.success,
          error: (_, __) => ServiceStatus.error,
          loading: () => ServiceStatus.loading,
        ),
    'Messenger': !hasNotificationPermission 
      ? ServiceStatus.error 
      : (notifications.isNotEmpty ? ServiceStatus.success : ServiceStatus.idle),
  };
});

// --- Google Sign In Providers ---

final googleSignInProvider = Provider((ref) => GoogleSignIn(
  clientId: '340547038394-2ltt55m50v217ktr11305u6hfo6hmamc.apps.googleusercontent.com',
  scopes: ApiConstants.googleScopes,
));

final googleUserProvider = StateProvider<GoogleSignInAccount?>((ref) => null);


// --- Personal Profile Provider ---

class PersonalProfileNotifier extends StateNotifier<String> {
  PersonalProfileNotifier() : super('') {
    _load();
  }
  static const _key = 'master_personal_profile';
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? '';
  }
  Future<void> updateProfile(String profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, profile);
    state = profile;
  }
}

final personalProfileProvider = StateNotifierProvider<PersonalProfileNotifier, String>((ref) {
  return PersonalProfileNotifier();
});

// --- API Key Provider ---

class ApiKeyNotifier extends StateNotifier<String> {
  ApiKeyNotifier() : super('') {
    _loadKey();
  }
  static const _key = 'gemini_api_key';
  Future<void> _loadKey() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? '';
  }
  Future<void> setKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, key);
    state = key;
  }
}

final aiApiKeyProvider = StateNotifierProvider<ApiKeyNotifier, String>((ref) {
  return ApiKeyNotifier();
});

// --- Google Data Summary Provider ---

final googleDataSummaryProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(googleUserProvider);
  if (user == null) return '';

  final httpClient = http.Client();
  try {
    final authHeaders = await user.authHeaders;
    final client = AuthenticatedClient(httpClient, authHeaders);
    final googleService = GoogleApiService(client);
    
    // 並列で取得して高速化
    final results = await Future.wait([
      googleService.fetchRecentEmails(),
      googleService.fetchTodayEvents(),
      googleService.fetchPendingTasks(),
    ]);
    
    return '\n--- Googleサービス情報 ---\n${results[0]}\n${results[1]}\n${results[2]}\n';
  } catch (e) {
    return '\nGoogle情報の取得に致命的なエラーが発生しました。詳細: $e';
  } finally {
    httpClient.close();
  }
});

// エラーログ表示用のプロバイダ（副作用を避け、監視ベースに変更）
final googleApiErrorProvider = Provider<String>((ref) {
  final summaryAsync = ref.watch(googleDataSummaryProvider);
  return summaryAsync.maybeWhen(
    data: (d) => d.contains('エラー') ? d : '',
    error: (e, _) => '重大なエラー: $e',
    orElse: () => '',
  );
});

// --- AI Insight Provider ---

final aiInsightProvider = FutureProvider<String>((ref) async {
  final apiKey = ref.watch(aiApiKeyProvider);
  final notifications = ref.watch(notificationListProvider);
  final googleInfoAsync = ref.watch(googleDataSummaryProvider);
  
  if (apiKey.isEmpty) {
    return '主人、AIの使用にはAPIキーの設定が必要でございます。\n現在は通知の待機モードとなっております。';
  }

  final googleInfo = googleInfoAsync.maybeWhen(
    data: (d) => d,
    orElse: () => '',
  );

  final personalProfile = ref.watch(personalProfileProvider);

  if (notifications.isEmpty && googleInfo.isEmpty && personalProfile.isEmpty) {
    return 'ご主人様、現在報告すべき新しい情報はありません。\n穏やかな時間をお過ごしください。';
  }

  final notificationData = notifications.map((n) {
    final pkg = n['packageName'] ?? '';
    final sender = n['sender'] ?? '';
    final group = n['conversationTitle'] ?? '';
    final title = n['title'] ?? '';
    final text = n['text'] ?? '';
    
    // アプリ名の簡易判定
    String appName = pkg.toString().split('.').last;
    if (pkg.contains('line')) appName = 'LINE';
    if (pkg.contains('whatsapp')) appName = 'WhatsApp';

    String info = "アプリ: $appName, ";
    if (group.isNotEmpty) {
      info += "グループ: $group, 送信者: $sender, ";
    } else if (sender.isNotEmpty && sender != title) {
      info += "送信者: $sender, ";
    } else {
      info += "タイトル: $title, ";
    }
    info += "本文: $text";
    return info;
  }).join('\n---\n');

  final transitAsyncValue = ref.watch(transitProvider);
  final transitInfo = transitAsyncValue.when(
    data: (d) => d,
    error: (e, _) => '運行情報の取得に失敗しました。',
    loading: () => '取得中...',
  );

  final service = AIInsightService(apiKey);
  final now = DateTime.now();
  final timeStr = DateFormat('yyyy年MM月dd日(E) HH時mm分', 'ja_JP').format(now);
  
  final rawData = '【現在日時】\n$timeStr\n\n【ご主人様に関する情報】\n$personalProfile\n\n【通知履歴】\n$notificationData\n$googleInfo\n【公共交通機関の運行情報】\n$transitInfo';
  try {
    return await service.getSimplifiedInsight(rawData);
  } catch (e) {
    return 'ご主人様、AIとの通信中に不具合が発生しました。設定やネットワークを確認してください。';
  }
});

// --- Chat Service Provider ---

final chatServiceProvider = Provider<ChatService?>((ref) {
  final apiKey = ref.watch(aiApiKeyProvider);
  if (apiKey.isEmpty) return null;

  final googleInfo = ref.watch(googleDataSummaryProvider).maybeWhen(
    data: (d) => d,
    orElse: () => 'Googleデータ未取得',
  );
  final notifications = ref.watch(notificationListProvider);
  final personalProfile = ref.watch(personalProfileProvider);
  
  final now = DateTime.now();
  final timeStr = DateFormat('yyyy年MM月dd日(E) HH時mm分', 'ja_JP').format(now);

  // 直近のコンテキストを構築
  String context = '【現在日時】\n$timeStr\n\n【ご主人様に関する情報】\n$personalProfile\n\n【現在のコンテキスト】\n$googleInfo\n';
  if (notifications.isNotEmpty) {
    context += '\n【通知履歴】\n';
    context += notifications.take(5).map((n) => '送信者: ${n['sender']}, 内容: ${n['text']}').join('\n');
  }

  return ChatService(apiKey, [], context);
});


// --- Helper Classes ---

class AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _headers;
  AuthenticatedClient(this._inner, this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

// --- Other Providers ---

final weatherProvider = FutureProvider<WeatherData>((ref) async {
  final service = WeatherService();
  return await service.fetchWeather(35.5804, 139.6593);
});

final calendarEventsProvider = FutureProvider<List<calendar.Event>>((ref) async {
  final user = ref.watch(googleUserProvider);
  if (user == null) return [];
  try {
    final authHeaders = await user.authHeaders;
    final client = AuthenticatedClient(http.Client(), authHeaders);
    final googleService = GoogleApiService(client);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return await googleService.fetchCalendarEvents(startOfMonth, endOfMonth);
  } catch (e) {
    return [];
  }
});

final appLauncherServiceProvider = Provider((ref) => AppLauncherService());
final installedAppsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(appLauncherServiceProvider).getInstalledApps();
});

final appUsageProvider = StateNotifierProvider<AppUsageNotifier, Map<String, int>>((ref) {
  return AppUsageNotifier();
});

class AppUsageNotifier extends StateNotifier<Map<String, int>> {
  AppUsageNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('app_usage_stats');
    if (data != null) {
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        state = decoded.map((k, v) => MapEntry(k, v as int));
      } catch (_) {}
    }
  }

  Future<void> recordLaunch(String packageName) async {
    final current = state[packageName] ?? 0;
    final newState = {...state, packageName: current + 1};
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_usage_stats', jsonEncode(newState));
  }
}

final emailAnalyzerServiceProvider = FutureProvider<EmailAnalyzerService?>((ref) async {
  final apiKey = ref.watch(aiApiKeyProvider);
  if (apiKey.isEmpty) return null;
  
  final user = ref.watch(googleUserProvider);
  if (user == null) return null;
  
  try {
    final authHeaders = await user.authHeaders;
    final client = AuthenticatedClient(http.Client(), authHeaders);
    final googleService = GoogleApiService(client);
    return EmailAnalyzerService(googleService, apiKey);
  } catch (e) {
    return null;
  }
});

final transitProvider = FutureProvider<String>((ref) async {
  final service = TransitService();
  return await service.fetchTransitInfo();
});
