import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/notification_service.dart';
import '../providers/home_providers.dart';
import 'glass_card.dart';
import 'package:intl/intl.dart';

class MessengerNotificationCard extends ConsumerWidget {
  const MessengerNotificationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationListProvider);

    // 本日の通知のみにフィルタリング（簡易的に最近の10件）
    final recentNotifications = notifications.take(10).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.messageCircle, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 12),
              Text(
                'MESSAGES',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (notifications.isNotEmpty)
                Text(
                  '${notifications.length} NEW',
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentNotifications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '新着メッセージはありません',
                  style: TextStyle(color: Colors.white24, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentNotifications.length,
              separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 24),
              itemBuilder: (context, index) {
                final n = recentNotifications[index];
                final pkg = n['packageName'] as String? ?? '';
                final sender = n['sender'] as String? ?? n['title'] as String? ?? '不明';
                final text = n['text'] as String? ?? '';
                final timestamp = n['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
                final timeStr = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(timestamp));

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppIcon(pkg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sender,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                timeStr,
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAppIcon(String packageName) {
    IconData iconData = LucideIcons.appWindow;
    Color iconColor = Colors.white24;

    if (packageName.contains('line')) {
      iconData = LucideIcons.messageSquare;
      iconColor = const Color(0xFF06C755);
    } else if (packageName.contains('whatsapp')) {
      iconData = LucideIcons.phone;
      iconColor = const Color(0xFF25D366);
    } else if (packageName.contains('slack')) {
      iconData = LucideIcons.slack;
      iconColor = const Color(0xFF4A154B);
    } else if (packageName.contains('teams')) {
      iconData = LucideIcons.users;
      iconColor = const Color(0xFF6264A7);
    } else if (packageName.contains('discord')) {
      iconData = LucideIcons.gamepad2;
      iconColor = const Color(0xFF5865F2);
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 18),
    );
  }
}
