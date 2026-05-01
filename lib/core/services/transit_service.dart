import 'package:http/http.dart' as http;
import 'dart:convert';

class TransitService {
  // Yahoo!路線情報のRSSが終了したため、ウェブページから直接取得する方式に変更
  // ひとまず関東エリアをターゲットにする
  static const String _webUrl = 'https://transit.yahoo.co.jp/diainfo/area/4';

  Future<String> fetchTransitInfo() async {
    try {
      final response = await http.get(Uri.parse(_webUrl));
      if (response.statusCode == 200) {
        final html = response.body;
        final items = _extractFromHtml(html);
        
        if (items.isEmpty) {
          return '【運行情報：正常】現在、関東エリアの主な路線で目立った遅延や運転見合わせの情報はありません。';
        }
        
        return '【運行情報：異常あり】以下の路線で情報があります：\n' + items.join('\n');
      }
      return '運行情報の取得に失敗しました。 (Status: ${response.statusCode})';
    } catch (e) {
      return '運行情報の取得中にエラーが発生しました: $e';
    }
  }

  List<String> _extractFromHtml(String html) {
    final List<String> results = [];
    
    // 運行情報がある路線のリストを抽出するための正規表現
    // HTMLタグを含んで取得し、後で除去する
    final RegExp regExp = RegExp(r'<td><a href="\/diainfo\/.*?">(.*?)<\/a><\/td>\s*<td>(.*?)<\/td>', dotAll: true);
    final matches = regExp.allMatches(html);
    
    for (final match in matches) {
      // HTMLタグを除去するヘルパー
      String clean(String input) => input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      
      final title = clean(match.group(1) ?? '');
      final status = clean(match.group(2) ?? '');
      
      if (status.isEmpty || status.contains('平常')) continue;
      
      results.add('[$title] $status');
    }

    // 別の構造（リスト形式など）も考慮
    if (results.isEmpty) {
      final RegExp regExpAlt = RegExp(r'<dt><a href="\/diainfo\/.*?">(.*?)<\/a><\/dt>\s*<dd.*?>(.*?)<\/dd>', dotAll: true);
      final matchesAlt = regExpAlt.allMatches(html);
      for (final match in matchesAlt) {
        String clean(String input) => input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        final title = clean(match.group(1) ?? '');
        final status = clean(match.group(2) ?? '');
        if (status.isEmpty || status.contains('平常')) continue;
        results.add('[$title] $status');
      }
    }

    return results;
  }
}

class TransitData {
  final String title;
  final String status;
  final String description;

  TransitData({required this.title, required this.status, required this.description});
}
