import 'package:flutter/services.dart';

class AppLauncherService {
  static const _channel = MethodChannel('com.mybutler.launcher_app/notifications');

  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      final List<dynamic> apps = await _channel.invokeMethod('getInstalledApps');
      return apps.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Failed to get apps: $e');
      return [];
    }
  }

  Future<void> launchApp(String packageName) async {
    try {
      await _channel.invokeMethod('launchApp', {'packageName': packageName});
    } catch (e) {
      print('Failed to launch app: $e');
    }
  }
}
