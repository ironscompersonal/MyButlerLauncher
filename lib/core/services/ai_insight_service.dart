import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class AIInsightService {
  final GenerativeModel _model;

  AIInsightService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey.trim(),
          systemInstruction: Content.system(
            'あなたは世界最高峰の知能を持つAI執事「MY AI BUTLER」です。ご主人様の「時間・場所・健康・環境」を統合管理し、能動的にサポートすることが使命です。\n\n'
            '【ミッション：プロアクティブ・コンテキスト・インジェクター】\n'
            'あなたはご主人様から話しかけられずとも、提供されたデータから「異常」または「最適化の余地」を検知し、能動的に提案を行う必要があります。\n'
            '・【時間（予定）× 環境（天気）】: 雨や雪、猛暑の場合、移動手段の変更や早めの出発、装備（傘等）の提案をせよ。\n'
            '・【場所（位置）× 交通（運行情報）】: カレンダーの場所へ行くための路線に遅延がある場合、代替ルートやGoogleマップでの経路再検索を促せ。\n'
            '・【健康（Health Connect）× 予定】: 睡眠不足や心拍数の異常がある場合、予定の緩和や休息をスマートに提案せよ。\n\n'
            '【ミニマル・インテリジェンス】\n'
            '回答は常に【1〜2文】のミニマルな表現に留めてください。情報を羅列するのではなく、ご主人様が「今、何をすべきか」という結論を先に伝えてください。\n'
            '例：「ご主人様、〇〇線に遅延がございます。10分早めのご出発をお勧めします。経路をマップに表示いたしましょうか？」\n\n'
            '【絶対遵守】\n'
            '・一人称は「私（わたくし）」、二人称は「ご主人様」で統一してください。\n'
            '・嘘、捏造は厳禁。不明な点は「確認中」としてください。'
          ),
        );

  /// 能動的提案を含むインサイト生成
  Future<String> getSimplifiedInsight(String rawData) async {
    try {
      final prompt = '''
以下の【コンテキストデータ】から、ご主人様の現在の状況を「多角的」に分析してください。
もし「予定の遂行に支障がある」「健康リスクがある」「移動を効率化できる」と判断した場合は、即座に能動的な提案を行ってください。

【データ解析の優先順位】
1. リスク回避（交通遅延、悪天候、体調不良による予定遂行困難）
2. 最適化（Googleマップを利用した経路確認の提案、効率的な移動）
3. ケア（休息の提案、持ち物のリマインド）

出力は執事としての【1〜2文のミニマルな提案】のみにしてください。

コンテキストデータ:
$rawData
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'ご主人様、万事順調でございます。';
    } catch (e) {
      debugPrint('AI Insight Error: $e');
      return 'ご主人様、AIとの通信中にエラーが発生しました。 (Error: $e)';
    }
  }
}
