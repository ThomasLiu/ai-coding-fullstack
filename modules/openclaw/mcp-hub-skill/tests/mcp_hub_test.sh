#!/bin/bash
# MCP Hub Skill - TDD 测试套件
# RED 阶段：先写测试，定义期望行为

set -e

PASS=0
FAIL=0

assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  ✓ PASS: $msg"
        PASS=$((PASS + 1))
    else
        echo "  ✗ FAIL: $msg"
        echo "    Expected: $expected"
        echo "    Actual:   $actual"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "  ✓ PASS: $msg"
        PASS=$((PASS + 1))
    else
        echo "  ✗ FAIL: $msg"
        echo "    Expected '$needle' in: $haystack"
        FAIL=$((FAIL + 1))
    fi
}

assert_file_exists() {
    local file="$1"
    local msg="$2"
    if [[ -f "$file" ]]; then
        echo "  ✓ PASS: $msg"
        PASS=$((PASS + 1))
    else
        echo "  ✗ FAIL: $msg (file not found: $file)"
        FAIL=$((FAIL + 1))
    fi
}

echo "========================================"
echo "MCP Hub Skill - TDD Test Suite (RED)"
echo "========================================"
echo ""

# =========================================
# 测试组 1: MCP Server 发现
# =========================================
echo "📦 [1] MCP Server 发现测试"
echo "----------------------------------"

# 测试 1.1: 列出已知 MCP Server 类型
result=$(bash scripts/list-servers.sh 2>/dev/null || echo "ERROR")
assert_eq "chrome,github,filesystem,memory" "$result" "list-servers 输出标准 server 列表"

# 测试 1.2: 服务器状态检查 - chrome 应返回包含 status 字段的 JSON
result=$(bash scripts/check-server.sh chrome 2>/dev/null || echo "ERROR")
assert_contains "$result" "status" "check-server 能识别 chrome 状态"

# 测试 1.3: 未知服务器报错
result=$(bash scripts/check-server.sh unknown-server 2>/dev/null && echo "NO_ERROR" || echo "ERROR")
assert_eq "ERROR" "$result" "未知 server 应报错"

echo ""

# =========================================
# 测试组 2: MCP 工具调用
# =========================================
echo "🔧 [2] MCP 工具调用测试"
echo "----------------------------------"

# 测试 2.1: 调用格式验证
result=$(bash scripts/call-tool.sh github list-repos 2>/dev/null || echo "ERROR")
# 正确格式应返回 JSON 或 error message，不应是 raw ERROR
if [[ "$result" != "ERROR" ]] || [[ "$result" == *"{"* ]] || [[ "$result" == *"error"* ]]; then
    echo "  ✓ PASS: call-tool 有有效输出"
    PASS=$((PASS + 1))
else
    echo "  ✗ FAIL: call-tool 输出异常"
    FAIL=$((FAIL + 1))
fi

# 测试 2.2: 缺少工具名报错
result=$(bash scripts/call-tool.sh 2>/dev/null && echo "NO_ERROR" || echo "ERROR")
assert_eq "ERROR" "$result" "缺少工具名应报错"

# 测试 2.3: 帮助信息
result=$(bash scripts/call-tool.sh --help 2>/dev/null || echo "ERROR")
assert_contains "$result" "Usage" "帮助信息正常"

echo ""

# =========================================
# 测试组 3: Skill 编排层
# =========================================
echo "🎯 [3] Skill 编排层测试"
echo "----------------------------------"

# 测试 3.1: 编排配置文件存在
assert_file_exists "SKILL.md" "SKILL.md 主文件存在"

# 测试 3.2: 编排脚本可执行
assert_file_exists "scripts/orchestrate.sh" "orchestrate.sh 存在"

# 测试 3.3: 编排模式列表
result=$(bash scripts/orchestrate.sh --list-modes 2>/dev/null || echo "ERROR")
assert_contains "$result" "sequential" "支持 sequential 模式"
assert_contains "$result" "parallel" "支持 parallel 模式"
assert_contains "$result" "fallback" "支持 fallback 模式"

echo ""

# =========================================
# 测试组 4: 会话共享机制
# =========================================
echo "🔗 [4] 会话共享机制测试"
echo "----------------------------------"

# 测试 4.1: 会话导出
result=$(bash scripts/share-session.sh --export test-session-id 2>/dev/null || echo "ERROR")
assert_contains "$result" "session_id" "会话导出包含 session_id"
assert_contains "$result" "exported" "会话导出包含 exported"

# 测试 4.2: 会话导入 (输出最后一行是 OK)
last_line=$(bash scripts/share-session.sh --import test-session-id 2>/dev/null | tail -1)
assert_eq "OK" "$last_line" "会话导入最后一行是 OK"

# 测试 4.3: 无效会话处理
result=$(bash scripts/share-session.sh --import invalid-id-$(date +%s) 2>/dev/null && echo "NO_ERROR" || echo "ERROR")
assert_eq "ERROR" "$result" "无效会话 ID 应报错"

echo ""

# =========================================
# 测试组 5: MCP Hub 核心功能
# =========================================
echo "🧠 [5] MCP Hub 核心功能测试"
echo "----------------------------------"

# 测试 5.1: Hub 初始化 (最后一行是 JSON)
last_line=$(bash scripts/hub-init.sh 2>/dev/null | tail -1)
assert_contains "$last_line" "initialized" "Hub 初始化输出包含 initialized"

# 测试 5.2: Hub 状态查询
result=$(bash scripts/hub-status.sh 2>/dev/null || echo "ERROR")
assert_contains "$result" "mcp-hub" "Hub 状态包含 hub 名称"
assert_contains "$result" "total" "Hub 状态包含 total 字段"

# 测试 5.3: Hub 配置验证 (最后一行是 valid)
last_line=$(bash scripts/hub-validate.sh 2>/dev/null | tail -1)
assert_eq "valid" "$last_line" "空配置应验证为 valid"

echo ""

# =========================================
# 测试结果汇总
# =========================================
echo "========================================"
echo "测试结果: $PASS passed, $FAIL failed"
echo "========================================"

if [[ $FAIL -eq 0 ]]; then
    echo "✅ 所有测试通过 (GREEN 阶段可以开始)"
    exit 0
else
    echo "❌ $FAIL 个测试失败 (继续 RED 阶段)"
    exit 1
fi
