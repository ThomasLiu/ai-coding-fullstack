#!/bin/bash
set -e

# ============================================================
# TDD RED 验收测试：TITLE_REPLACED / BODY_REPLACED
# 预期：功能未实现 → FAIL (exit 1)
# 功能正确实现后 → PASS (exit 0)
# ============================================================

# ---- 辅助函数 ----
log_info()  { echo "[INFO]  $1"; }
log_pass()  { echo "[PASS]  $1"; }
log_fail()  { echo "[FAIL]  $1"; }

# ---- 读取 Issue 元信息 ----
ISSUE_TITLE="TITLE_REPLACED"
ISSUE_BODY="BODY_REPLACED"

EXPECTED_TITLE="<实际 Issue 标题>"
EXPECTED_BODY="<实际 Issue 正文内容>"

# ============================================================
# 测试用例 1：Issue 标题必须是真实内容，不能是占位符
# ============================================================
test_title_not_placeholder() {
  log_info "检查 Issue 标题是否为占位符..."

  if [[ "$ISSUE_TITLE" == "TITLE_REPLACED" ]]; then
    log_fail "Issue 标题仍为占位符 'TITLE_REPLACED'，功能未实现"
    return 1
  fi

  if [[ -z "$ISSUE_TITLE" ]]; then
    log_fail "Issue 标题为空，功能未实现"
    return 1
  fi

  log_pass "Issue 标题已替换为真实内容: '$ISSUE_TITLE'"
  return 0
}

# ============================================================
# 测试用例 2：Issue 正文必须是真实内容，不能是占位符
# ============================================================
test_body_not_placeholder() {
  log_info "检查 Issue 正文是否为占位符..."

  if [[ "$ISSUE_BODY" == "BODY_REPLACED" ]]; then
    log_fail "Issue 正文仍为占位符 'BODY_REPLACED'，功能未实现"
    return 1
  fi

  if [[ -z "$ISSUE_BODY" ]]; then
    log_fail "Issue 正文为空，功能未实现"
    return 1
  fi

  log_pass "Issue 正文已替换为真实内容 (长度: ${#ISSUE_BODY} 字符)"
  return 0
}

# ============================================================
# 测试用例 3：标题和正文不能相同（验证非模板复制错误）
# ============================================================
test_title_body_different() {
  log_info "检查标题与正文是否不同..."

  if [[ "$ISSUE_TITLE" == "$ISSUE_BODY" ]]; then
    log_fail "标题与正文内容完全相同，疑似占位符未正确替换"
    return 1
  fi

  log_pass "标题与正文内容不同，内容已正确填充"
  return 0
}

# ============================================================
# 汇总测试结果
# ============================================================
FAILED=0

test_title_not_placeholder  || FAILED=$((FAILED + 1))
test_body_not_placeholder   || FAILED=$((FAILED + 1))
test_title_body_different   || FAILED=$((FAILED + 1))

echo ""
echo "========================================"
if [[ $FAILED -eq 0 ]]; then
  log_pass "所有验收测试通过 ✓"
  echo "========================================"
  exit 0
else
  log_fail "共 $FAILED 项测试失败 ✗"
  log_fail "Issue 内容仍为占位符，功能尚未实现"
  echo "========================================"
  exit 1
fi
