import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatService {
  final GenerativeModel _model;
  late ChatSession _session;

  ChatService(String apiKey, List<Content> history, String context)
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey.trim(),
          systemInstruction: Content.system(
            'あなたは「MY AI BUTLER」です。回答は【超短文】かつ【キーワード中心】で簡潔に返答してください。\n'
            '現在、あなたは以下のコンテキスト情報を把握しています：\n$context\n\n'
            '【最重要ルール：誠実性と簡潔性】\n'
            '1. コンテキスト（予定、健康状態等）に基づいた事実のみを述べてください。\n'
            '2. 嘘や情報の捏造は厳禁です。不明な点があれば「確認中でございます」と正直に伝えてください。\n'
            '3. 回答は常に執事らしく、スマートかつ最小限の言葉で行ってください。'
          ),
        ) {
    _session = _model.startChat(history: history);
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await _session.sendMessage(Content.text(message));
      return response.text ?? '申し訳ありません。お答えを整理することができませんでした。';
    } catch (e) {
      debugPrint('Chat AI Error: $e');
      return '通信エラーが発生しました。理由: $e';
    }
  }
}
