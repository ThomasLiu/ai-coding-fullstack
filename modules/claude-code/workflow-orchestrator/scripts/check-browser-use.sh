#!/bin/bash
# 检测 Browser Use CLI 是否安装
# Usage: check-browser-use.sh --check

set -e

if [[ "$1" == "--check" ]]; then
    if command -v browser-use &>/dev/null; then
        echo "Browser Use CLI found: $(which browser-use)"
        exit 0
    elif command -v npx &>/dev/null && npx browser-use --version &>/dev/null; then
        echo "Browser Use CLI found via npx"
        exit 0
    else
        echo "Browser Use CLI not found"
        exit 1
    fi
fi

# 默认输出帮助
cat << 'EOF'
Browser Use CLI Checker

Usage:
    check-browser-use.sh --check

Checks if browser-use CLI is installed and available.
EOF
