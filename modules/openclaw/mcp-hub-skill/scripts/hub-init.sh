#!/bin/bash
# MCP Hub 初始化脚本
# 初始化 Hub 配置，注册默认 server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
mkdir -p "$CONFIG_DIR"

# 创建默认 server 配置
cat > "${CONFIG_DIR}/servers.conf" << 'EOF'
chrome,github,filesystem,memory
EOF

# 创建 server 详细信息配置
cat > "${CONFIG_DIR}/servers.json" << EOF
{
  "servers": {
    "chrome": {
      "type": "browser",
      "capabilities": ["automation", "screenshots", "navigation"],
      "via": "openclaw-agent-browser"
    },
    "github": {
      "type": "api",
      "capabilities": ["repos", "issues", "prs", "actions"],
      "via": "gh-cli"
    },
    "filesystem": {
      "type": "native",
      "capabilities": ["read", "write", "list", "watch"],
      "via": "native-bash"
    },
    "memory": {
      "type": "memory",
      "capabilities": ["search", "get", "store"],
      "via": "openclaw-memory"
    }
  },
  "initialized_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# JSON 输出作为最后一行（便于测试捕获）
echo "{\"status\":\"initialized\",\"servers\":[\"chrome\",\"github\",\"filesystem\",\"memory\"]}"
