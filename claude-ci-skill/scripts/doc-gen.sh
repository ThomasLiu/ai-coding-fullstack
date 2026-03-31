#!/bin/bash
# Claude Code CI - 文档生成模板
# 使用 --bare flag 加速 CI/CD 场景

set -e

MODEL="${CLAUDE_MODEL:-claude-sonnet-4-20250514}"

SYSTEM_PROMPT='你是一个技术文档工程师。根据提供的代码生成完整的 API 文档：
1. 函数说明（参数、返回值、异常）
2. 使用示例（JavaScript/TypeScript）
3. TypeScript 类型定义

输出格式：
## API 文档
### 函数名
**参数**: 
**返回值**: 
**示例**:
'

show_help() {
    cat << 'HELP'
用法:
    ./doc-gen.sh --file path/to/code.ts [--format markdown|jsdoc]
    cat code.ts | ./doc-gen.sh

环境变量:
    CLAUDE_MODEL      Claude 模型 (默认: claude-sonnet-4-20250514)
HELP
}

FILE=""
FORMAT="markdown"

while [ $# -gt 0 ]; do
    case "$1" in
        --file) FILE="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
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

# --bare 模式：跳过插件同步，文档生成更快
claude -p --bare --model "$MODEL" --system "$SYSTEM_PROMPT" < "$FILE"
