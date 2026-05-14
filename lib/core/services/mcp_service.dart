import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// MCPツールの実行結果を保持するクラス
class MCPToolResult {
  final bool isSuccess;
  final Map<String, dynamic> data;
  final String? errorMessage;

  MCPToolResult({
    required this.isSuccess,
    this.data = const {},
    this.errorMessage,
  });
}

/// 執事らしいエラーメッセージを生成するMixin
mixin ButlerErrorHandling {
  String getButlerErrorMessage(String action) {
    return '主人、申し訳ございません。現在、$actionに少々時間を要しております。後ほど改めて報告させていただきます。';
  }
}

/// MCP連携の基盤サービス
class MCPService with ButlerErrorHandling {
  // 接続先のMCPサーバーURL (SSE または JSON-RPC over HTTP)
  // TODO: 本番環境のIPアドレスに置き換え
  static const String _mcpBaseUrl = 'https://your-mcp-gateway.com';

  /// 共通のJSON-RPC呼び出しロジック
  Future<MCPToolResult> _callTool(String serverName, String toolName, Map<String, dynamic> arguments) async {
    try {
      final response = await http.post(
        Uri.parse('$_mcpBaseUrl/$serverName/call/$toolName'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'arguments': arguments}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MCPToolResult(isSuccess: true, data: data);
      } else {
        return MCPToolResult(
          isSuccess: false, 
          errorMessage: 'サーバー応答エラー: ${response.statusCode}'
        );
      }
    } catch (e) {
      return MCPToolResult(isSuccess: false, errorMessage: e.toString());
    }
  }

  /// 楽天証券：口座サマリー取得
  Future<MCPToolResult> getAccountSummary() async {
    return await _callTool('rakuten_sec', 'get_account_summary', {});
  }

  /// 楽天証券：NISA状況取得
  Future<MCPToolResult> getNisaStatus() async {
    return await _callTool('rakuten_sec', 'get_nisa_status', {});
  }

  /// 楽天証券：投資信託一覧取得
  Future<MCPToolResult> getInvestmentTrustList() async {
    return await _callTool('rakuten_sec', 'get_trust_list', {});
  }
}

final mcpServiceProvider = Provider((ref) => MCPService());
