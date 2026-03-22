#!/bin/bash
# AI Coding Fullstack Supervisor v8
# 使用 github-utils.sh 公共函数库

source "$(dirname "$0")/github-utils.sh"

LOG_FILE="$HOME/Projects/ai-coding-fullstack/logs/supervisor.log"
PROJECT_DIR="$HOME/Projects/ai-coding-fullstack"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" 2>/dev/null || echo "$*"; }

main() {
    log "=== AI Coding Supervisor v8 ==="
    
    # 1. 检查当前状态
    local state=$(get_current_state)
    local current_issue=$(get_current_issue)
    
    log "当前状态: state=$state, current_issue=$current_issue"
    
    # 2. 如果有正在处理的 Issue，检查 PR
    if [[ "$state" == "working" && "$current_issue" != "null" ]]; then
        log "Issue #$current_issue 正在处理中"
        
        local pr_status=$(check_pr_status "$current_issue")
        log "PR 状态: $pr_status"
        
        case "$pr_status" in
            merged)
                log "PR 已合并，更新状态"
                update_state "idle" "null" "$current_issue"
                ;;
            open)
                log "PR 仍有 open，跳过"
                ;;
            closed|none)
                log "PR 已关闭或不存在，重置"
                update_state "idle" "null" "$current_issue"
                ;;
        esac
        return 0
    fi
    
    # 3. 检查是否有未完成的分支
    local pending_branch=$(get_pending_branch)
    if [[ -n "$pending_branch" ]]; then
        log "检测到未完成分支: $pending_branch"
        local branch_issue=$(echo "$pending_branch" | grep -oE "[0-9]+" | tail -1)
        if [[ -n "$branch_issue" ]]; then
            update_state "working" "$branch_issue" "null"
        fi
        log "等待分支完成..."
        return 0
    fi
    
    # 4. 选择下一个 Issue
    local next_issue=$(select_next_issue)
    if [[ -z "$next_issue" ]]; then
        log "没有待处理的 Issue"
        update_state "idle" "null" "null"
        return 0
    fi
    
    # 5. 开始处理
    log "选取 Issue #$next_issue"
    update_state "working" "$next_issue" "null"
    
    local title=$(gh issue view "$next_issue" --json title --jq '.title' 2>/dev/null || echo "Issue $next_issue")
    log "标题: $title"
    
    # 6. TDD RED - 创建测试
    log "TDD RED: 创建测试..."
    mkdir -p "$PROJECT_DIR/modules/core/tests"
    cat > "$PROJECT_DIR/modules/core/tests/test_$next_issue.sh" << TESTEOF
#!/bin/bash
echo "Test for Issue #$next_issue: $title"
TESTEOF
    chmod +x "$PROJECT_DIR/modules/core/tests/test_$next_issue.sh"
    
    # 7. 分支操作
    create_branch_and_push "$next_issue" || return 1
    commit_changes "feat #$next_issue: Start $title"
    
    # 8. 推送分支
    log "推送分支..."
    push_branch "feature/issue-$next_issue"
    
    # 9. 创建 PR
    log "创建 PR..."
    create_pr "$next_issue" "$title"
    
    log "=== Issue #$next_issue 处理完成 ==="
}

main "$@"
