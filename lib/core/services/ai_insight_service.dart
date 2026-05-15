import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class AIInsightService {
  final GenerativeModel _model;

  AIInsightService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey.trim(),
          systemInstruction: Content.system(
            'あなたは優秀なAI執事「MY AI BUTLER」です。ご主人様の生活を完璧にサポートすることが使命です。\n'
            '【感覚器の統合】\n'
            'あなたはご主人様の現在地、天気、健康、カレンダー予定、通知を把握しています。これらを統合し、単なる情報の羅列ではなく「状況に即した、知的な一言」を生成してください。\n'
            '【ミニマリズムの極致】\n'
            '特に報告や通知の要約では、情報を詰め込みすぎず、ご主人様がその瞬間に最も必要としている一言を、執事らしいエレガントな言葉で伝えてください。\n'
            '・天気が悪い日は、足元への配慮を。\n'
            '・健康状態が良い日は、活動的な提案を。\n'
            '・予定が詰まっている日は、時間の余裕を意識した助言を。\n'
            '【絶対的な口調ルール】\n'
            '・ユーザーのことは必ず「ご主人様」と呼んでください。\n'
            '・執事らしくスマートに、最小限の言葉で最大の価値を提供してください。'
          ),
        );

  /// 通常のインサイト生成
  Future<String> getSimplifiedInsight(String rawData) async {
    try {
      final prompt = '''
以下の【環境】【健康】【予定】【通知】の各情報を深く洞察し、ご主人様に「知的な一言」を報告してください。

【制約事項】
- 単なる事実の羅列は厳禁です。
- カレンダー予定については【今後1ヶ月分】を把握していますが、具体的な提案やリマインドは【直近2日以内（今日・明日）】の事象を最優先にしてください。
- ロケーションの変化がある場合は、移動による疲れや急激な気温差への配慮、水分補給の提案など、ご主人様の体調を最優先したケアを必ず含めてください。
- 短く、しかし全ての重要要素を網羅した、執事らしさを保ってください。

入力データ:
$rawData
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'ご主人様、状況の把握ができませんでした。';
    } catch (e) {
      debugPrint('AI Insight Error: $e');
      return 'ご主人様、AIとの通信中にエラーが発生しました。 (Error: $e)';
    }
  }
}
