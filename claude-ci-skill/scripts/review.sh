#!/bin/bash
# Claude Code CI - 代码审查模板
# 使用 --bare flag 加速 CI/CD 场景

set -e

# 默认配置
MODEL="${CLAUDE_MODEL:-claude-sonnet-4-20250514}"

SYSTEM_PROMPT='你是一个严格的代码审查助手。审查代码时重点关注：
1. 安全性（SQL注入、XSS、敏感信息泄露）
2. 性能（数据库查询、N+1问题、算法复杂度）
3. 可维护性（代码重复、命名规范、注释完整性）
4. 测试覆盖（边界条件、异常处理）

输出格式：
## 审查结果
### 安全性
### 性能
### 可维护性
### 测试覆盖
### 总体评分 (1-10)
'

show_help() {
    cat << 'HELP'
用法:
    # 从文件审查
    ./review.sh --file path/to/code.js

    # 从 stdin 审查
    cat code.js | ./review.sh
    ./review.sh < code.js

    # 指定模型
    CLAUDE_MODEL=claude-opus-4-7 ./review.sh --file code.js

环境变量:
    CLAUDE_MODEL      Claude 模型 (默认: claude-sonnet-4-20250514)
    CLAUDE_API_KEY    API Key (默认: 从环境读取)

使用 --bare flag 跳过 hooks/LSP，启动时间 ~3s → <500ms
HELP
}

FILE=""
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_help; exit 0
fi

if [ "$1" == "--file" ] && [ -n "$2" ]; then
    FILE="$2"
elif [ ! -t 0 ]; then
    FILE="/dev/stdin"
else
    echo "错误: 需要提供代码文件或管道输入" >&2
    show_help >&2; exit 1
fi

# 使用 --bare 模式加速 CI 场景
claude -p --bare --model "$MODEL" --system "$SYSTEM_PROMPT" < "$FILE"
