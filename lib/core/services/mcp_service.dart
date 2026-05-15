import '../utils/error_handler.dart';

class MCPToolResult {
  final bool isSuccess;
  final Map<String, dynamic> data;
  final String? errorMessage;

  MCPToolResult({required this.isSuccess, this.data = const {}, this.errorMessage});
}

/// MCP連携の基盤サービス（楽天証券関連はすべて削除済み）
class MCPService with ButlerErrorHandling {
  // 現在、特定の外部ツール連携は定義されていません。
}
