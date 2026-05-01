import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/home_providers.dart';
import '../../../core/services/weather_service.dart';

class ClockWeatherSection extends ConsumerWidget {
  const ClockWeatherSection({super.key});

  IconData _getWeatherIcon(int code) {
    if (code == 0) return LucideIcons.sun;
    if (code <= 3) return LucideIcons.cloudSun;
    if (code <= 48) return LucideIcons.cloudFog;
    if (code <= 67) return LucideIcons.cloudRain;
    if (code <= 77) return LucideIcons.cloudSnow;
    if (code <= 82) return LucideIcons.cloudRain;
    if (code <= 99) return LucideIcons.cloudLightning;
    return LucideIcons.helpCircle;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final size = MediaQuery.of(context).size;
    final isPortrait = size.width < 600;
    final weatherAsync = ref.watch(weatherProvider);

    return Column(
      crossAxisAlignment: isPortrait ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Clock Section
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            crossAxisAlignment: isPortrait ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('HH:mm').format(now),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: isPortrait ? 104 : 64, // 80%にサイズダウン
                  fontWeight: FontWeight.w200,
                  letterSpacing: -2,
                ),
              ),
              Text(
                DateFormat('EEEE, MMMM d').format(now).toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 14,
                  letterSpacing: 4,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Weather Section
        weatherAsync.when(
          data: (weather) => Column(
            crossAxisAlignment: isPortrait ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: isPortrait ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Icon(_getWeatherIcon(weather.weatherCode), size: 48, color: Colors.white),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.round()}°',
                        style: theme.textTheme.displayLarge?.copyWith(fontSize: 48, fontWeight: FontWeight.w300),
                      ),
                      Text(
                        weather.location,
                        style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 2.0, color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Forecast Row (Actual data)
              Row(
                mainAxisAlignment: isPortrait ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: weather.dailyForecast.map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 32.0),
                    child: _ForecastItem(
                      day: DateFormat('E').format(f.date).toUpperCase(),
                      icon: _getWeatherIcon(f.weatherCode),
                      temp: '${f.maxTemp.round()}°/${f.minTemp.round()}°',
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Text('天気取得エラー', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}

class _ForecastItem extends StatelessWidget {
  final String day;
  final IconData icon;
  final String temp;

  const _ForecastItem({required this.day, required this.icon, required this.temp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(day, style: theme.textTheme.titleMedium?.copyWith(fontSize: 10, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Icon(icon, size: 28, color: Colors.white70),
        const SizedBox(height: 4),
        Text(temp, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60)),
      ],
    );
  }
}
