import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/widgets/clock_weather_section.dart';
import 'features/home/widgets/ai_insight_card.dart';
import 'features/home/widgets/profile_icon.dart';
import 'features/home/widgets/calendar_card.dart';
import 'core/services/notification_service.dart';
import 'features/home/providers/home_providers.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    ref.read(notificationServiceProvider);
    
    // Googleログインの自動試行
    Future.microtask(() async {
      final googleSignIn = GoogleSignIn();
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
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/forest_bg.jpg',
              fit: BoxFit.cover,
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
                    Colors.black.withOpacity(0.6),
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
        ],
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          SizedBox(height: 40),
          ClockWeatherSection(),
          SizedBox(height: 60),
          AIInsightCard(),
          SizedBox(height: 20),
          CalendarCard(),
          SizedBox(height: 40),
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
            children: const [
              SizedBox(height: 40),
              ClockWeatherSection(),
              Spacer(),
              AIInsightCard(),
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
