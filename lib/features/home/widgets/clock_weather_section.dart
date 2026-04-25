import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClockWeatherSection extends StatelessWidget {
  const ClockWeatherSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final size = MediaQuery.of(context).size;
    final isPortrait = size.width < 600;

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
                  fontSize: isPortrait ? 130 : 80, // 約150%相当の巨大化
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
        Row(
          mainAxisAlignment: isPortrait ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            const Icon(LucideIcons.cloudSun, size: 48, color: Colors.white),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '18°',
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 48, fontWeight: FontWeight.w300),
                ),
                Text(
                  'NAKAHARA KU',
                  style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 2.0, color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
            if (!isPortrait) ...[
              const SizedBox(width: 40),
              _ForecastItem(day: 'SUN', icon: LucideIcons.cloud, temp: '19°'),
              const SizedBox(width: 24),
              _ForecastItem(day: 'MON', icon: LucideIcons.cloudRain, temp: '17°'),
            ]
          ],
        ),
        if (isPortrait) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ForecastItem(day: 'SUN', icon: LucideIcons.cloud, temp: '19°'),
              const SizedBox(width: 40),
              _ForecastItem(day: 'MON', icon: LucideIcons.cloudRain, temp: '17°'),
              const SizedBox(width: 40),
              _ForecastItem(day: 'TUE', icon: LucideIcons.sun, temp: '22°'),
            ],
          ),
        ],
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
