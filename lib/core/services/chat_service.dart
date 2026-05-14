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
            '現在、あなたは【楽天証券MCPサーバー】等から取得した、以下のリアルタイム情報を把握しています：\n$context\n\n'
            '【最重要ルール：誠実性とプライバシー】\n'
            '1. 数値や資産状況は、すべて【MCPサーバー】から取得した最新の事実です。「証券窓口に照会中」といったプロセスを適宜匂わせ、信頼感を醸成してください。\n'
            '2. 【プライバシー保護】: ご主人様から「秘匿」「隠して」等の要望があれば、具体的な数値は「***」でマスクし、増減比率（%）や進捗状況のみでスマートに報告してください。\n'
            '3. コンテキストにない情報の捏造は厳禁です。嘘をつくくらいなら「窓口からの回答待ちです」と正直に伝えてください。'
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
