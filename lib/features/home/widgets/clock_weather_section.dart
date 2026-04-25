import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClockWeatherSection extends StatelessWidget {
  const ClockWeatherSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('HH:mm').format(now),
                  style: theme.textTheme.displayLarge,
                ),
                Text(
                  DateFormat('EEEE, MMMM d').format(now).toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 14),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'NAKAHARA KU',
                  style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 2.0, color: Colors.white60),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.cloudSun, size: 42, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('18°', style: theme.textTheme.displayLarge?.copyWith(fontSize: 58)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ForecastItem(day: 'SUN', icon: LucideIcons.cloud, temp: '19°'),
                    const SizedBox(width: 24),
                    _ForecastItem(day: 'MON', icon: LucideIcons.cloudRain, temp: '17°'),
                  ],
                ),
              ],
            ),
          ],
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
        Icon(icon, size: 24, color: Colors.white70),
        const SizedBox(height: 4),
        Text(temp, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60)),
      ],
    );
  }
}
