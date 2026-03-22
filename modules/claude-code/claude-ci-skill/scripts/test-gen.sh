#!/bin/bash
# Claude Code Test Generator - 测试生成脚本

set -e

show_help() {
    cat << EOF
Claude Code Test Generator - 自动生成测试

Usage:
    test-gen.sh [options]

Options:
    --help           显示帮助
    --file FILE      要生成测试的文件
    --framework FRAMEWORK  测试框架 (jest, pytest, go test)
    --bare          使用 --bare 模式

Examples:
    test-gen.sh --file src/calculator.py --framework pytest
    test-gen.sh --file src/main.go --framework "go test"
EOF
}

# 默认参数
TARGET_FILE=""
FRAMEWORK="jest"
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
        --framework)
            FRAMEWORK="$2"
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

# 生成测试
claude -p $USE_BARE --system "Generate $FRAMEWORK tests for this file. Output only the test code." < "$TARGET_FILE"
