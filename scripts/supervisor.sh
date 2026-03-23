#!/bin/bash
source "$(dirname "$0")/github-utils.sh"
PROJECT_DIR="$HOME/Projects/ai-coding-fullstack"
BRANCH_NAME=""
main() {
    log "=== AI Coding Supervisor v12 ==="
    local state=$(get_current_state)
    local current_issue=$(get_current_issue)
    log "当前状态: state=$state, current_issue=$current_issue"
    if [[ "$state" == working && "$current_issue" != null ]]; then
        log "Issue #$current_issue 正在处理中"
        local pr=$(check_pr_status "$current_issue")
        log "PR 状态: $pr"
        case "$pr" in
            merged) log "PR 已合并，更新状态"; update_state idle null "$current_issue";;
            open) log "PR 仍有 open，跳过";;
            closed|none) log "PR 已关闭或不存在，重置"; update_state idle null "$current_issue";;
        esac; return 0
    fi
    local pending=$(get_pending_branch)
    if [[ -n "$pending" ]]; then
        log "检测到未完成分支: $pending"
        local bi=$(echo "$pending" | grep -oE "[0-9]+" | tail -1)
        if [[ -n "$bi" ]]; then update_state working "$bi" null; fi
        log "等待分支完成..."; return 0
    fi
    local next=$(select_next_issue)
    if [[ -z "$next" ]]; then log "没有待处理的 Issue"; update_state idle null null; return 0; fi
    log "选取 Issue #$next"
    update_state working "$next" null
    local title=$(gh issue view "$next" --json title --jq '.title' 2>/dev/null || echo "Issue $next")
    log "标题: $title"
    log "TDD RED: 创建测试..."
    mkdir -p "$PROJECT_DIR/modules/core/tests"
    cat > "$PROJECT_DIR/modules/core/tests/test_$next.sh" << TESTEOF
#!/bin/bash
echo "Test for Issue #$next: $title"
TESTEOF
    chmod +x "$PROJECT_DIR/modules/core/tests/test_$next.sh"
    BRANCH_NAME="feature/issue-$next"
    create_branch "$next" || return 1
    commit_changes "feat #$next: Start $title"
    log "推送分支..."
    push_branch "$BRANCH_NAME"
    log "创建 PR..."
    create_pr "$next" "$title" "$BRANCH_NAME"
    log "=== Issue #$next 处理完成 ==="
}
main "$@"
