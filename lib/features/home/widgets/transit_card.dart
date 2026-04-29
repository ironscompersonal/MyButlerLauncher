import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/home_providers.dart';
import 'glass_card.dart';

class TransitCard extends ConsumerWidget {
  const TransitCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transitAsync = ref.watch(transitProvider);

    return transitAsync.when(
      data: (info) {
        final isDelayed = info.contains('異常あり');
        final statusColor = isDelayed ? const Color(0xFFFF3366) : const Color(0xFF00FF88);
        
        // 情報をパースして表示用に整理
        final lines = info.split('\n');
        final title = lines.first;
        final details = lines.skip(1).toList();

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isDelayed ? LucideIcons.alertTriangle : LucideIcons.train,
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'TRANSIT INFO',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      isDelayed ? 'DELAYED' : 'NORMAL',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isDelayed) ...[
                ...details.take(3).map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.white54)),
                      Expanded(
                        child: Text(
                          detail,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                if (details.length > 3)
                  Text(
                    '他 ${details.length - 3} 件の遅延情報あり',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ] else
                const Text(
                  '全ての路線で平常通り運行されています。',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const GlassCard(
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
          ),
        ),
      ),
      error: (err, _) => GlassCard(
        child: Row(
          children: const [
            Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 20),
            SizedBox(width: 12),
            Text('運行情報の取得に失敗しました', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
