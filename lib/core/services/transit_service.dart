import 'package:http/http.dart' as http;
import 'dart:convert';

class TransitService {
  // Yahoo!路線情報の運行情報RSS（全国）
  static const String _rssUrl = 'https://transit.yahoo.co.jp/rss/diainfo/all.xml';

  Future<String> fetchTransitInfo() async {
    try {
      final response = await http.get(Uri.parse(_rssUrl));
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final items = _extractItems(body);
        
        final delayedItems = items.where((i) => !i.contains('平常運転')).toList();
        
        if (delayedItems.isEmpty) {
          return '【運行情報：正常】現在、各路線で目立った遅延や運転見合わせの情報はありません。全て平常通り運行されています。';
        }
        
        return '【運行情報：異常あり】以下の路線で遅延や運転見合わせが発生しています：\n' + delayedItems.join('\n');
      }
      return '運行情報の取得に失敗しました。';
    } catch (e) {
      return '運行情報の取得中にエラーが発生しました: $e';
    }
  }

  List<String> _extractItems(String xml) {
    final List<String> results = [];
    final RegExp regExp = RegExp(r'<title>(.*?)<\/title>\s*<link>(.*?)<\/link>\s*<description>(.*?)<\/description>', dotAll: true);
    final matches = regExp.allMatches(xml);
    
    for (final match in matches) {
      final title = match.group(1) ?? '';
      final description = match.group(3) ?? '';
      
      // RSSの先頭のタイトル（Yahoo!路線情報...）は除外
      if (title.contains('Yahoo!路線情報')) continue;
      
      // 「平常運転」以外の情報を優先的に追加
      if (!description.contains('平常運転')) {
        results.insert(0, '[$title] $description');
      } else {
        results.add('[$title] $description');
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
