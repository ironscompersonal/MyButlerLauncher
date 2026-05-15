import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
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
import 'dart:typed_data';
import '../../../core/services/health_service.dart';
import '../../../core/services/mcp_service.dart';
import '../../../core/services/environment_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// --- Butler Card States ---

enum ButlerCardMode { insight, listening, thinking, chat }

class ButlerCardState {
  final ButlerCardMode mode;
  final String content;
  final String? lastRecognition;

  ButlerCardState({
    required this.mode,
    required this.content,
    this.lastRecognition,
  });

  ButlerCardState copyWith({
    ButlerCardMode? mode,
    String? content,
    String? lastRecognition,
  }) {
    return ButlerCardState(
      mode: mode ?? this.mode,
      content: content ?? this.content,
      lastRecognition: lastRecognition ?? this.lastRecognition,
    );
  }
}

class ButlerCardNotifier extends StateNotifier<ButlerCardState> {
  final Ref ref;
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;

  ButlerCardNotifier(this.ref) : super(ButlerCardState(mode: ButlerCardMode.insight, content: ''));

  Future<void> initialize() async {
    // インサイトが更新されたらカードも更新するリスナー
    ref.listen(aiInsightProvider, (previous, next) {
      next.whenData((text) {
        if (state.mode == ButlerCardMode.insight) {
          state = state.copyWith(content: text);
        }
      });
    });
    
    // 初期値設定
    final initialInsight = ref.read(aiInsightProvider).maybeWhen(data: (d) => d, orElse: () => 'ご主人様、状況を整理しております。');
    state = state.copyWith(content: initialInsight);
  }

  Future<void> startListening() async {
    if (await _recorder.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/butler_voice.m4a';
      
      const config = RecordConfig();
      await _recorder.start(config, path: _recordingPath!);
      
      state = state.copyWith(
        mode: ButlerCardMode.listening, 
        lastRecognition: 'ご指示を承ります（録音中...）',
      );
    } else {
      state = state.copyWith(content: 'マイクの権限がありません。設定をご確認ください。');
    }
  }

  Future<void> stopListening() async {
    final path = await _recorder.stop();
    if (path != null) {
      _processVoice(path);
    } else {
      state = state.copyWith(mode: ButlerCardMode.insight);
    }
  }

  Future<void> _processVoice(String path) async {
    state = state.copyWith(
      mode: ButlerCardMode.thinking, 
      content: 'お声を解析しております。少々お待ちください。'
    );

    final apiKey = ref.read(aiApiKeyProvider);
    if (apiKey.isEmpty) {
      state = state.copyWith(mode: ButlerCardMode.insight, content: 'APIキーが未設定です。');
      return;
    }

    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    
    try {
      final audioFile = File(path);
      final audioBytes = await audioFile.readAsBytes();
      
      // AIに音声を直接渡し、テキスト化と意図解釈を同時に行わせる
      final response = await model.generateContent([
        Content.multi([
          TextPart('以下の音声を解析し、ご主人様が話した内容を日本語でテキスト化してください。'
                   'その後、その依頼に対する執事としての最適な回答を生成してください。'
                   '出力は執事としての回答のみで結構です。'),
          DataPart('audio/m4a', audioBytes),
        ])
      ]);

      final answer = response.text ?? '聞き取ることができませんでした。';
      state = state.copyWith(mode: ButlerCardMode.chat, content: answer);
    } catch (e) {
      print('Audio Analysis Error: $e');
      state = state.copyWith(mode: ButlerCardMode.insight, content: '聴解中に支障が生じました: $e');
    }
  }

  void resetToInsight() {
    final insight = ref.read(aiInsightProvider).maybeWhen(data: (d) => d, orElse: () => '');
    state = state.copyWith(mode: ButlerCardMode.insight, content: insight);
  }
}

final butlerCardProvider = StateNotifierProvider<ButlerCardNotifier, ButlerCardState>((ref) {
  return ButlerCardNotifier(ref);
});

// --- Existing Providers ---

// --- Time Provider ---

final currentTimeProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

// --- Service Status ---

enum ServiceStatus { success, error, loading, idle, warning }

final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  return await ref.read(notificationServiceProvider).checkPermission();
});

final healthServiceProvider = Provider((ref) => HealthService());

