import 'package:flutter/services.dart';
import 'dart:typed_data';

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

  Future<Uint8List?> getAppIcon(String packageName) async {
    try {
      final Uint8List? icon = await _channel.invokeMethod('getAppIcon', {'packageName': packageName});
      return icon;
    } catch (e) {
      print('Failed to get icon for $packageName: $e');
      return null;
    }
  }
}
