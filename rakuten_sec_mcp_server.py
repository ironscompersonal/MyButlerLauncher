# 楽天証券 MCP サーバー (Reference Implementation)
# 
# 使い方:
# 1. pip install mcp fastmcp
# 2. python rakuten_sec_mcp_server.py
# 
from mcp.server.fastmcp import FastMCP
import json

mcp = FastMCP("RakutenSecurities")

@mcp.tool()
def get_nisa_status():
    """楽天証券から最新のNISA残枠情報を取得します。"""
    # ここに実際のスクレイピングまたはAPI連携のロジックを実装してください。
    # 現在は、実機側での疎通確認用に具体的な数値を返却するサンプルとなっています。
    return {
        "tsumitate_limit_used": 500000,
        "tsumitate_limit_remaining": 700000,
        "growth_limit_used": 2399702,
        "growth_limit_remaining": 298,
        "status": "active"
    }

@mcp.tool()
def get_account_summary():
    """証券口座の総資産額、買付余力、評価損益を取得します。"""
    return {
        "total_assets": 12500000,
        "buying_power": 450000,
        "profit_loss": 1200000,
        "profit_loss_rate": 10.6
    }

@mcp.tool()
def get_trust_list():
    """保有している投資信託の一覧と評価額を取得します。"""
    return {
        "items": [
            {"name": "eMAXIS Slim 全世界株式", "value": 5000000, "profit": 650000},
            {"name": "eMAXIS Slim 米国株式(S&P500)", "value": 3500000, "profit": 420000},
            {"name": "楽天・全米株式インデックス・ファンド", "value": 2000000, "profit": 130000}
        ]
    }

if __name__ == "__main__":
    # Android実機からアクセス可能なようにSSEトランスポートを使用
    # ホストマシンのIPアドレスを指定して実行してください
    mcp.run(transport='sse')
