class MCPToolResult {
  final bool isSuccess;
  final Map<String, dynamic> data;
  final String? errorMessage;

  MCPToolResult({required this.isSuccess, this.data = const {}, this.errorMessage});
}

/// MCP連携の基盤サービス（クリーン版）
class MCPService {
  // 現在、特定の外部ツール連携は定義されていません。
}
