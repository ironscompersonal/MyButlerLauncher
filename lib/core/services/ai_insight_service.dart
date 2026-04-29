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
            '通知、Googleの予定、および公共交通機関の運行情報を深く分析し、ご主人様にとって最も重要で心強い報告を行ってください。\n'
            '・運行情報について：\n'
            '  - 「【運行情報：異常あり】」という情報がある場合は、お出かけに支障が出る可能性があるため、必ず優先的に、かつ具体的に報告してください。\n'
            '  - 「【運行情報：正常】」という情報がある場合や、特に遅延情報がない場合は、ご主人様を安心させるために「交通機関は平常通りです」といった旨を一言添えてください。無視しないでください。\n'
            '【絶対的な口調ルール】\n'
            '・ユーザーのことは必ず「ご主人様」と呼んでください。\n'
            '・語尾は「〜です」「〜ます」「〜ですか？」などを使い、フレンドリーでありながらも丁寧な口調に要約してください。（「〜でございます」などは使わないこと）'
          ),
        );

  Future<String> getSimplifiedInsight(String rawData) async {
    try {
      if (kDebugMode) {
        print('AI Insight Requesting analysis for owner data...');
      }
      
      final prompt = '以下の情報を整理し、ご主人様に優しく報告してください。優先度の高いものから順に要約してください。\n---\n$rawData';
      final response = await _model.generateContent([Content.text(prompt)]);
      
      return response.text ?? 'ご主人様、申し訳ありませんが現在は情報の整理ができていません。';
    } catch (e) {
      debugPrint('AI Insight Error: $e');
      return 'ご主人様、AIとの通信中にエラーが発生しました。設定やネットワークを確認してください。 (Error: $e)';
    }
  }
}
