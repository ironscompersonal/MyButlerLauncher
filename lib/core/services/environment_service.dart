import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 執事の「感覚器」を定義するクラス
class EnvironmentData {
  final String locationName;
  final double latitude;
  final double longitude;
  final String weatherCondition;
  final double temperature;
  final bool isMock;

  EnvironmentData({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.weatherCondition,
    required this.temperature,
    this.isMock = false,
  });

  String get description => '現在地: $locationName, 天候: $weatherCondition, 気温: ${temperature.toStringAsFixed(1)}℃';
}

/// 位置・天気情報の統合サービス
class EnvironmentService {
  static const _mockKey = 'environment_mock_enabled';
  static const _mockLocKey = 'environment_mock_location';
  static const _mockWeatherKey = 'environment_mock_weather';

  /// 現在の環境情報を取得（モック設定がある場合はそれを優先）
  Future<EnvironmentData> fetchCurrentEnvironment(WeatherData realWeather) async {
    final prefs = await SharedPreferences.getInstance();
    final isMockEnabled = prefs.getBool(_mockKey) ?? false;

    if (isMockEnabled) {
      return EnvironmentData(
        locationName: prefs.getString(_mockLocKey) ?? '東京（モック）',
        latitude: 35.6812,
        longitude: 139.7671,
        weatherCondition: prefs.getString(_mockWeatherKey) ?? '雨',
        temperature: 18.5,
        isMock: true,
      );
    }

    // 実機環境（一旦WeatherServiceの情報をベースにする）
    return EnvironmentData(
      locationName: realWeather.location,
      latitude: realWeather.lat ?? 35.6812,
      longitude: realWeather.lon ?? 139.7671,
      weatherCondition: realWeather.conditionText,
      temperature: realWeather.temperature,
    );
  }

  /// デバッグ用：モック設定を保存
  Future<void> setMockData({required bool enabled, String? location, String? weather}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mockKey, enabled);
    if (location != null) await prefs.setString(_mockLocKey, location);
    if (weather != null) await prefs.setString(_mockWeatherKey, weather);
  }
}

final environmentServiceProvider = Provider((ref) => EnvironmentService());
