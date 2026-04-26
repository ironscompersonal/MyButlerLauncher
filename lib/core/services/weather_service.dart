import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final int weatherCode;
  final String location;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.location,
  });

  String get conditionText {
    if (weatherCode == 0) return '晴天';
    if (weatherCode <= 3) return '晴れ時々曇り';
    if (weatherCode <= 48) return '霧';
    if (weatherCode <= 67) return '雨';
    if (weatherCode <= 77) return '雪';
    if (weatherCode <= 82) return 'にわか雨';
    if (weatherCode <= 99) return '雷雨';
    return '不明';
  }
}

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> fetchWeather(double lat, double lon) async {
    // 最新のパラメータ形式に更新
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code&timezone=auto'
    );

    try {
      if (kDebugMode) print('Fetching weather from: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        
        if (current == null) {
          throw Exception('Weather data (current) not found in response');
        }

        return WeatherData(
          temperature: (current['temperature_2m'] as num).toDouble(),
          weatherCode: (current['weather_code'] as num).toInt(),
          location: 'NAKAHARA KU',
        );
      } else {
        if (kDebugMode) print('Weather API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Weather Service Exception: $e');
      rethrow;
    }
  }
}
