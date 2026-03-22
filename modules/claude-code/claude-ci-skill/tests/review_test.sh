#!/bin/bash
# Claude CI Skill - TDD Tests
# RED: 测试优先

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

log() { echo "[TEST] $*"; }
pass() { echo "[PASS] $*"; }
fail() { echo "[FAIL] $*" >&2; exit 1; }

# 测试计数
TESTS_RUN=0
TESTS_PASSED=0

assert() {
    TESTS_RUN=$((TESTS_RUN + 1))
    if "$@"; then
        pass "Assertion: $*"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        fail "Assertion failed: $*"
    fi
}

# ============================================
# TEST: Claude CLI 可用
# ============================================
log "=== TEST: Claude CLI 可用 ==="
assert command -v claude

# ============================================
# TEST: --bare flag 存在
# ============================================
log "=== TEST: --bare flag 支持 ==="
assert claude --help 2>&1 | grep -q "bare"

# ============================================
# TEST: review.sh 存在
# ============================================
log "=== TEST: review.sh 存在 ==="
assert [[ -f "$PROJECT_DIR/scripts/review.sh" ]]

# ============================================
# TEST: review.sh 可执行
# ============================================
log "=== TEST: review.sh 可执行 ==="
assert [[ -x "$PROJECT_DIR/scripts/review.sh" ]]

# ============================================
# TEST: review.sh 输出帮助信息
# ============================================
log "=== TEST: review.sh 帮助信息 ==="
assert "$PROJECT_DIR/scripts/review.sh" --help 2>&1 | grep -q "Usage"

# ============================================
# TEST: test-gen.sh 存在
# ============================================
log "=== TEST: test-gen.sh 存在 ==="
assert [[ -f "$PROJECT_DIR/scripts/test-gen.sh" ]]

# ============================================
# TEST: doc-gen.sh 存在
# ============================================
log "=== TEST: doc-gen.sh 存在 ==="
assert [[ -f "$PROJECT_DIR/scripts/doc-gen.sh" ]]

# ============================================
# TEST: GitHub Actions 模板存在
# ============================================
log "=== TEST: GitHub Actions 模板 ==="
assert [[ -f "$PROJECT_DIR/.github/workflows/claude-review.yml" ]]

# ============================================
# TEST: GitHub Actions 模板有效
# ============================================
log "=== TEST: GitHub Actions 模板 YAML 有效 ==="
if command -v python3 &>/dev/null; then
    if python3 -c "import yaml" 2>/dev/null; then
        python3 -c "import yaml; yaml.safe_load(open('$PROJECT_DIR/.github/workflows/claude-review.yml'))"
        pass "YAML 有效"
    else
        # 如果没有 yaml 模块，检查基本格式
        if grep -q "name:" "$PROJECT_DIR/.github/workflows/claude-review.yml" && grep -q "on:" "$PROJECT_DIR/.github/workflows/claude-review.yml"; then
            pass "YAML 基本格式正确"
        else
            fail "YAML 格式错误"
        fi
    fi
fi

# ============================================
# TEST: SKILL.md 存在
# ============================================
log "=== TEST: SKILL.md 存在 ==="
assert [[ -f "$PROJECT_DIR/SKILL.md" ]]

echo ""
echo "=========================================="
echo "测试结果: $TESTS_PASSED/$TESTS_RUN 通过"
echo "=========================================="

if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
    echo "✅ 所有测试通过!"
    exit 0
else
    echo "❌ $((TESTS_RUN - TESTS_PASSED)) 个测试失败"
    exit 1
fi
