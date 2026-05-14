import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:math';

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
    if (!Platform.isAndroid) return true; // デスクトップ版では常にtrue（モック用）
    try {
      return await _health.isHealthConnectAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Play StoreのHealth Connectページを開く
  Future<void> openHealthConnectStore() async {
    if (!Platform.isAndroid) return;
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
    if (!Platform.isAndroid) return true;
    try {
      final permissions = _types.map((e) => HealthDataAccess.READ).toList();
      return await _health.requestAuthorization(_types, permissions: permissions);
    } catch (e) {
      print('Health Connect Permission Error: $e');
      return false;
    }
  }

  /// 直近24時間のデータを取得
  Future<Map<String, dynamic>> fetchHealthSummary() async {
    if (!Platform.isAndroid) return _getMockSummary();

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    Map<String, dynamic> summary = {
      'steps': 0,
      'sleep_minutes': 0,
      'avg_heart_rate': 0,
      'status': 'searching',
      'details': '', 
    };

    try {
      // 接続可能かチェック
      bool? isSupported = await _health.isHealthConnectAvailable();
      if (isSupported != true) {
        summary['status'] = 'not_supported';
        summary['details'] = 'ヘルスコネクトが利用できません。';
        return summary;
      }

      final permissions = _types.map((e) => HealthDataAccess.READ).toList();
      bool? hasPermission = await _health.hasPermissions(_types, permissions: permissions);

      if (hasPermission != true) {
        bool authorized = await requestPermissions();
        if (!authorized) {
          summary['status'] = 'denied';
          summary['details'] = '権限が拒否されました。設定を確認してください。';
          return summary;
        }
      }

      int totalSteps = 0;
      List<double> heartRates = [];
      int totalSleepMinutes = 0;

      // 型ごとに個別に取得を試みる（一つがエラーでも他は生かす）
      for (var type in _types) {
        try {
          List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
            startTime: yesterday,
            endTime: now,
            types: [type],
          );
          
          print('Fetched ${data.length} points for type: $type');

          for (var point in data) {
            if (point.type == HealthDataType.STEPS) {
              totalSteps += (point.value as NumericHealthValue).numericValue.toInt();
            } else if (point.type == HealthDataType.HEART_RATE) {
              heartRates.add((point.value as NumericHealthValue).numericValue.toDouble());
            } else if (point.type == HealthDataType.SLEEP_ASLEEP) {
              totalSleepMinutes += point.dateTo.difference(point.dateFrom).inMinutes;
            } else if (point.type == HealthDataType.WEIGHT) {
              summary['weight'] = (point.value as NumericHealthValue).numericValue.toDouble();
            }
          }
        } catch (e) {
          print('Error fetching $type: $e');
        }
      }

      summary['steps'] = totalSteps;
      summary['sleep_minutes'] = totalSleepMinutes;
      if (heartRates.isNotEmpty) {
        summary['avg_heart_rate'] = (heartRates.reduce((a, b) => a + b) / heartRates.length).round();
      }
      
      summary['status'] = (totalSteps > 0 || heartRates.isNotEmpty || totalSleepMinutes > 0) ? 'success' : 'no_data';
      if (summary['status'] == 'no_data') {
        summary['details'] = '権限はありますが、過去24時間のデータがヘルスコネクトに存在しません。';
      }

    } catch (e) {
      print('Health Overall Error: $e');
      summary['status'] = 'error';
      summary['details'] = 'システムエラーが発生しました: $e';
    }

    return summary;
  }

  /// 週間データ（直近7日間）を取得
  Future<List<Map<String, dynamic>>> fetchWeeklyHealthData() async {
    if (!Platform.isAndroid) return _getMockWeeklyData();

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
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

  // --- Mock Helpers ---

  Map<String, dynamic> _getMockSummary() {
    return {
      'steps': 8540,
      'sleep_minutes': 425,
      'avg_heart_rate': 68,
      'weight': 72.5,
      'body_fat': 18.2,
      'lean_mass': 59.3,
      'body_water': 42.1,
    };
  }

  List<Map<String, dynamic>> _getMockWeeklyData() {
    final now = DateTime.now();
    final random = Random();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return {
        'date': date,
        'steps': 5000 + random.nextInt(5000),
        'weight': 72.0 + random.nextDouble(),
        'body_fat': 18.0 + random.nextDouble(),
        'lean_mass': 59.0,
        'body_water': 42.0,
      };
    });
  }
}
