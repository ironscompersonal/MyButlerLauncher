import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/widgets/clock_weather_section.dart';
import 'features/home/widgets/ai_insight_card.dart';
import 'features/home/widgets/profile_icon.dart';
import 'features/home/widgets/calendar_card.dart';
import 'features/home/widgets/chat_overlay.dart';
import 'features/home/widgets/app_drawer.dart';
import 'core/services/notification_service.dart';
import 'features/home/providers/home_providers.dart';

void main() {
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
  @override
  void initState() {
    super.initState();
    // 通知サービスの初期化
    ref.read(notificationServiceProvider);
    
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
          const CalendarCard(),
          const SizedBox(height: 100), // 余白
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
            ],
          ),
        ),
        const SizedBox(width: 40),
        const Expanded(
          flex: 3,
          child: CalendarCard(),
        ),
      ],
    );
  }
}
