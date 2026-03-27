#!/bin/bash
# 会话共享脚本 - OpenClaw 与 Claude Code 之间共享会话
# Usage: share-session.sh --export <session-id> | --import <session-id>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_STORE="${SCRIPT_DIR}/../.sessions"

mkdir -p "$SESSION_STORE"

show_help() {
    cat << EOF
Session Share - OpenClaw ↔ Claude Code 会话共享

Usage:
    share-session.sh --export <session-id>   # 导出当前会话
    share-session.sh --import <session-id>   # 导入会话
    share-session.sh --list                   # 列出已存储的会话
    share-session.sh --help

Description:
    导出时：将当前 OpenClaw 会话上下文打包
    导入时：将会话注入 Claude Code 执行上下文

EOF
}

export_session() {
    local session_id="$1"
    local session_file="${SESSION_STORE}/${session_id}.json"

    # 收集当前会话信息
    local openclaw_info=""
    if command -v openclaw &>/dev/null; then
        openclaw_info=$(openclaw session --export 2>/dev/null || echo "{}")
    else
        openclaw_info='{"openclaw":"not-available"}'
    fi

    # 收集环境信息
    local env_info=$(cat << EOF
{
    "session_id": "$session_id",
    "exported_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "cwd": "$(pwd)",
    "openclaw": $openclaw_info,
    "shell": "$SHELL",
    "user": "$(whoami)"
}
EOF
)

    echo "$env_info" > "$session_file"
    echo "Session exported: $session_id"
    echo "$env_info"
}

import_session() {
    local session_id="$1"
    local session_file="${SESSION_STORE}/${session_id}.json"

    if [[ ! -f "$session_file" ]]; then
        echo "Error: session not found: $session_id" >&2
        exit 1
    fi

    # 验证会话文件
    if ! jq empty "$session_file" 2>/dev/null; then
        echo "Error: invalid session file" >&2
        exit 1
    fi

    # 读取并应用会话
    local session_data=$(cat "$session_file")
    local exported_at=$(jq -r '.exported_at' "$session_file")
    local cwd=$(jq -r '.cwd' "$session_file")

    echo "Session imported: $session_id (exported: $exported_at)"
    echo "Working directory: $cwd"

    # 返回会话数据供调用者使用
    echo "$session_data"

    # 设置环境标记（可被 Claude Code 读取）
    export OPENCLAW_SESSION_ID="$session_id"
    export OPENCLAW_SESSION_DATA="$session_data"

    # OK 标记（测试用）
    echo "OK"
}

list_sessions() {
    if [[ ! -d "$SESSION_STORE" ]] || [[ -z "$(ls -A "$SESSION_STORE" 2>/dev/null)" ]]; then
        echo "No sessions stored"
        return
    fi

    echo "Stored sessions:"
    for f in "${SESSION_STORE}"/*.json; do
        local id=$(basename "$f" .json)
        local date=$(jq -r '.exported_at' "$f" 2>/dev/null || echo "unknown")
        echo "  $id (exported: $date)"
    done
}

# 主逻辑
ACTION="$1"

case "$ACTION" in
    --export)
        if [[ -z "$2" ]]; then
            echo "Error: session-id required" >&2
            exit 1
        fi
        export_session "$2"
        ;;
    --import)
        if [[ -z "$2" ]]; then
            echo "Error: session-id required" >&2
            exit 1
        fi
        import_session "$2"
        ;;
    --list)
        list_sessions
        ;;
    --help|-h)
        show_help
        ;;
    *)
        echo "Error: unknown action '$ACTION'" >&2
        show_help >&2
        exit 1
        ;;
esac