final healthStatusProvider = FutureProvider<ServiceStatus>((ref) async {
  final service = ref.read(healthServiceProvider);
  final installed = await service.isHealthConnectInstalled();
  if (!installed) return ServiceStatus.warning; // 未インストール
  return ServiceStatus.success;
});

final serviceStatusProvider = Provider<Map<String, ServiceStatus>>((ref) {
  final ai = ref.watch(aiInsightProvider);
  final weather = ref.watch(weatherProvider);
  final transit = ref.watch(transitProvider);
  final calendar = ref.watch(calendarEventsProvider);
  final user = ref.watch(googleUserProvider);
  final health = ref.watch(healthStatusProvider).maybeWhen(
    data: (s) => s,
    orElse: () => ServiceStatus.loading,
  );
  
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
    'Health': health,
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
  if (!Platform.isAndroid) {
    // デスクトップ版での検証用モック
    return '\n--- Googleサービス情報 ---\n【メール】未読はありません。\n【予定】14:00 役員会議, 18:00 会食\n【タスク】資料作成、クリーニング回収\n';
  }
  
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
      googleService.fetchUpcomingEvents(),
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

// --- Health Data Provider ---

final healthDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(healthServiceProvider);
  final installed = await service.isHealthConnectInstalled();
  if (!installed) return {};
  return await service.fetchHealthSummary();
});

final weeklyHealthDataProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(healthServiceProvider);
  final installed = await service.isHealthConnectInstalled();
  if (!installed) return [];
  return await service.fetchWeeklyHealthData();
});

// --- Environment Provider (Task A/B) ---

final environmentProvider = FutureProvider<EnvironmentData>((ref) async {
  final service = ref.read(environmentServiceProvider);
  final weather = await ref.watch(weatherProvider.future);
  return await service.fetchCurrentEnvironment(weather);
});

// --- MCP Data Providers ---

// --- AI Insight Service Provider ---

final aiInsightServiceProvider = Provider<AIInsightService?>((ref) {
  final apiKey = ref.watch(aiApiKeyProvider);
  if (apiKey.isEmpty) return null;
  return AIInsightService(apiKey);
});

// --- AI Insight Provider ---

final aiInsightProvider = FutureProvider<String>((ref) async {
  final apiKey = ref.watch(aiApiKeyProvider);
  final notifications = ref.watch(notificationListProvider);
  final googleInfoAsync = ref.watch(googleDataSummaryProvider);
  final healthDataAsync = ref.watch(healthDataProvider);
  final now = DateTime.now();
  final timeStr = DateFormat('yyyy年MM月dd日(E) HH時mm分', 'ja_JP').format(now);
  
  if (apiKey.isEmpty) {
    return '主人、AIの使用にはAPIキーの設定が必要でございます。\n現在は通知の待機モードとなっております。';
  }

  final googleInfo = googleInfoAsync.maybeWhen(
    data: (d) => d,
    orElse: () => '',
  );

  final healthData = healthDataAsync.maybeWhen(
    data: (d) => d.isEmpty ? '' : '\n【健康データ(直近24h)】\n歩数: ${d['steps']}歩, 睡眠: ${d['sleep_minutes']}分, 平均心拍: ${d['avg_heart_rate']}bpm',
    orElse: () => '',
  );

  final personalProfile = ref.watch(personalProfileProvider);

  if (notifications.isEmpty && googleInfo.isEmpty && personalProfile.isEmpty && healthData.isEmpty) {
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

  final service = ref.watch(aiInsightServiceProvider);
  if (service == null) return 'APIキーが未設定です。';

  final envDataAsync = ref.watch(environmentProvider);
  final envInfo = envDataAsync.maybeWhen(
    data: (d) => '\n【現在の環境】\n${d.description}',
    orElse: () => '',
  );

  try {
    final rawData = '【現在日時】\n$timeStr\n\n【ご主人様に関する情報】\n$personalProfile\n\n【通知履歴】\n$notificationData\n$googleInfo\n【公共交通機関の運行情報】\n$transitInfo\n$healthData$envInfo';
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

  // 直近のコンテキストを構築（資産情報は除外）
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

final appIconProvider = FutureProvider.family<Uint8List?, String>((ref, packageName) async {
  return ref.read(appLauncherServiceProvider).getAppIcon(packageName);
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
