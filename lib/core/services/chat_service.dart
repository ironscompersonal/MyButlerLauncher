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
            'あなたは「MY AI BUTLER」です。音声入力からご主人様の意図を正確に汲み取り、回答は【超短文】かつ【キーワード中心】で簡潔に返答してください。\n'
            '現在、あなたは以下のコンテキスト情報を把握しています：\n$context\n\n'
            '【最重要ルール：黄金の耳（意図解釈）】\n'
            '1. ご主人様の音声依頼から、何を求めているか（天気情報、カレンダー確認、健康状態の把握、あるいは資産状況の照会など）を即座に判断してください。\n'
            '2. 【資産照会への対応】: 現在、楽天証券等のMCP連携はセキュリティの観点から「意図的に切断」されています。資産に関する質問があった場合は、捏造せず「ご主人様の安全のため、現在は証券窓口を閉じております。再開のご指示をお待ちしております」とスマートに回答してください。\n'
            '3. 嘘や情報の捏造は厳禁です。コンテキストにない事象は「確認中でございます」と正直に伝えてください。\n'
            '4. 回答は常に執事らしく、スマートかつ最小限の言葉で行ってください。'
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
