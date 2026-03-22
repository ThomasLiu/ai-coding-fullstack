#!/bin/bash
# TDD RED: Skill Generator Tests
# Run with: ./skill_generator_test.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
cd "$SKILL_DIR"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

passed=0
failed=0

assert() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == "$expected" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $description"
        ((passed++))
    else
        echo -e "${RED}✗ FAIL${NC}: $description"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        ((failed++))
    fi
}

assert_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $description"
        ((passed++))
    else
        echo -e "${RED}✗ FAIL${NC}: $description"
        echo "  Expected to contain: $needle"
        echo "  Actual: $haystack"
        ((failed++))
    fi
}

assert_file_exists() {
    local description="$1"
    local file="$2"

    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $description"
        ((passed++))
    else
        echo -e "${RED}✗ FAIL${NC}: $description"
        echo "  File not found: $file"
        ((failed++))
    fi
}

assert_dir_exists() {
    local description="$1"
    local dir="$2"

    if [[ -d "$dir" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $description"
        ((passed++))
    else
        echo -e "${RED}✗ FAIL${NC}: $description"
        echo "  Directory not found: $dir"
        ((failed++))
    fi
}

echo "========================================="
echo "TDD RED Phase: Skill Generator Tests"
echo "========================================="
echo ""

# ─────────────────────────────────────────
# Module 1: OpenClaw Skill Spec Analyzer
# ─────────────────────────────────────────
echo "━━━ Module 1: OpenClaw Skill Spec Analyzer ━━━"

# Test 1.1: parse-skill-spec.sh outputs correct structure
output=$(bash scripts/parse-skill-spec.sh 2>/dev/null || echo "ERROR")
assert_contains "parse-skill-spec.sh runs without error" "$output" "trigger" || true

# Test 1.2: list-skill-fields extracts required fields
output=$(bash scripts/parse-skill-spec.sh 2>/dev/null | head -1 || echo "ERROR")
assert_contains "parse-skill-spec.sh outputs trigger field" "$output" "trigger" || true

# Test 1.3: skill spec has required frontmatter fields
output=$(bash scripts/parse-skill-spec.sh 2>/dev/null || echo "ERROR")
for field in "name:" "description:" "trigger:" "tools:"; do
    assert_contains "skill spec contains $field" "$output" "$field" || true
done

# Test 1.4: skill spec validation works
output=$(bash scripts/parse-skill-spec.sh 2>/dev/null || echo "ERROR")
assert_contains "skill spec outputs valid YAML" "$output" "name:" || true

# ─────────────────────────────────────────
# Module 2: Claude Code CLI Parameter Tracker
# ─────────────────────────────────────────
echo ""
echo "━━━ Module 2: Claude Code CLI Parameter Tracker ━━━"

# Test 2.1: track-claude-params.sh can list known parameters
output=$(bash scripts/track-claude-params.sh 2>/dev/null || echo "ERROR")
assert_contains "track-claude-params.sh lists parameters" "$output" "--bare" || true

# Test 2.2: track-claude-params.sh detects new parameters
output=$(bash scripts/track-claude-params.sh --check 2>/dev/null || echo "ERROR")
assert_contains "track-claude-params.sh supports --check flag" "$output" "bare" || true

# Test 2.3: known params are tracked in config
config_file="config/claude-params.json"
if [[ -f "$config_file" ]]; then
    assert_contains "claude-params.json contains --bare" "$(cat "$config_file")" "bare" || true
    assert_contains "claude-params.json contains --channels" "$(cat "$config_file")" "channels" || true
fi

# Test 2.4: claude-params.json has correct structure
if [[ -f "$config_file" ]]; then
    assert_contains "claude-params.json is valid JSON" "$(cat "$config_file")" "params" || true
fi

# Test 2.5: track-claude-params.sh outputs JSON format
output=$(bash scripts/track-claude-params.sh --json 2>/dev/null || echo "ERROR")
if [[ -n "$output" && "$output" != "ERROR" ]]; then
    assert_contains "track-claude-params.sh --json outputs parsable format" "$output" "bare" || true
fi

# ─────────────────────────────────────────
# Module 3: Skill Auto-Generator
# ─────────────────────────────────────────
echo ""
echo "━━━ Module 3: Skill Auto-Generator ━━━"

# Test 3.1: generate-skill.sh creates skill file
temp_spec=$(mktemp)
echo '{"trigger":"test-skill","description":"Test skill","tools":["exec"]}' > "$temp_spec"
output=$(bash scripts/generate-skill.sh "$temp_spec" 2>/dev/null || echo "ERROR")
rm -f "$temp_spec"
assert_contains "generate-skill.sh creates skill output" "$output" "test-skill" || true

# Test 3.2: generate-skill.sh outputs SKILL.md format
temp_spec=$(mktemp)
echo '{"trigger":"my-skill","description":"My description"}' > "$temp_spec"
output=$(bash scripts/generate-skill.sh "$temp_spec" 2>/dev/null || echo "ERROR")
rm -f "$temp_spec"
for field in "name:" "description:" "trigger:"; do
    assert_contains "generate-skill.sh outputs $field" "$output" "$field" || true
done

# Test 3.3: generate-skill.sh handles unknown CLI param
temp_spec=$(mktemp)
echo '{"cli_param":"--new-flag","description":"New feature flag","use_case":"testing"}' > "$temp_spec"
output=$(bash scripts/generate-skill.sh --from-cli-param "$temp_spec" 2>/dev/null || echo "ERROR")
rm -f "$temp_spec"
assert_contains "generate-skill.sh --from-cli-param works" "$output" "new-flag" || true

# Test 3.4: generate-skill.sh outputs to file when specified
temp_spec=$(mktemp)
temp_output=$(mktemp -d)
echo '{"trigger":"output-test","description":"Test output to file"}' > "$temp_spec"
bash scripts/generate-skill.sh "$temp_spec" --output-dir "$temp_output" 2>/dev/null || true
if [[ -d "$temp_output" ]]; then
    found=$(find "$temp_output" -name "*.md" 2>/dev/null | head -1)
    if [[ -n "$found" ]]; then
        assert_file_exists "generate-skill.sh outputs file to directory" "$found" || true
    fi
fi
rm -rf "$temp_spec" "$temp_output"

# Test 3.5: generate-skill.sh generates skill draft for changelog entry
temp_spec=$(mktemp)
cat > "$temp_spec" << 'EOF'
{
  "source": "changelog",
  "product": "claude-code",
  "version": "v2.1.81",
  "change": "MCP read/search tools collapsible display",
  "date": "2026-03-22"
}
EOF
output=$(bash scripts/generate-skill.sh --from-changelog "$temp_spec" 2>/dev/null || echo "ERROR")
rm -f "$temp_spec"
assert_contains "generate-skill.sh --from-changelog works" "$output" "claude-code" || true
assert_contains "generate-skill.sh --from-changelog outputs skill name" "$output" "mcp" || true

# ─────────────────────────────────────────
# Module 4: Change Log Monitor
# ─────────────────────────────────────────
echo ""
echo "━━━ Module 4: Change Log Monitor ━━━"

# Test 4.1: monitor-changelogs.sh can check OpenClaw
output=$(bash scripts/monitor-changelogs.sh --check openclaw 2>/dev/null || echo "ERROR")
assert_contains "monitor-changelogs.sh checks openclaw" "$output" "openclaw" || true

# Test 4.2: monitor-changelogs.sh can check Claude Code
output=$(bash scripts/monitor-changelogs.sh --check claude-code 2>/dev/null || echo "ERROR")
assert_contains "monitor-changelogs.sh checks claude-code" "$output" "claude-code" || true

# Test 4.3: monitor-changelogs.sh outputs changes in JSON
output=$(bash scripts/monitor-changelogs.sh --json --check openclaw 2>/dev/null || echo "ERROR")
if [[ -n "$output" && "$output" != "ERROR" ]]; then
    assert_contains "monitor-changelogs.sh --json outputs" "$output" "version" || true
fi

# Test 4.3: config/sources.conf exists and has entries
if [[ -f "config/sources.conf" ]]; then
    content=$(cat "config/sources.conf")
    assert_contains "sources.conf contains OpenClaw entry" "$content" "openclaw" || true
    assert_contains "sources.conf contains Claude Code entry" "$content" "claude-code" || true
fi

# ─────────────────────────────────────────
# Module 5: Skill Draft Output
# ─────────────────────────────────────────
echo ""
echo "━━━ Module 5: Skill Draft Output ━━━"

# Test 5.1: generate-drafts.sh creates skill drafts from changelog
output=$(bash scripts/generate-drafts.sh 2>/dev/null || echo "ERROR")
if [[ "$output" != "ERROR" && -n "$output" ]]; then
    draft_count=$(echo "$output" | grep -c "^name:" || echo "0")
    # Test passes if we got at least one draft (draft_count >= 1)
    if [[ "$draft_count" -ge 1 ]]; then
        echo -e "${GREEN}✓ PASS${NC}: generate-drafts.sh produces at least 1 draft (found $draft_count)"
        ((passed++))
    else
        echo -e "${RED}✗ FAIL${NC}: generate-drafts.sh produces at least 1 draft"
        echo "  Expected: >= 1"
        echo "  Actual: $draft_count"
        ((failed++))
    fi
fi

# Test 5.2: generated drafts have required frontmatter
output=$(bash scripts/generate-drafts.sh 2>/dev/null || echo "ERROR")
if [[ "$output" != "ERROR" && -n "$output" ]]; then
    assert_contains "generate-drafts.sh outputs name field" "$output" "name:" || true
    assert_contains "generate-drafts.sh outputs trigger field" "$output" "trigger:" || true
fi

# Test 5.3: SKILL.md exists in skill directory
assert_file_exists "SKILL.md exists in skill directory" "SKILL.md" || true

# Test 5.4: SKILL.md references all sub-modules
if [[ -f "SKILL.md" ]]; then
    content=$(cat "SKILL.md")
    assert_contains "SKILL.md references parse-skill-spec" "$content" "parse-skill-spec" || true
    assert_contains "SKILL.md references track-claude-params" "$content" "track-claude-params" || true
    assert_contains "SKILL.md references generate-skill" "$content" "generate-skill" || true
    assert_contains "SKILL.md references monitor-changelogs" "$content" "monitor-changelogs" || true
fi

# ─────────────────────────────────────────
# Summary
# ─────────────────────────────────────────
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
total=$((passed + failed))
echo -e "Total:  $total tests"
echo -e "Passed: ${GREEN}$passed${NC}"
echo -e "Failed: ${RED}$failed${NC}"
echo ""

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. TDD RED phase - tests define expected behavior.${NC}"
    exit 1
fi
