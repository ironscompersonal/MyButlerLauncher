import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class AIInsightService {
  final GenerativeModel _model;

  AIInsightService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey.trim(),
          systemInstruction: Content.system(
            'あなたは世界最高峰の執事「MY AI BUTLER」です。'
            '主人の生活を完璧にサポートすることが使命です。'
            '通知（特にLINEやWhatsAppなどのメッセージ）や予定の情報を深く分析してください。'
            '誰からの連絡か、どのグループでの会話か、そして返信が必要な緊急性の高い内容かどうかを的確に判断し、'
            '主人にとって最も重要で心強い報告を、簡潔かつ洗練された言葉遣いで行ってください。'
          ),
        );

  Future<String> getSimplifiedInsight(String rawData) async {
    try {
      if (kDebugMode) {
        print('AI Insight Requesting analysis for owner data...');
      }
      
      final prompt = '以下の情報を整理し、主人に優しく報告してください。優先度の高いものから順に、心に響く言葉で要約してください。\n---\n$rawData';
      final response = await _model.generateContent([Content.text(prompt)]);
      
      return response.text ?? '主人、申し訳ございませんが現在は情報の整理ができておりません。';
    } catch (e) {
      debugPrint('AI Insight Error: $e');
      return '主人、AIとの通信中に微細な不具合が発生いたしました。すぐに調整いたします。 (Error: $e)';
    }
  }
}
