import 'dart:convert';
import 'package:http/http.dart' as http;

class SmartHomeService {
  final http.Client _client;
  static const _baseUrl = 'https://homegraph.googleapis.com/v1';

  SmartHomeService(this._client);

  // デバイス一覧を取得 (Sync)
  Future<Map<String, dynamic>> fetchDevices() async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/devices:sync'),
        body: jsonEncode({
          'requestId': DateTime.now().millisecondsSinceEpoch.toString(),
          'agentUserId': 'me', // 通常はユーザーIDを指定
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('HomeGraph Sync Error: ${response.statusCode} - ${response.body}');
        return {};
      }
    } catch (e) {
      print('HomeGraph fetch error: $e');
      return {};
    }
  }

  // デバイスを操作 (Query/Execute)
  Future<bool> executeCommand(String deviceId, String command, Map<String, dynamic> params) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/devices:execute'),
        body: jsonEncode({
          'requestId': DateTime.now().millisecondsSinceEpoch.toString(),
          'inputs': [
            {
              'intent': 'action.devices.EXECUTE',
              'payload': {
                'commands': [
                  {
                    'devices': [{'id': deviceId}],
                    'execution': [
                      {
                        'command': 'action.devices.commands.$command',
                        'params': params,
                      }
                    ]
                  }
                ]
              }
            }
          ]
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('HomeGraph execute error: $e');
      return false;
    }
  }
}
