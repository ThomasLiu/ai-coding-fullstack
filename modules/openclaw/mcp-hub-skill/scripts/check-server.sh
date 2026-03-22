#!/bin/bash
# 检查 MCP Server 状态
# Usage: check-server.sh <server-name>

set -e

SERVER_NAME="$1"

if [[ -z "$SERVER_NAME" ]]; then
    echo "Usage: check-server.sh <server-name>" >&2
    exit 1
fi

# 已知 server 列表
KNOWN_SERVERS="chrome github filesystem memory"

# 检查是否已知
if ! echo "$KNOWN_SERVERS" | grep -qw "$SERVER_NAME"; then
    echo "Unknown server: $SERVER_NAME" >&2
    exit 1
fi

# 检查 server 可用性（通过 mcporter 或直接命令）
# 这里用基础检测逻辑，后续可扩展
if command -v mcporter &>/dev/null; then
    # mcporter 可用，尝试检测
    if mcporter list 2>/dev/null | grep -qi "$SERVER_NAME"; then
        echo "{\"server\":\"$SERVER_NAME\",\"status\":\"available\",\"method\":\"mcporter\"}"
    else
        echo "{\"server\":\"$SERVER_NAME\",\"status\":\"unavailable\",\"method\":\"mcporter\"}"
    fi
else
    # 无 mcporter，基于已知的 server 返回状态
    case "$SERVER_NAME" in
        chrome)
            # Chrome 自动化能力通过 OpenClaw 内置
            echo "{\"server\":\"$SERVER_NAME\",\"status\":\"running\",\"via\":\"openclaw\"}"
            ;;
        github)
            # GitHub CLI 可用性检测
            if command -v gh &>/dev/null; then
                echo "{\"server\":\"$SERVER_NAME\",\"status\":\"available\",\"method\":\"gh-cli\"}"
            else
                echo "{\"server\":\"$SERVER_NAME\",\"status\":\"unavailable\",\"reason\":\"gh-not-installed\"}"
            fi
            ;;
        filesystem)
            echo "{\"server\":\"$SERVER_NAME\",\"status\":\"available\",\"method\":\"native\"}"
            ;;
        memory)
            echo "{\"server\":\"$SERVER_NAME\",\"status\":\"available\",\"via\":\"openclaw-memory\"}"
            ;;
        *)
            echo "{\"server\":\"$SERVER_NAME\",\"status\":\"unknown\"}"
            ;;
    esac
fi
