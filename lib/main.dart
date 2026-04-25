import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/widgets/clock_weather_section.dart';
import 'features/home/widgets/ai_insight_card.dart';

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ClockWeatherSection(),
                  const Spacer(),
                  const AIInsightCard(
                    text: '主人、おはようございます。本日は午後から雨の予報です。\n• 14時の会議資料の準備は整っておりますか？\n• クリーニングの受け取りが本日までとなっております。',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
