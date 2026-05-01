import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ForecastData {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;

  ForecastData({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
  });

  String get conditionText => WeatherUtils.getConditionText(weatherCode);
}

class WeatherData {
  final double temperature;
  final int weatherCode;
  final String location;
  final List<ForecastData> dailyForecast;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.location,
    required this.dailyForecast,
  });

  String get conditionText => WeatherUtils.getConditionText(weatherCode);
}

class WeatherUtils {
  static String getConditionText(int weatherCode) {
    if (weatherCode == 0) return '晴天';
    if (weatherCode <= 3) return '晴れ';
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
    // current に加え、daily（予報）も取得するようにURLを更新
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto'
    );

    try {
      if (kDebugMode) print('Fetching weather with forecast from: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        final daily = data['daily'];
        
        if (current == null) {
          throw Exception('Weather data (current) not found in response');
        }

        final List<ForecastData> forecast = [];
        if (daily != null && daily['time'] != null) {
          final times = daily['time'] as List;
          final codes = daily['weather_code'] as List;
          final maxTemps = daily['temperature_2m_max'] as List;
          final minTemps = daily['temperature_2m_min'] as List;

          // 1番目は当日なので、1（明日）と2（明後日）を取得
          for (int i = 1; i < times.length && i <= 2; i++) {
            forecast.add(ForecastData(
              date: DateTime.parse(times[i]),
              weatherCode: codes[i].toInt(),
              maxTemp: maxTemps[i].toDouble(),
              minTemp: minTemps[i].toDouble(),
            ));
          }
        }

        return WeatherData(
          temperature: (current['temperature_2m'] as num).toDouble(),
          weatherCode: (current['weather_code'] as num).toInt(),
          location: 'NAKAHARA KU',
          dailyForecast: forecast,
        );
      } else {
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Weather Service Exception: $e');
      rethrow;
    }
  }
}
