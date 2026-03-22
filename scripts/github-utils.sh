#!/bin/bash
# GitHub 操作公共函数库

PROJECT_DIR="$HOME/Projects/ai-coding-fullstack"
LOG_FILE="$HOME/Projects/ai-coding-fullstack/logs/supervisor.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" 2>/dev/null || echo "$*"; }

# 带超时的执行 (兼容 macOS)
run_with_timeout() {
    local seconds="$1"
    shift
    local cmd="$*"
    # macOS 没有 timeout，用 perl 实现
    if command -v timeout &>/dev/null; then
        timeout "$seconds" $cmd
    else
        perl -e 'alarm shift; exec @ARGV' "$seconds" $cmd
    fi
}

# 检查 PR 状态
check_pr_status() {
    local issue_num="$1"
    local branch_name="feature/issue-$issue_num"
    local count
    
    count=$(gh pr list --head "$branch_name" --state merged 2>/dev/null | wc -l | tr -d ' ')
    [[ -z "$count" ]] && count=0
    if [[ "$count" -gt 0 ]]; then
        echo "merged"
        return
    fi
    
    count=$(gh pr list --head "$branch_name" --state open 2>/dev/null | wc -l | tr -d ' ')
    [[ -z "$count" ]] && count=0
    if [[ "$count" -gt 0 ]]; then
        echo "open"
        return
    fi
    
    count=$(gh pr list --head "$branch_name" --state closed 2>/dev/null | wc -l | tr -d ' ')
    [[ -z "$count" ]] && count=0
    if [[ "$count" -gt 0 ]]; then
        echo "closed"
        return
    fi
    
    echo "none"
}

# 获取当前处理的 Issue
get_current_issue() {
    local session_file="$PROJECT_DIR/.supervisor/session"
    if [[ -f "$session_file" ]]; then
        python3 -c "import sys,json; print(json.load(open('$session_file')).get('current_issue', 'null'))" 2>/dev/null || echo "null"
    else
        echo "null"
    fi
}

# 获取当前状态
get_current_state() {
    local session_file="$PROJECT_DIR/.supervisor/session"
    if [[ -f "$session_file" ]]; then
        python3 -c "import sys,json; print(json.load(open('$session_file')).get('state', 'idle'))" 2>/dev/null || echo "idle"
    else
        echo "idle"
    fi
}

# 更新状态
update_state() {
    local state="$1" current_issue="$2" last_issue="$3"
    local session_file="$PROJECT_DIR/.supervisor/session"
    mkdir -p "$(dirname "$session_file")"
    
    [[ "$current_issue" == "null" ]] && current_issue="null" || current_issue=""$current_issue""
    [[ "$last_issue" == "null" ]] && last_issue="null" || last_issue=""$last_issue""
    
    cat > "$session_file" << EOF
{
    "state": "$state",
    "current_issue": $current_issue,
    "last_issue": $last_issue,
    "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    log "状态更新: state=$state, current=$current_issue"
}

# 检查是否有未完成的分支
get_pending_branch() {
    run_with_timeout 10 git -C "$PROJECT_DIR" branch -r 2>/dev/null | grep "feature/" | grep -v "feature/issue-1" | grep -v "feature/issue-None" | head -1 | sed 's/.*origin\///' | tr -d ' '
}

# 选择下一个 Issue
select_next_issue() {
    cd "$PROJECT_DIR"
    
    # 获取当前处理的 issue
    local current=$(get_current_issue)
    [[ "$current" == "null" ]] && current=""
    
    # 获取所有 open issues
    local issues=$(gh issue list --state open --limit 20 2>/dev/null)
    
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local num=$(echo "$line" | awk '{print $1}')
        [[ -n "$current" && "$num" == "$current" ]] && continue
        
        # 检查是否有对应的 PR
        local pr_status=$(check_pr_status "$num")
        if [[ "$pr_status" == "none" ]]; then
            echo "$num"
            return 0
        fi
        log "Issue #$num 已有 PR ($pr_status)，跳过"
    done <<< "$issues"
    
    return 1
}

# 创建分支并推送
create_branch_and_push() {
    local issue_num="$1"
    local branch_name="feature/issue-$issue_num"
    
    cd "$PROJECT_DIR"
    
    run_with_timeout 10 git pull origin main 2>/dev/null || true
    
    if git rev-parse --verify "$branch_name" 2>/dev/null; then
        git checkout "$branch_name" 2>/dev/null || true
        log "切换到已有分支: $branch_name"
    else
        git checkout -b "$branch_name" 2>/dev/null || {
            git checkout -b "$branch_name" --track "origin/$branch_name" 2>/dev/null || {
                log "分支创建失败"
                return 1
            }
        }
        log "创建新分支: $branch_name"
    fi
    
    return 0
}

# 推送分支
push_branch() {
    local branch_name="$1"
    cd "$PROJECT_DIR"
    
    run_with_timeout 30 git push -u origin "$branch_name" 2>&1 | while read line; do
        log "  $line"
    done
}

# 创建 PR
create_pr() {
    local issue_num="$1" title="$2"
    cd "$PROJECT_DIR"
    
    gh pr create         --title "feat #$issue_num: $title"         --body "Closes #$issue_num"         --base main 2>&1 | while read line; do
        log "  $line"
    done
}

# 提交更改
commit_changes() {
    local message="$1"
    cd "$PROJECT_DIR"
    
    git add .
    git commit -m "$message" 2>/dev/null || log "没有需要提交的内容"
}
