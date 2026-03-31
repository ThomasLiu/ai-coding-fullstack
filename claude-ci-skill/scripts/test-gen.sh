#!/bin/bash
# Claude Code CI - 测试生成模板
# 使用 --bare flag 加速 CI/CD 场景

set -e

MODEL="${CLAUDE_MODEL:-claude-sonnet-4-20250514}"

SYSTEM_PROMPT='你是一个测试工程师。根据提供的代码生成全面的测试用例：
1. 单元测试（边界条件、异常情况）
2. 集成测试（API 调用、数据流）
3. 使用 Jest/Vitest 风格，assert 语法

输出格式：
## 测试用例
### 单元测试
### 集成测试
### 边界条件
'

show_help() {
    cat << 'HELP'
用法:
    ./test-gen.sh --file path/to/code.js [--framework jest|vitest]
    cat code.js | ./test-gen.sh --framework jest

环境变量:
    CLAUDE_MODEL      Claude 模型 (默认: claude-sonnet-4-20250514)
HELP
}

FILE=""
FRAMEWORK="jest"

while [ $# -gt 0 ]; do
    case "$1" in
        --file) FILE="$2"; shift 2 ;;
        --framework) FRAMEWORK="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) shift ;;
    esac
done

if [ -z "$FILE" ]; then
    if [ ! -t 0 ]; then
        FILE="/dev/stdin"
    else
        echo "错误: 需要 --file 参数或 stdin 输入" >&2
        show_help >&2; exit 1
    fi
fi

# --bare 跳过 hooks/LSP，测试生成速度更快
claude -p --bare --model "$MODEL" --system "$SYSTEM_PROMPT" < "$FILE"
