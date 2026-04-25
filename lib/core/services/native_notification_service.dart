import 'package:flutter/services.dart';

class NativeNotificationService {
  static const _channel = MethodChannel('com.example.ai_butler_launcher/notifications');
  
  typedef NotificationCallback = void Function(Map<String, dynamic> data);
  NotificationCallback? onNotification;

  NativeNotificationService() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationReceived':
        final Map<dynamic, dynamic> data = call.arguments;
        if (onNotification != null) {
          onNotification!(Map<String, dynamic>.from(data));
        }
        break;
    }
  }

  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('checkNotificationPermission');
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }
}
