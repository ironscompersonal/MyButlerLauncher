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
import '../../../core/constants/api_constants.dart';

// --- Service Status ---

enum ServiceStatus { success, error, loading, idle }

final serviceStatusProvider = Provider<Map<String, ServiceStatus>>((ref) {
  final ai = ref.watch(aiInsightProvider);
  final weather = ref.watch(weatherProvider);
  final transit = ref.watch(transitProvider);
  final calendar = ref.watch(calendarEventsProvider);
  final user = ref.watch(googleUserProvider);

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
    'Messenger': ref.watch(notificationListProvider).isNotEmpty 
      ? ServiceStatus.success 
      : ServiceStatus.idle,
  };
});

// --- Google Sign In Providers ---

final googleSignInProvider = Provider((ref) => GoogleSignIn(
  clientId: '340547038394-2ltt55m50v217ktr11305u6hfo6hmamc.apps.googleusercontent.com',
  scopes: ApiConstants.googleScopes,
));

final googleUserProvider = StateProvider<GoogleSignInAccount?>((ref) => null);

// デバッグ用エラー文字列
final googleApiErrorProvider = StateProvider<String>((ref) => '');

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

// --- AI Insight Provider ---

final aiInsightProvider = FutureProvider<String>((ref) async {
  final apiKey = ref.watch(aiApiKeyProvider);
  final notifications = ref.watch(notificationListProvider);
  final user = ref.watch(googleUserProvider);
  
  if (apiKey.isEmpty) {
    return '主人、AIの使用にはAPIキーの設定が必要でございます。\n現在は通知の待機モードとなっております。';
  }

  String googleInfo = '';
  if (user != null) {
    try {
      final authHeaders = await user.authHeaders;
      final client = AuthenticatedClient(http.Client(), authHeaders);
      final googleService = GoogleApiService(client);
      
      final emails = await googleService.fetchRecentEmails();
      final events = await googleService.fetchTodayEvents();
      final tasks = await googleService.fetchPendingTasks();
      googleInfo = '\n--- Googleサービス情報 ---\n$emails\n$events\n$tasks\n';
      
      // エラーがあればデバッグ用に記録
      if (googleInfo.contains('エラー')) {
        Future.microtask(() => ref.read(googleApiErrorProvider.notifier).state = googleInfo);
      } else {
        Future.microtask(() => ref.read(googleApiErrorProvider.notifier).state = '');
      }
    } catch (e) {
      final errorMsg = '\nGoogle情報の取得に致命的なエラーが発生しました。詳細: $e';
      googleInfo = errorMsg;
      Future.microtask(() => ref.read(googleApiErrorProvider.notifier).state = errorMsg);
    }
  }

  if (notifications.isEmpty && googleInfo.isEmpty) {
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
  final rawData = '【通知履歴】\n$notificationData\n$googleInfo\n【公共交通機関の運行情報】\n$transitInfo';
  try {
    return await service.getSimplifiedInsight(rawData);
  } catch (e) {
    return 'ご主人様、AIとの通信中に不具合が発生しました。設定やネットワークを確認してください。';
  }
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
