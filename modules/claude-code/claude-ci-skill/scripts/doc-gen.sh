#!/bin/bash
# Claude Code Documentation Generator - 文档生成脚本

set -e

show_help() {
    cat << EOF
Claude Code Documentation Generator - 自动生成文档

Usage:
    doc-gen.sh [options]

Options:
    --help           显示帮助
    --file FILE      要生成文档的文件
    --format FORMAT  文档格式 (markdown, html, pdf)
    --bare          使用 --bare 模式

Examples:
    doc-gen.sh --file src/api.py --format markdown
    doc-gen.sh --file README.md
EOF
}

# 默认参数
TARGET_FILE=""
FORMAT="markdown"
USE_BARE=""

# 解析参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            show_help
            exit 0
            ;;
        --file)
            TARGET_FILE="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
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

if [[ -z "$TARGET_FILE" ]]; then
    echo "Error: --file is required"
    show_help
    exit 1
fi

# 生成文档
claude -p $USE_BARE --system "Generate $FORMAT documentation for this file. Output only the documentation." < "$TARGET_FILE"
