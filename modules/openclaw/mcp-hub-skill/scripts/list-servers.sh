#!/bin/bash
# MCP Server 发现脚本
# 列出已注册的 MCP Server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

# 默认 server 列表
DEFAULT_SERVERS="chrome,github,filesystem,memory"

# 如果有配置文件，从配置文件读取
if [[ -f "${CONFIG_DIR}/servers.conf" ]]; then
    cat "${CONFIG_DIR}/servers.conf"
else
    echo "$DEFAULT_SERVERS"
fi
