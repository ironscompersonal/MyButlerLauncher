import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class HealthService {
  final Health _health = Health();

  // 取得するデータ型
  final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.HEART_RATE,
  ];

  /// Health Connectがインストールされているか確認
  Future<bool> isHealthConnectInstalled() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _health.isHealthConnectAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Play StoreのHealth Connectページを開く
  Future<void> openHealthConnectStore() async {
    final url = Uri.parse('market://details?id=com.google.android.apps.healthdata');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final webUrl = Uri.parse('https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata');
      await launchUrl(webUrl);
    }
  }

  /// 権限のリクエスト
  Future<bool> requestPermissions() async {
    try {
      // 全ての権限をREADで要求
      final permissions = _types.map((e) => HealthDataAccess.READ).toList();
      return await _health.requestAuthorization(_types, permissions: permissions);
    } catch (e) {
      print('Health Connect Permission Error: $e');
      return false;
    }
  }

  /// 直近24時間のデータを取得
  Future<Map<String, dynamic>> fetchHealthSummary() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    Map<String, dynamic> summary = {
      'steps': 0,
      'sleep_minutes': 0,
      'avg_heart_rate': 0,
    };

    try {
      // 権限確認
      final permissions = _types.map((e) => HealthDataAccess.READ).toList();
      bool? hasPermission = await _health.hasPermissions(_types, permissions: permissions);
      if (hasPermission != true) {
        bool authorized = await requestPermissions();
        if (!authorized) return summary;
      }

      // データ取得
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: _types,
      );

      // 集計
      int steps = 0;
      int sleepMinutes = 0;
      List<double> heartRates = [];

      for (var point in healthData) {
        if (point.type == HealthDataType.STEPS) {
          steps += (point.value as NumericHealthValue).numericValue.toInt();
        } else if (point.type == HealthDataType.SLEEP_SESSION) {
          final start = point.dateFrom;
          final end = point.dateTo;
          sleepMinutes += end.difference(start).inMinutes;
        } else if (point.type == HealthDataType.HEART_RATE) {
          heartRates.add((point.value as NumericHealthValue).numericValue.toDouble());
        }
      }

      summary['steps'] = steps;
      summary['sleep_minutes'] = sleepMinutes;
      if (heartRates.isNotEmpty) {
        summary['avg_heart_rate'] = (heartRates.reduce((a, b) => a + b) / heartRates.length).round();
      }

    } catch (e) {
      print('Error fetching health data: $e');
    }

    return summary;
  }
}
