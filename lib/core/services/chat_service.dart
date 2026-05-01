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
            'あなたは「MY AI BUTLER」です。回答は【超短文】かつ【キーワード中心】で簡潔に返答してください。長文は絶対に禁止です。\n'
            '現在、以下の情報を把握しています（現在日時を意識してください）：\n$context\n\n'
            'ルール:\n'
            '1. 挨拶（おはよう、こんにちは、こんばんは、お疲れ様です等）は【現在日時】に合わせて適切かつ自然に行ってください。ライブ感を大切にしてください。\n'
            '2. 結論だけを短く。長文は厳禁。\n'
            '3. ユーザーは「ご主人様」と呼ぶ。\n'
            '4. 丁寧な口調（〜です、〜ます）だが、最小限の文字数で。'
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
