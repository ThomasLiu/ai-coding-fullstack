#!/bin/bash
# AI Coding Fullstack Supervisor
# 每15分钟检查并驱动Claude Code实现最高优先级任务

set -e

LOG_FILE="$HOME/Projects/ai-coding-fullstack/logs/supervisor.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

log "=== Supervisor 开始运行 ==="

# 1. 读取 ai-coding-fullstack 最高优先级未完成的 Issue
cd "$HOME/Projects/ai-coding-fullstack"

# 获取最高优先级(P1)未完成的Issue
ISSUE=$(gh issue list --state open --limit 50 2>/dev/null | grep -E "P1|P2" | head -1)

if [[ -z "$ISSUE" ]]; then
    log "没有发现P1/P2级别的未完成Issue，检查所有未完成任务..."
    ISSUE=$(gh issue list --state open --limit 20 2>/dev/null | head -1)
fi

if [[ -z "$ISSUE" ]]; then
    log "没有未完成的Issue，退出"
    exit 0
fi

# 解析 Issue 信息
ISSUE_TITLE=$(echo "$ISSUE" | awk -F'\t' '{print $1}')
ISSUE_NUMBER=$(echo "$ISSUE" | awk -F'\t' '{print $2}')
ISSUE_LABELS=$(echo "$ISSUE" | awk -F'\t' '{print $3}')

log "选取任务: #$ISSUE_NUMBER - $ISSUE_TITLE"
log "标签: $ISSUE_LABELS"

# 2. 获取 Issue 详情
ISSUE_BODY=$(gh issue view "$ISSUE_NUMBER" --json body --jq '.body' 2>/dev/null | head -100)
log "Issue内容预览: $(echo "$ISSUE_BODY" | head -5)"

# 3. 检查是否已经有正在进行的PR
EXISTING_PR=$(gh pr list --head "feature/issue-$ISSUE_NUMBER" --state open 2>/dev/null | head -1)
if [[ -n "$EXISTING_PR" ]]; then
    log "Issue #$ISSUE_NUMBER 已有对应PR，退出"
    exit 0
fi

# 4. 创建分支
git checkout -b "feature/issue-$ISSUE_NUMBER" 2>/dev/null || git checkout "feature/issue-$ISSUE_NUMBER" 2>/dev/null || true
git pull origin main 2>/dev/null || true

# 5. 根据Issue内容创建TDD测试
log "创建TDD测试..."

# 分析Issue类型，确定需要实现的模块
if echo "$ISSUE_LABELS" | grep -q "openclaw"; then
    MODULE_DIR="$HOME/Projects/ai-coding-fullstack/modules/openclaw"
elif echo "$ISSUE_LABELS" | grep -q "claude-code"; then
    MODULE_DIR="$HOME/Projects/ai-coding-fullstack/modules/claude-code"
elif echo "$ISSUE_LABELS" | grep -q "mcp"; then
    MODULE_DIR="$HOME/Projects/ai-coding-fullstack/modules/mcp"
else
    MODULE_DIR="$HOME/Projects/ai-coding-fullstack/modules/core"
fi

mkdir -p "$MODULE_DIR/tests"

# 生成测试文件名
TEST_FILE="$MODULE_DIR/tests/$(echo "$ISSUE_TITLE" | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]')_test.sh"

# 6. 创建TODO: 实现功能
log "创建TODO: $MODULE_DIR/TODO.md"
cat > "$MODULE_DIR/TODO.md" << EOF
# Issue #$ISSUE_NUMBER: $ISSUE_TITLE

## 背景
$(echo "$ISSUE_BODY" | grep -A20 "## 背景" | head -20)

## 子任务
$(echo "$ISSUE_BODY" | grep -A50 "## 子任务" | head -50)

## TDD 进度
- [ ] RED: 编写测试
- [ ] GREEN: 实现最小代码
- [ ] REFACTOR: 重构优化
EOF

# 7. 提交初步更改
git add "$MODULE_DIR/"
git commit -m "feat #$ISSUE_NUMBER: 开始实现 $ISSUE_TITLE [WIP]" 2>/dev/null || true

log "分支已创建并提交初始状态"
log "=== Supervisor 运行结束 ==="

# 8. 输出下一步指示
echo ""
echo "=========================================="
echo "下一步操作:"
echo "1. 查看 $MODULE_DIR/TODO.md 了解任务详情"
echo "2. Claude Code 可以继续实现"
echo "3. 运行测试验证: bash $TEST_FILE"
echo "=========================================="
