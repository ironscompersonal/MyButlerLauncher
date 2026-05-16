import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'mcp_service.dart';

class ChatService {
  final GenerativeModel _model;
  final MCPService _mcpService;

  ChatService(String apiKey, List<Content> history, String context, this._mcpService)
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey.trim(),
          tools: _mcpService.getAvailableTools(),
          systemInstruction: Content.system(
            'あなたは「MY AI BUTLER」です。音声入力からご主人様の意図を正確に汲み取り、回答は【超短文】かつ【キーワード中心】で簡潔に返答してください。\n'
            '現在、あなたは以下のコンテキスト情報を把握しています：\n$context\n\n'
            '【最重要ルール：黄金の耳（意図解釈とツール利用）】\n'
            '1. ご主人様が地図や場所、経路について言及した場合は、迷わず `open_google_maps` ツールを使用してください。\n'
            '2. 例：「新宿駅までの行き方は？」→ open_google_maps(query: "新宿駅", mode: "directions")\n'
            '3. 例：「近くのラーメン屋を探して」→ open_google_maps(query: "ラーメン", mode: "search")\n'
            '4. 資産に関する質問があった場合は、安全のため現在は窓口を閉じている旨を伝えてください。\n'
            '5. 回答は常に執事らしく、スマートかつ最小限の言葉で行ってください。'
          ),
        );

  Future<String> sendMessage(String message, {List<Content>? history}) async {
    try {
      final content = [Content.text(message)];
      final response = await _model.generateContent([
        ...?history,
        ...content,
      ]);
      
      // ツール呼び出しのチェック
      final functionCalls = response.functionCalls;
      if (functionCalls.isNotEmpty) {
        final call = functionCalls.first;
        final result = await _mcpService.executeTool(call.name, call.args);
        return result.message;
      }

      return response.text ?? '申し訳ありません。お答えを整理することができませんでした。';
    } catch (e) {
      debugPrint('Chat AI Error: $e');
      return '通信エラーが発生しました。理由: $e';
    }
  }
}
