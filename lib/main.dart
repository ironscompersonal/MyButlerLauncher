import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/widgets/clock_weather_section.dart';
import 'features/home/widgets/ai_insight_card.dart';
import 'features/home/widgets/profile_icon.dart';
import 'features/home/widgets/calendar_card.dart';
import 'features/home/widgets/chat_overlay.dart';
import 'features/home/widgets/app_drawer.dart';
import 'features/home/widgets/service_status_dashboard.dart';
import 'features/home/widgets/transit_card.dart';
import 'features/home/widgets/messenger_notification_card.dart';
import 'core/services/notification_service.dart';
import 'features/home/providers/home_providers.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);
  runApp(const ProviderScope(child: MyButlerLauncher()));
}

class MyButlerLauncher extends StatelessWidget {
  const MyButlerLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MY AI BUTLER',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _emailCheckTimer;

  @override
  void initState() {
    super.initState();
    // 通知サービスの初期化
    ref.read(notificationServiceProvider);
    
    // 定期的なメール確認タイマー（15分ごとに条件チェック）
    _emailCheckTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _checkEmailsAndRegisterEvents();
    });
    
    // Googleログインの自動試行
    Future.microtask(() async {
      final googleSignIn = ref.read(googleSignInProvider);
      try {
        final account = await googleSignIn.signInSilently();
        if (account != null) {
          ref.read(googleUserProvider.notifier).state = account;
        }
      } catch (e) {
        debugPrint('Silent sign-in failed: $e');
      }

      final hasPermission = await ref.read(notificationServiceProvider).checkPermission();
      if (!hasPermission && mounted) {
        _showPermissionDialog();
      }
    });
  }

  @override
  void dispose() {
    _emailCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailsAndRegisterEvents() async {
    final now = DateTime.now();
    // 6時から23時までの間のみ動作
    if (now.hour < 6 || now.hour >= 23) return;

    final prefs = await SharedPreferences.getInstance();
    final lastCheckMillis = prefs.getInt('last_email_check_time') ?? 0;
    final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheckMillis);

    // 前回のチェックから3時間経過していなければスキップ
    if (now.difference(lastCheckTime).inHours < 3) return;

    final emailAnalyzer = await ref.read(emailAnalyzerServiceProvider.future);
    if (emailAnalyzer == null) return;

    // 初回は3時間前から、それ以降は前回のチェック日時から取得
    final since = lastCheckMillis == 0 ? now.subtract(const Duration(hours: 3)) : lastCheckTime;
    final emailResult = await emailAnalyzer.analyzeAndRegisterEvents(since);
    int eventsCount = emailResult['events'] ?? 0;
    int tasksCount = emailResult['tasks'] ?? 0;

    // メッセンジャー通知の取得と解析
    final notifications = ref.read(notificationListProvider);
    final targetPackages = [
      'jp.naver.line.android',
      'com.whatsapp',
      'jp.ecstudio.chatworkandroid',
      'com.microsoft.teams',
      'com.slack',
      'com.instagram.android',
      'com.facebook.orca',
      'org.telegram.messenger'
    ];
    
    // 前回チェック以降の対象通知をフィルタリング
    final targetNotifications = notifications.where((n) {
      final timestamp = n['timestamp'] as int? ?? 0;
      final packageName = n['packageName'] as String? ?? '';
      return timestamp > lastCheckMillis && targetPackages.contains(packageName);
    }).toList();

    if (targetNotifications.isNotEmpty) {
      final messengerResult = await emailAnalyzer.analyzeNotificationsAndRegisterEvents(targetNotifications);
      eventsCount += (messengerResult['events'] ?? 0);
      tasksCount += (messengerResult['tasks'] ?? 0);
    }

    // チェック時刻を更新
    await prefs.setInt('last_email_check_time', now.millisecondsSinceEpoch);

    // 新規登録があった場合はUIで通知
    if ((eventsCount > 0 || tasksCount > 0) && mounted) {
      _showButlerReportDialog(eventsCount, tasksCount);
      // プロバイダを更新
      ref.invalidate(calendarEventsProvider);
    }
  }

  void _showButlerReportDialog(int eventsCount, int tasksCount) {
    String message = 'ご主人様、メールとメッセージを確認しました。';
    if (eventsCount > 0 && tasksCount > 0) {
      message += '\nカレンダーに登録すべき予定が $eventsCount 件、ToDo（タスク）が $tasksCount 件あったので、私の方で登録を済ませておきました。';
    } else if (eventsCount > 0) {
      message += '\nカレンダーに登録すべき予定が $eventsCount 件あったので、私の方で登録を済ませておきました。';
    } else if (tasksCount > 0) {
      message += '\n新たに追加すべきToDo（タスク）が $tasksCount 件あったので、私の方で登録を済ませておきました。';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('執事からのご報告', style: TextStyle(color: Colors.white)),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ご苦労', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _showAppDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AppDrawer(),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('執事の権限', style: TextStyle(color: Colors.white)),
        content: const Text(
          '主人の状況を把握するためには、通知へのアクセス権限が必要です。設定画面で「MY AI BUTLER」を許可してください。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('承知しました'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.width < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/images/forest_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
              ),
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: isPortrait ? _buildPortraitLayout() : _buildLandscapeLayout(),
            ),
          ),
          // Profile Icon (Top Right)
          const Positioned(
            top: 40,
            right: 16,
            child: ProfileIconWidget(),
          ),
          // App Drawer Toggle (Bottom Center)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _showAppDrawer,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'APPLICATIONS',
                        style: TextStyle(
                          color: Colors.white,
                          letterSpacing: 2,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const ClockWeatherSection(),
          const SizedBox(height: 60),
          AIInsightCard(
            onAction: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ChatOverlay(),
              );
            },
          ),
          const SizedBox(height: 20),
          const TransitCard(),
          const SizedBox(height: 20),
          const CalendarCard(),
          const SizedBox(height: 20),
          const MessengerNotificationCard(),
          const SizedBox(height: 20),
          const ServiceStatusDashboard(),
          const SizedBox(height: 120), // 余白
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const ClockWeatherSection(),
              const Spacer(),
              AIInsightCard(
                onAction: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const ChatOverlay(),
                  );
                },
              ),
              const SizedBox(height: 20),
              const TransitCard(),
            ],
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: const [
                CalendarCard(),
                SizedBox(height: 20),
                MessengerNotificationCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
