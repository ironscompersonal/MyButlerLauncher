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
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.LEAN_BODY_MASS,
    HealthDataType.BODY_WATER_MASS,
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

      // 最新の体組成データを取得
      for (var type in [HealthDataType.WEIGHT, HealthDataType.BODY_FAT_PERCENTAGE, HealthDataType.LEAN_BODY_MASS, HealthDataType.BODY_WATER_MASS]) {
        final points = healthData.where((p) => p.type == type).toList();
        if (points.isNotEmpty) {
          points.sort((a, b) => b.dateFrom.compareTo(a.dateFrom)); // 最新順
          final latest = points.first;
          final val = (latest.value as NumericHealthValue).numericValue.toDouble();
          if (type == HealthDataType.WEIGHT) summary['weight'] = val;
          if (type == HealthDataType.BODY_FAT_PERCENTAGE) summary['body_fat'] = val;
          if (type == HealthDataType.LEAN_BODY_MASS) summary['lean_mass'] = val;
          if (type == HealthDataType.BODY_WATER_MASS) summary['body_water'] = val;
        }
      }

    } catch (e) {
      print('Error fetching health data: $e');
    }

    return summary;
  }

  /// 週間データ（直近7日間）を取得
  Future<List<Map<String, dynamic>>> fetchWeeklyHealthData() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6)); // 今日を含めて7日間
    final startDate = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);
    
    List<Map<String, dynamic>> weeklyData = [];

    try {
      final permissions = _types.map((e) => HealthDataAccess.READ).toList();
      bool? hasPermission = await _health.hasPermissions(_types, permissions: permissions);
      if (hasPermission != true) return [];

      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: now,
        types: _types,
      );

      // 日ごとに集計
      for (int i = 0; i < 7; i++) {
        final day = startDate.add(Duration(days: i));
        if (day.isAfter(now)) break;

        final dayData = healthData.where((p) => 
          p.dateFrom.year == day.year && 
          p.dateFrom.month == day.month && 
          p.dateFrom.day == day.day
        ).toList();

        Map<String, dynamic> daySummary = {
          'date': day,
          'steps': 0,
          'weight': 0.0,
          'body_fat': 0.0,
          'lean_mass': 0.0,
          'body_water': 0.0,
        };

        for (var p in dayData) {
          if (p.type == HealthDataType.STEPS) {
            daySummary['steps'] += (p.value as NumericHealthValue).numericValue.toInt();
          } else if (p.type == HealthDataType.WEIGHT) {
            daySummary['weight'] = (p.value as NumericHealthValue).numericValue.toDouble();
          } else if (p.type == HealthDataType.BODY_FAT_PERCENTAGE) {
            daySummary['body_fat'] = (p.value as NumericHealthValue).numericValue.toDouble();
          } else if (p.type == HealthDataType.LEAN_BODY_MASS) {
            daySummary['lean_mass'] = (p.value as NumericHealthValue).numericValue.toDouble();
          } else if (p.type == HealthDataType.BODY_WATER_MASS) {
            daySummary['body_water'] = (p.value as NumericHealthValue).numericValue.toDouble();
          }
        }
        weeklyData.add(daySummary);
      }
    } catch (e) {
      print('Error fetching weekly health data: $e');
    }

    return weeklyData;
  }
}
