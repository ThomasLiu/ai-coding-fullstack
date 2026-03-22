#!/bin/bash
# Issue #1 TDD 测试 - 基于 --bare flag 打造零开销 CI 脚本

PASS=0
FAIL=0

assert() {
    local desc="$1"
    local cmd="$2"
    if eval "$cmd" &>/dev/null; then
        echo "  ✅ PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  ❌ FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

assert_file() {
    local desc="$1"
    local file="$2"
    if [ -f "$file" ]; then
        echo "  ✅ PASS: $desc (file exists: $file)"
        PASS=$((PASS + 1))
    else
        echo "  ❌ FAIL: $desc (file missing: $file)"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local desc="$1"
    local file="$2"
    local pattern="$3"
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "  ✅ PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  ❌ FAIL: $desc (pattern '$pattern' not found in $file)"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "========================================"
echo "Issue #1: --bare flag CI 脚本 TDD 测试"
echo "========================================"
echo ""

echo "--- 1. SKILL.md ---"
assert_file "SKILL.md 存在" "claude-ci-skill/SKILL.md"
assert_contains "SKILL.md 包含 bare flag" "claude-ci-skill/SKILL.md" "bare"
assert_contains "SKILL.md 包含 Claude" "claude-ci-skill/SKILL.md" "claude"

echo ""
echo "--- 2. 脚本模板 ---"
assert_file "review.sh 存在" "claude-ci-skill/scripts/review.sh"
assert_file "test-gen.sh 存在" "claude-ci-skill/scripts/test-gen.sh"
assert_file "doc-gen.sh 存在" "claude-ci-skill/scripts/doc-gen.sh"
assert_contains "review.sh 使用 --bare" "claude-ci-skill/scripts/review.sh" "bare"
assert_contains "test-gen.sh 使用 --bare" "claude-ci-skill/scripts/test-gen.sh" "bare"
assert_contains "doc-gen.sh 使用 --bare" "claude-ci-skill/scripts/doc-gen.sh" "bare"

echo ""
echo "--- 3. GitHub Actions ---"
assert_file "workflow 存在" ".github/workflows/claude-ci.yml"
assert_contains "workflow 使用 --bare" ".github/workflows/claude-ci.yml" "bare"
assert_contains "workflow 使用 claude" ".github/workflows/claude-ci.yml" "claude"

echo ""
echo "========================================"
echo "结果: $PASS passed, $FAIL failed"
echo "========================================"
[ $FAIL -eq 0 ]
