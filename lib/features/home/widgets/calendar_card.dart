import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'glass_card.dart';
import '../../../core/constants/style_constants.dart';
import '../providers/home_providers.dart';

class CalendarCard extends ConsumerWidget {
  const CalendarCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(calendarEventsProvider);

    return GlassCard(
      accentColor: StyleConstants.themeAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'SCHEDULE',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(letterSpacing: 2.0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          eventsAsync.when(
            data: (events) => TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: DateTime.now(),
              calendarFormat: CalendarFormat.month,
              headerVisible: false,
              daysOfWeekHeight: 20,
              rowHeight: 32,
              eventLoader: (day) {
                return events.where((event) {
                  final start = event.start?.dateTime ?? event.start?.date;
                  if (start == null) return false;
                  return isSameDay(start, day);
                }).toList();
              },
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                weekendTextStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                todayDecoration: BoxDecoration(
                  color: StyleConstants.themeAccent.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: StyleConstants.themeAccent,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: StyleConstants.themeAccent,
                  shape: BoxShape.circle,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white38, fontSize: 10),
                weekendStyle: TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ),
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => const SizedBox(
              height: 200,
              child: Center(child: Text('予定の取得に失敗しました', style: TextStyle(color: Colors.white54))),
            ),
          ),
        ],
      ),
    );
  }
}

