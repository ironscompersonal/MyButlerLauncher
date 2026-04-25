import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ai_insight_service.dart';
import '../../../core/services/notification_service.dart';

// 将来的にユーザー設定から取得するようにする予備の場所
final aiApiKeyProvider = StateProvider<String>((ref) => '');

final aiInsightProvider = FutureProvider<String>((ref) async {
  final apiKey = ref.watch(aiApiKeyProvider);
  final notifications = ref.watch(notificationListProvider);
  
  if (apiKey.isEmpty) {
    return '主人、AIの使用にはAPIキーの設定が必要でございます。\n現在は通知の待機モードとなっております。\n• 合計 ${notifications.length} 件の通知を受信済みです。';
  }

  if (notifications.isEmpty) {
    return '主人、現在報告すべき新しい通知はございません。\n穏やかな時間をお過ごしください。';
  }

  final service = AIInsightService(apiKey);
  
  // 通知データをテキスト化してAIに渡す
  final rawData = notifications.map((n) => 
    "アプリ: ${n['packageName']}, タイトル: ${n['title']}, 本文: ${n['text']}"
  ).join('\n---\n');

  return await service.getSimplifiedInsight(rawData);
});
