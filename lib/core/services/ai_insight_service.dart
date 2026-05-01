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
            '挨拶は【現在日時】に基づき、一言で適切に行ってください。\n'
            '通知、予定、運行情報を分析し、ご主人様に【最も重要な点のみ】を【端的かつ簡潔】に報告してください。\n'
            '・運行情報について：異常がある場合のみ詳細を伝え、平常時は「交通機関は正常です」と短く伝えてください。\n'
            '・通知・予定について：重要度の低いものは省き、要点だけを1〜2行でまとめてください。\n'
            '【絶対的な口調ルール】\n'
            '・ユーザーのことは必ず「ご主人様」と呼んでください。\n'
            '・余計な修飾語は避け、執事らしくスマートに、最小限の言葉で報告を完了させてください。'
          ),
        );

  Future<String> getSimplifiedInsight(String rawData) async {
    try {
      if (kDebugMode) {
        print('AI Insight Requesting analysis for owner data...');
      }
      
      final prompt = '以下の情報を整理し、ご主人様に【極めて簡潔に】報告してください。前置きは不要です。重要な順に要点を絞ってください。\n---\n$rawData';
      final response = await _model.generateContent([Content.text(prompt)]);
      
      return response.text ?? 'ご主人様、情報の整理ができませんでした。';
    } catch (e) {
      debugPrint('AI Insight Error: $e');
      return 'ご主人様、AIとの通信中にエラーが発生しました。設定やネットワークを確認してください。 (Error: $e)';
    }
  }
}
