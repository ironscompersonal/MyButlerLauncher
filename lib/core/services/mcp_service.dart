import 'package:google_generative_ai/google_generative_ai.dart';
import 'location_service.dart';

class MCPToolResult {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic> data;

  MCPToolResult({required this.isSuccess, required this.message, this.data = const {}});
}

/// MCP連携の基盤サービス（クリーン版・生活支援特化）
class MCPService {
  final LocationService _locationService = LocationService();

  /// AIに提供するツール定義のリスト
  List<Tool> getAvailableTools() {
    return [
      Tool(functionDeclarations: [
        FunctionDeclaration(
          'control_home_device',
          '照明やエアコンなどのホームデバイスを操作します。',
          Schema.object(properties: {
            'device': Schema.string(description: '操作対象のデバイス名 (例: ライト, エアコン, テレビ)'),
            'action': Schema.string(description: '実行するアクション (例: オン, オフ, 24度にする)'),
          }, requiredProperties: ['device', 'action']),
        ),
        FunctionDeclaration(
          'open_google_maps',
          'Googleマップを開いて経路検索や周辺検索を行います。',
          Schema.object(properties: {
            'query': Schema.string(description: '目的地や検索キーワード (例: 新宿駅, 近くのコンビニ)'),
            'mode': Schema.string(
              description: '動作モード (directions: 経路検索, search: 周辺検索)',
            ),
          }, requiredProperties: ['query', 'mode']),
        ),
      ]),
    ];
  }

  /// ツールの実行
  Future<MCPToolResult> executeTool(String functionName, Map<String, dynamic> arguments) async {
    if (functionName == 'control_home_device') {
      final device = arguments['device'] as String;
      final action = arguments['action'] as String;
      print('MCP Action: $device を $action にしました。');
      return MCPToolResult(
        isSuccess: true,
        message: '$deviceの操作（$action）を承りました。',
      );
    }
    
    if (functionName == 'open_google_maps') {
      final query = arguments['query'] as String;
      final mode = arguments['mode'] as String;
      
      try {
        await _locationService.openGoogleMaps(query: query, mode: mode);
        final actionText = mode == 'directions' ? 'への経路' : 'の周辺検索';
        return MCPToolResult(
          isSuccess: true,
          message: 'Googleマップで「$query」$actionTextを表示しました。',
        );
      } catch (e) {
        return MCPToolResult(isSuccess: false, message: 'マップの起動に失敗しました: $e');
      }
    }
    
    return MCPToolResult(isSuccess: false, message: '不明なツールでございます。');
  }
}
