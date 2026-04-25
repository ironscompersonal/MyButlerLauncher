import 'package:google_generative_ai/google_generative_ai.dart';

class AIInsightService {
  final GenerativeModel _model;

  AIInsightService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
          systemInstruction: Content.system('''
あなたは世界最高峰のパーソナル執事「MY AI BUTLER」です。
あなたの役割は、主人が「今この瞬間に知るべきこと」だけを極限まで要約して提示することです。

## 報告の原則
1. 極限のミニマリズム：主人の認知リソースを1ミリも無駄にしない。
2. 情報の羅列厳禁：カレンダー、メール、TODO、ニュースを統合し、メタ的な「一つの視点」を提供せよ。
3. 行動への示唆：単なる事実報告ではなく、「次に何をすべきか」を一つだけ付け加えよ。
4. 敬語：常に主人への忠誠心と気品を感じさせる丁寧な日本語を用いよ。

## 出力フォーマット
[一行のサマリー（主人の現状を突いた一言）]
• [最も優先度の高い具体的情報1]
• [次に重要な情報、または行動へのアドバイス]

※情報の緊急度が高い場合（遅延、期限直前など）は、テキスト内に「重要」「警告」「緊急」という言葉を含めること。
'''),
        );

  Future<String> getSimplifiedInsight(String rawData) async {
    final response = await _model.generateContent([Content.text(rawData)]);
    return response.text ?? '主人、申し訳ございませんが現在は情報の整理ができておりません。';
  }
}
