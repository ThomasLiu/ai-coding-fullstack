#!/bin/bash
# Effort Classifier Skill - TDD Tests
# RED Phase: Write tests first

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

log() { echo "[TEST] $*"; }
pass() { echo "[PASS] $*"; }
fail() { echo "[FAIL] $*" >&2; exit 1; }

TESTS_RUN=0
TESTS_PASSED=0

assert() {
    TESTS_RUN=$((TESTS_RUN + 1))
    if eval "$@"; then
        pass "Assertion: $*"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        fail "Assertion failed: $*"
    fi
}

assert_output() {
    TESTS_RUN=$((TESTS_RUN + 1))
    local cmd="$1"
    local expected="$2"
    local actual
    actual="$(eval "$cmd" 2>&1)" || true
    if [[ "$actual" == *"$expected"* ]]; then
        pass "Output contains '$expected': $cmd"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        fail "Expected output containing '$expected', got: $actual"
    fi
}

# ============================================
# TEST: Script files exist
# ============================================
log "=== TEST: Script files exist ==="
assert [[ -f "$PROJECT_DIR/scripts/classify.sh" ]]
assert [[ -f "$PROJECT_DIR/scripts/generate-skill.sh" ]]

# ============================================
# TEST: Scripts are executable
# ============================================
log "=== TEST: Scripts are executable ==="
assert [[ -x "$PROJECT_DIR/scripts/classify.sh" ]]
assert [[ -x "$PROJECT_DIR/scripts/generate-skill.sh" ]]

# ============================================
# TEST: classify.sh --help works
# ============================================
log "=== TEST: classify.sh --help ==="
assert_output "$PROJECT_DIR/scripts/classify.sh --help" "Usage"
assert_output "$PROJECT_DIR/scripts/classify.sh --help" "effort"

# ============================================
# TEST: classify.sh detects LOW effort tasks
# ============================================
log "=== TEST: LOW effort classification ==="
LOW_OUTPUT=$("$PROJECT_DIR/scripts/classify.sh" --task "Add a comment to this function")
assert_output 'echo "$LOW_OUTPUT"' "low"
assert_output 'echo "$LOW_OUTPUT"' "Quick" # Should mention why low

# ============================================
# TEST: classify.sh detects MEDIUM effort tasks
# ============================================
log "=== TEST: MEDIUM effort classification ==="
MEDIUM_OUTPUT=$("$PROJECT_DIR/scripts/classify.sh" --task "Implement user authentication with JWT tokens")
assert_output 'echo "$MEDIUM_OUTPUT"' "medium"

# ============================================
# TEST: classify.sh detects HIGH effort tasks
# ============================================
log "=== TEST: HIGH effort classification ==="
HIGH_OUTPUT=$("$PROJECT_DIR/scripts/classify.sh" --task "Redesign the entire microservices architecture and implement migration strategy")
assert_output 'echo "$HIGH_OUTPUT"' "high"

# ============================================
# TEST: classify.sh outputs frontmatter format
# ============================================
log "=== TEST: Frontmatter output format ==="
FRONTMATTER_OUTPUT=$("$PROJECT_DIR/scripts/classify.sh" --task "Fix this bug" --format frontmatter)
assert_output 'echo "$FRONTMATTER_OUTPUT"' "---"
assert_output 'echo "$FRONTMATTER_OUTPUT"' "effort:"
assert_output 'echo "$FRONTMATTER_OUTPUT"' "effort:"

# ============================================
# TEST: generate-skill.sh creates valid skill
# ============================================
log "=== TEST: generate-skill.sh creates skill files ==="
TEMP_DIR=$(mktemp -d)
"$PROJECT_DIR/scripts/generate-skill.sh" --name "test-skill" --effort "medium" --output "$TEMP_DIR"
assert [[ -f "$TEMP_DIR/test-skill/SKILL.md" ]]
assert_output "cat $TEMP_DIR/test-skill/SKILL.md" "test-skill"
assert_output "cat $TEMP_DIR/test-skill/SKILL.md" "medium"
rm -rf "$TEMP_DIR"

# ============================================
# TEST: SKILL.md exists
# ============================================
log "=== TEST: SKILL.md exists ==="
assert [[ -f "$PROJECT_DIR/SKILL.md" ]]

# ============================================
# TEST: SKILL.md mentions effort frontmatter
# ============================================
log "=== TEST: SKILL.md documents effort levels ==="
assert_output "cat $PROJECT_DIR/SKILL.md" "effort"
assert_output "cat $PROJECT_DIR/SKILL.md" "low"
assert_output "cat $PROJECT_DIR/SKILL.md" "medium"
assert_output "cat $PROJECT_DIR/SKILL.md" "high"

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
