import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  static const _channel = MethodChannel('com.mybutler.launcher_app/notifications');
  final Ref _ref;

  NotificationService(this._ref) {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationReceived':
        final Map<dynamic, dynamic> data = call.arguments;
        // 通知をプロバイダー経由で記録する
        _ref.read(notificationListProvider.notifier).addNotification(data);
        break;
    }
  }

  Future<bool> checkPermission() async {
    try {
      final bool result = await _channel.invokeMethod('checkNotificationPermission');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check permission: '${e.message}'.");
      return false;
    }
  }

  Future<String> getAppSignature() async {
    try {
      final String result = await _channel.invokeMethod('getAppSignature');
      return result;
    } catch (e) {
      return "Error: $e";
    }
  }
}

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

final notificationListProvider = StateNotifierProvider<NotificationListNotifier, List<Map<dynamic, dynamic>>>((ref) {
  return NotificationListNotifier();
});

class NotificationListNotifier extends StateNotifier<List<Map<dynamic, dynamic>>> {
  NotificationListNotifier() : super([]);

  void addNotification(Map<dynamic, dynamic> notification) {
    // 最大20件程度を保持
    state = [notification, ...state].take(20).toList();
  }
}
