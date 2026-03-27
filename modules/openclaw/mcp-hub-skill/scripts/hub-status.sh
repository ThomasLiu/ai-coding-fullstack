#!/bin/bash
# MCP Hub 状态查询
# 显示所有注册的 server 及其状态

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
CHECK_SERVER="${SCRIPT_DIR}/check-server.sh"

# 获取 server 列表
if [[ -f "${CONFIG_DIR}/servers.conf" ]]; then
    SERVERS=$(cat "${CONFIG_DIR}/servers.conf")
else
    SERVERS="chrome,github,filesystem,memory"
fi

echo "{"
echo "  \"hub\": \"mcp-hub\","
echo "  \"servers\": ["

first=true
IFS=',' read -ra SERVER_ARRAY <<< "$SERVERS"
for server in "${SERVER_ARRAY[@]}"; do
    if [[ -f "${CHECK_SERVER}" ]]; then
        # 获取完整 JSON 状态
        status=$("$CHECK_SERVER" "$server" 2>/dev/null || echo "{\"status\":\"unknown\"}")
        # 提取 name 和 status
        name=$(echo "$status" | jq -r '.server // empty')
        status_val=$(echo "$status" | jq -r '.status // empty')
        via_val=$(echo "$status" | jq -r '.via // .method // empty')
    else
        name="$server"
        status_val="unknown"
        via_val="unknown"
    fi

    if $first; then
        first=false
    else
        echo ","
    fi
    echo -n "    {\"name\":\"$name\",\"status\":\"$status_val\",\"via\":\"$via_val\"}"
done

echo ""
echo "  ],"
echo "  \"total\": ${#SERVER_ARRAY[@]},"
echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
echo "}"
