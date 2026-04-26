import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ai_insight_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/services/google_api_service.dart';
import '../../../core/services/app_launcher_service.dart';
import '../../../core/services/smart_home_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import '../../../core/constants/api_constants.dart';

// --- Google Sign In Providers ---

final googleSignInProvider = Provider((ref) => GoogleSignIn(
  scopes: ApiConstants.googleScopes,
));

final googleUserProvider = StateProvider<GoogleSignInAccount?>((ref) => null);

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
    } catch (e) {
      googleInfo = '\nGoogle情報の取得に失敗しました。';
    }
  }

  if (notifications.isEmpty && googleInfo.isEmpty) {
    return '主人、現在報告すべき新しい情報はございません。\n穏やかな時間をお過ごしください。';
  }

  final service = AIInsightService(apiKey);
  final notificationData = notifications.map((n) => 
    "アプリ: ${n['packageName']}, タイトル: ${n['title']}, 本文: ${n['text']}"
  ).join('\n---\n');

  final rawData = '【通知履歴】\n$notificationData\n$googleInfo';
  try {
    return await service.getSimplifiedInsight(rawData);
  } catch (e) {
    return '主人、AIとの通信中に不具合が発生いたしました。設定やネットワークをご確認ください。';
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
