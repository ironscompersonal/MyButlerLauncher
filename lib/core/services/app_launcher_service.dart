import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:io';

class AppLauncherService {
  static const _channel = MethodChannel('com.mybutler.launcher_app/notifications');

  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    if (!Platform.isAndroid) return _getMockApps();
    try {
      final List<dynamic> apps = await _channel.invokeMethod('getInstalledApps');
      return apps.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Failed to get apps: $e');
      return [];
    }
  }

  Future<void> launchApp(String packageName) async {
    if (!Platform.isAndroid) {
      print('Mock Launching: $packageName');
      return;
    }
    try {
      await _channel.invokeMethod('launchApp', {'packageName': packageName});
    } catch (e) {
      print('Failed to launch app: $e');
    }
  }

  Future<Uint8List?> getAppIcon(String packageName) async {
    if (!Platform.isAndroid) return null;
    try {
      final Uint8List? icon = await _channel.invokeMethod('getAppIcon', {'packageName': packageName});
      return icon;
    } catch (e) {
      print('Failed to get icon for $packageName: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> _getMockApps() {
    return [
      {'name': 'Settings', 'packageName': 'com.android.settings'},
      {'name': 'Google Fit', 'packageName': 'com.google.android.apps.fitness'},
      {'name': 'Rakuten Securities', 'packageName': 'jp.co.rakuten_sec.ispeed'},
      {'name': 'Chrome', 'packageName': 'com.android.chrome'},
    ];
  }
}
