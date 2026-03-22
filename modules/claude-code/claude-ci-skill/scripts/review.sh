#!/bin/bash
# Claude Code Review - 代码审查脚本

set -e

show_help() {
    cat << EOF
Claude Code Review - 代码审查工具

Usage:
    review.sh [options]

Options:
    --help           显示帮助
    --context FILE   从文件读取上下文
    --system TEXT    System prompt
    --bare          使用 --bare 模式

Examples:
    review.sh --context pr.txt --bare
    review.sh --system "Review for security" < code.py
EOF
}

# 默认参数
CONTEXT=""
SYSTEM_PROMPT="Review this code for issues, bugs, and improvements."
USE_BARE=""

# 解析参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            show_help
            exit 0
            ;;
        --context)
            CONTEXT="$2"
            shift 2
            ;;
        --system)
            SYSTEM_PROMPT="$2"
            shift 2
            ;;
        --bare)
            USE_BARE="--bare"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# 构建命令
CMD="claude -p $USE_BARE --system '$SYSTEM_PROMPT'"

# 如果有上下文文件，添加到命令
if [[ -n "$CONTEXT" ]]; then
    CMD="$CMD < $CONTEXT"
fi

# 执行
eval "$CMD"
