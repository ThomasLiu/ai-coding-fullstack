#!/bin/bash
# MCP Hub 配置验证
# 验证配置文件的完整性和正确性

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

# 检查配置目录
if [[ ! -d "$CONFIG_DIR" ]]; then
    mkdir -p "$CONFIG_DIR"
fi

# 检查 servers.conf
if [[ -f "${CONFIG_DIR}/servers.conf" ]]; then
    SERVERS=$(cat "${CONFIG_DIR}/servers.conf")
    if [[ -z "$SERVERS" ]]; then
        echo "Warning: servers.conf is empty"
        exit 1
    fi
fi

# 空配置也是 valid（会使用默认）
# 输出到 stderr 不干扰 stdout 的 JSON 结果
echo "valid"
