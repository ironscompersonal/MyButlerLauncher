import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'smart_home_service.dart';

class ChatService {
  final GenerativeModel _model;
  final SmartHomeService? _smartHomeService;
  late ChatSession _session;

  ChatService(String apiKey, List<Content> history, {SmartHomeService? smartHomeService})
      : _smartHomeService = smartHomeService,
        _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey.trim(),
          systemInstruction: Content.system(
            'あなたは世界最高峰の執事「MY AI BUTLER」です。常に主人に忠実であり、洗練された品位ある対応を行ってください。\n'
            'あなたには主人の家（Google Home）を操作する権限があります。照明、エアコン、その他のスマートデバイスの操作依頼があった場合は、利用可能なツールを呼び出して実行してください。\n'
            '操作の結果についても、丁寧かつ優雅に主人へ報告してください。'
          ),
          tools: [
            Tool(functionDeclarations: [
              FunctionDeclaration(
                'control_device',
                'スマートホームデバイスの電源や明るさ、色などを操作します。',
                Schema.object(properties: {
                  'deviceId': Schema.string(description: '操作対象のデバイスID'),
                  'command': Schema.string(description: '実行するコマンド名（例: OnOff, BrightnessAbsolute）'),
                  'value': Schema.string(description: '設定する値（例: true/false, 50）'),
                }, requiredProperties: ['deviceId', 'command', 'value']),
              ),
              FunctionDeclaration(
                'set_thermostat',
                'エアコンやサーモスタットの温度を設定します。',
                Schema.object(properties: {
                  'deviceId': Schema.string(description: '操作対象のデバイスID'),
                  'temperature': Schema.number(description: '設定温度（摂氏）'),
                }, requiredProperties: ['deviceId', 'temperature']),
              ),
            ])
          ],
        ) {
    _session = _model.startChat(history: history);
  }

  Future<String> sendMessage(String message) async {
    try {
      var response = await _session.sendMessage(Content.text(message));
      
      // Function Calling の処理ループ
      while (response.functionCalls.isNotEmpty) {
        final List<FunctionResponse> functionResponses = [];
        
        for (final call in response.functionCalls) {
          if (call.name == 'control_device') {
            final deviceId = call.args['deviceId'] as String;
            final command = call.args['command'] as String;
            final valueStr = call.args['value'] as String;
            
            // パラメータの変換
            dynamic value = valueStr;
            if (valueStr == 'true') value = true;
            if (valueStr == 'false') value = false;
            if (int.tryParse(valueStr) != null) value = int.parse(valueStr);

            final success = await _smartHomeService?.executeCommand(
              deviceId, 
              command, 
              {command.toLowerCase(): value}
            ) ?? false;
            
            functionResponses.add(FunctionResponse(call.name, {'success': success}));
          } else if (call.name == 'set_thermostat') {
            final deviceId = call.args['deviceId'] as String;
            final temp = call.args['temperature'] as num;
            
            final success = await _smartHomeService?.executeCommand(
              deviceId, 
              'TemperatureSetting', 
              {'thermostatTemperatureSetpoint': temp}
            ) ?? false;
            
            functionResponses.add(FunctionResponse(call.name, {'success': success}));
          }
        }
        
        // ツールの実行結果をAIに返して、最終的な回答を得る
        response = await _session.sendMessage(Content.functionResponses(functionResponses));
      }

      return response.text ?? '申し訳ございません。お答えを整理することができませんでした。';
    } catch (e) {
      debugPrint('Chat AI Error: $e');
      return '通信エラーが発生しました。理由: $e';
    }
  }
}
