import 'dart:convert';
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
    // WMO Weather interpretation codes (WW)
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
  // Open-Meteo API (No API key required for non-commercial use)
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> fetchWeather(double lat, double lon) async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon&current_weather=true&timezone=auto'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        return WeatherData(
          temperature: current['temperature'],
          weatherCode: current['weathercode'],
          location: 'NAKAHARA KU', // 将来的に逆ジオコーディングで取得
        );
      } else {
        throw Exception('Failed to load weather');
      }
    } catch (e) {
      rethrow;
    }
  }
}
