#!/bin/bash
# 最终评审脚本
# 被 supervisor_v2.sh 调用

source "$(dirname "$0")/../github-utils.sh"

PROJECT_DIR="$HOME/Projects/ai-coding-fullstack"

# 检查某阶段是否完成
check_stage_complete() {
    local issue_num=$1
    local stage=$2
    
    cd "$PROJECT_DIR"
    local count=$(gh issue comments "$issue_num" 2>/dev/null | \
        grep -c "Status.*$stage.*done\|$stage.*完成\|$stage.*✅" || echo 0)
    
    [[ $count -gt 0 ]]
}

# 运行验收测试
run_acceptance_tests() {
    local issue_num=$1
    local test_file="$PROJECT_DIR/modules/core/tests/test_$issue_num.sh"
    
    if [[ ! -f "$test_file" ]]; then
        echo "❌ 验收测试文件不存在: $test_file"
        return 1
    fi
    
    bash "$test_file"
}

# 检查 CI 状态
check_ci_status() {
    local pr_num=$1
    
    cd "$PROJECT_DIR"
    local checks=$(gh pr checks "$pr_num" --json status,conclusion 2>/dev/null)
    
    # 检查是否有失败的 check
    local failed=$(echo "$checks" | jq -r '.[] | select(.conclusion=="failure") | .id' 2>/dev/null | wc -l)
    [[ $failed -eq 0 ]]
}

# 检查是否可以合并
check_mergeable() {
    local pr_num=$1
    
    cd "$PROJECT_DIR"
    local mergeable=$(gh pr view "$pr_num" --json mergeable --jq '.mergeable' 2>/dev/null)
    [[ "$mergeable" == "true" ]]
}

# 检查评审记录
check_review_comments() {
    local issue_num=$1
    
    cd "$PROJECT_DIR"
    local count=$(gh issue comments "$issue_num" 2>/dev/null | \
        grep -c "验收清单评审\|技术方案评审\|Design Review\|Checklist Review" || echo 0)
    
    [[ $count -ge 2 ]]
}

# 获取 Issue 优先级
get_issue_priority() {
    local issue_num=$1
    
    cd "$PROJECT_DIR"
    gh issue view "$issue_num" --json labels --jq '.labels[] | select(.name | startswith("P")) | .name' 2>/dev/null | \
        head -1 || echo "P3"
}

# 获取 PR 编号
get_pr_number() {
    local issue_num=$1
    
    cd "$PROJECT_DIR"
    gh pr list --head "feature/issue-$issue_num" --state open --json number --jq '.[0].number' 2>/dev/null || echo ""
}

# 请求人工确认
request_human_review() {
    local issue_num=$1
    local pr_num=$2
    
    cd "$PROJECT_DIR"
    
    gh issue comment "$issue_num" --body "
## ⚠️ 最终评审待确认

Issue #$issue_num (PR #$pr_num) 已完成 TDD 流程，请确认是否可以合并。

### 合并前确认清单

- [ ] P0 验收清单满足
- [ ] P1 验收清单满足
- [ ] 无安全问题
- [ ] 无 blocking issues

### 操作

请回复以下任一标签：
- \`LGTM\` - 可以合并
- \`NEEDS_CHANGE\` - 需要修改，说明原因
- \`BLOCKING\` - 阻塞，明确问题

---
评审人: @ThomasLiu
" 2>/dev/null
    
    echo "已请求人工确认 Issue #$issue_num"
}

# 自动合并
auto_merge() {
    local pr_num=$1
    local issue_num=$2
    
    cd "$PROJECT_DIR"
    
    if gh pr merge "$pr_num" --admin --merge --body "Auto-merged by AI Coding Fullstack Supervisor v2" 2>/dev/null; then
        echo "✅ 合并成功 PR #$pr_num"
        
        # 关闭 Issue
        gh issue close "$issue_num" --comment "✅ 已合并" 2>/dev/null || true
        
        return 0
    else
        echo "❌ 合并失败 PR #$pr_num"
        return 1
    fi
}

# 最终评审主函数
final_review() {
    local issue_num=$1
    local pr_num=$(get_pr_number "$issue_num")
    
    [[ -z "$pr_num" ]] && { echo "❌ Issue #$issue_num 没有 PR"; return 1; }
    
    echo "=== 最终评审: Issue #$issue_num (PR #$pr_num) ==="
    
    # 检查阶段完成状态
    local stages=("checklist-review" "red" "design-review" "green" "refactor")
    for stage in "${stages[@]}"; do
        if ! check_stage_complete "$issue_num" "$stage"; then
            echo "❌ 阶段 $stage 未完成"
            return 1
        fi
        echo "  ✅ 阶段 $stage 完成"
    done
    
    # 运行验收测试
    echo "运行验收测试..."
    if ! run_acceptance_tests "$issue_num"; then
        echo "❌ 验收测试失败"
        return 1
    fi
    echo "  ✅ 验收测试通过"
    
    # 检查 CI 状态
    echo "检查 CI 状态..."
    if ! check_ci_status "$pr_num"; then
        echo "❌ CI 未通过"
        return 1
    fi
    echo "  ✅ CI 通过"
    
    # 检查合并冲突
    echo "检查合并冲突..."
    if ! check_mergeable "$pr_num"; then
        echo "❌ 有合并冲突"
        return 1
    fi
    echo "  ✅ 无合并冲突"
    
    # 检查评审记录
    echo "检查评审记录..."
    if ! check_review_comments "$issue_num"; then
        echo "❌ 评审记录不足"
        return 1
    fi
    echo "  ✅ 评审记录完整"
    
    # 根据优先级决策
    local priority=$(get_issue_priority "$issue_num")
    echo "Issue 优先级: $priority"
    
    case "$priority" in
        P0|P1)
            echo "⚠️ P0/P1 需要人工确认"
            request_human_review "$issue_num" "$pr_num"
            ;;
        P2|P3|*)
            echo "💚 P2/P3 自动合并"
            auto_merge "$pr_num" "$issue_num"
            ;;
    esac
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    issue_num=$1
    [[ -z "$issue_num" ]] && { echo "用法: $0 <issue_num>"; exit 1; }
    final_review "$issue_num"
fi
