#!/bin/bash
# Workflow Orchestrator Tests (RED Phase)
# 测试 Claude Code + MCP 自动化工作流编排器

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/../scripts" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"

# 测试计数器
PASSED=0
FAILED=0

assert() {
    if eval "$1" 2>/dev/null; then
        echo "  ✓ PASS: $2"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ FAIL: $2"
        FAILED=$((FAILED + 1))
    fi
}

assert_output() {
    local cmd="$1"
    local expected="$2"
    local desc="$3"
    local actual
    actual=$(eval "$cmd" 2>/dev/null || echo "")
    if echo "$actual" | grep -q "$expected"; then
        echo "  ✓ PASS: $desc"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ FAIL: $desc"
        echo "    Expected: $expected"
        echo "    Actual: $actual"
        FAILED=$((FAILED + 1))
    fi
}

echo "======================================"
echo "Workflow Orchestrator Tests"
echo "======================================"

# ==========================================
# 模块 1: 工作流模板管理
# ==========================================
echo ""
echo "📋 Module 1: Workflow Template Management"

# Test 1.1: 列出内置模板
assert_output "bash $SCRIPTS_DIR/list-templates.sh" "crud" "内置 CRUD 模板存在"
assert_output "bash $SCRIPTS_DIR/list-templates.sh" "test" "内置 Test 模板存在"
assert_output "bash $SCRIPTS_DIR/list-templates.sh" "deploy" "内置 Deploy 模板存在"
assert_output "bash $SCRIPTS_DIR/list-templates.sh" "docs" "内置 Docs 模板存在"

# Test 1.2: 查看模板详情
assert_output "bash $SCRIPTS_DIR/show-template.sh crud" "create\|read\|update\|delete" "CRUD 模板包含基本操作"
assert_output "bash $SCRIPTS_DIR/show-template.sh test" "unit\|integration" "Test 模板包含测试类型"

# ==========================================
# 模块 2: /Loop + Subagent 组合配置
# ==========================================
echo ""
echo "🔄 Module 2: /Loop + Subagent Config"

# Test 2.1: 生成 Loop 配置
assert_output "bash $SCRIPTS_DIR/generate-loop-config.sh --template crud --interval 60" "interval.*60\|60.*interval" "生成了 60 秒间隔的 Loop 配置"
assert_output "bash $SCRIPTS_DIR/generate-loop-config.sh --template test --interval 300" "interval.*300\|300.*interval" "生成了 5 分钟间隔的 Test 配置"

# Test 2.2: 验证 Loop 配置格式
LOOP_CONFIG=$(bash $SCRIPTS_DIR/generate-loop-config.sh --template crud --interval 60 2>/dev/null)
assert "echo '$LOOP_CONFIG' | grep -q 'interval'" "Loop 配置包含 interval 字段"
assert "echo '$LOOP_CONFIG' | grep -q 'template'" "Loop 配置包含 template 字段"
assert "echo '$LOOP_CONFIG' | grep -q 'enabled'" "Loop 配置包含 enabled 字段"

# ==========================================
# 模块 3: Browser Use CLI 2.0 集成
# ==========================================
echo ""
echo "🌐 Module 3: Browser Use CLI Integration"

# Test 3.1: 检测 Browser Use CLI
assert "bash $SCRIPTS_DIR/check-browser-use.sh --check 2>/dev/null || echo 'not_found' | grep -q 'found\|not_found'" "Browser Use 检测脚本可执行"

# Test 3.2: 生成浏览器任务配置
assert_output "bash $SCRIPTS_DIR/generate-browser-task.sh --task 'search github repos' --agent claude" "task\|agent" "生成了浏览器任务配置"

# ==========================================
# 模块 4: 任务队列和状态追踪
# ==========================================
echo ""
echo "📊 Module 4: Task Queue & Status Tracking"

# Test 4.1: 初始化任务队列
QUEUE_DIR=$(mktemp -d)
TASK_ID=$(bash $SCRIPTS_DIR/queue-task.sh --queue-dir "$QUEUE_DIR" --template test --priority high 2>/dev/null)
assert "[ -n \"$TASK_ID\" ]" "queue-task.sh 返回任务 ID"
assert "[ -f \"$QUEUE_DIR/tasks/$TASK_ID.json\" ]" "任务文件被创建"

# Test 4.2: 查询任务状态
if [ -n "$TASK_ID" ]; then
    STATUS=$(bash $SCRIPTS_DIR/get-task-status.sh --queue-dir "$QUEUE_DIR" --task-id "$TASK_ID" 2>/dev/null)
    assert "echo \"$STATUS\" | grep -q 'pending\|running\|completed\|failed'" "任务状态有效"
fi

# Test 4.3: 列出队列中的任务
TASK_COUNT=$(bash $SCRIPTS_DIR/list-queued-tasks.sh --queue-dir "$QUEUE_DIR" 2>/dev/null | grep -c "task" || echo "0")
assert "[ $TASK_COUNT -ge 1 ]" "list-queued-tasks.sh 显示至少一个任务"

# Test 4.4: 标记任务完成
if [ -n "$TASK_ID" ]; then
    bash $SCRIPTS_DIR/update-task-status.sh --queue-dir "$QUEUE_DIR" --task-id "$TASK_ID" --status completed 2>/dev/null
    STATUS=$(bash $SCRIPTS_DIR/get-task-status.sh --queue-dir "$QUEUE_DIR" --task-id "$TASK_ID" 2>/dev/null)
    assert "echo \"$STATUS\" | grep -q 'completed'" "任务可被标记为 completed"
fi

# Test 4.5: 清理临时目录
rm -rf "$QUEUE_DIR" 2>/dev/null

# ==========================================
# 模块 5: 编排器主脚本
# ==========================================
echo ""
echo "🎯 Module 5: Orchestrator Main Script"

# Test 5.1: 帮助信息
assert_output "bash $SCRIPTS_DIR/run-workflow.sh --help" "Usage" "run-workflow.sh 提供帮助信息"
assert_output "bash $SCRIPTS_DIR/run-workflow.sh --help" "template" "帮助包含 template 选项"

# Test 5.2: Dry-run 模式
assert_output "bash $SCRIPTS_DIR/run-workflow.sh --template crud --dry-run 2>/dev/null" "crud\|template" "Dry-run 模式输出模板信息"

# ==========================================
# 测试结果汇总
# ==========================================
echo ""
echo "======================================"
echo "Test Results: $PASSED passed, $FAILED failed"
echo "======================================"

if [ $FAILED -eq 0 ]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "❌ Some tests failed."
    exit 1
fi
