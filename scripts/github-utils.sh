#!/bin/bash
# GitHub 操作公共函数库

PROJECT_DIR="$HOME/Projects/ai-coding-fullstack"
LOG_FILE="$HOME/Projects/ai-coding-fullstack/logs/supervisor.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

run_with_timeout() {
    local seconds="$1"
    shift
    if command -v timeout &>/dev/null; then
        timeout "$seconds" $@
    else
        perl -e 'alarm shift; exec @ARGV' "$seconds" $@
    fi
}

check_pr_status() {
    local issue_num="$1"
    local branch_name="feature/issue-$issue_num"
    local count
    
    count=$(gh pr list --head "$branch_name" --state merged 2>/dev/null | wc -l | tr -d ' ')
    [[ -z "$count" ]] && count=0
    [[ "$count" -gt 0 ]] && { echo "merged"; return; }
    
    count=$(gh pr list --head "$branch_name" --state open 2>/dev/null | wc -l | tr -d ' ')
    [[ -z "$count" ]] && count=0
    [[ "$count" -gt 0 ]] && { echo "open"; return; }
    
    echo "none"
}

branch_exists() {
    local issue_num="$1"
    local branch_name="feature/issue-$issue_num"
    
    # 检查远程分支
    run_with_timeout 10 git -C "$PROJECT_DIR" ls-remote --heads origin "$branch_name" 2>/dev/null | grep -q . && return 0
    
    # 检查本地分支 (不要输出 commit hash)
    git -C "$PROJECT_DIR" rev-parse --verify "$branch_name" >/dev/null 2>&1 && return 0
    
    return 1
}

get_current_issue() {
    local session_file="$PROJECT_DIR/.supervisor/session"
    [[ -f "$session_file" ]] && python3 -c "import sys,json; print(json.load(open('$session_file')).get('current_issue', 'null'))" 2>/dev/null || echo "null"
}

get_current_state() {
    local session_file="$PROJECT_DIR/.supervisor/session"
    [[ -f "$session_file" ]] && python3 -c "import sys,json; print(json.load(open('$session_file')).get('state', 'idle'))" 2>/dev/null || echo "idle"
}

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

get_pending_branch() {
    run_with_timeout 10 git -C "$PROJECT_DIR" branch -r 2>/dev/null | grep "feature/" | grep -v "feature/issue-1" | grep -v "feature/issue-None" | head -1 | sed 's/.*origin\///' | tr -d ' '
}

select_next_issue() {
    cd "$PROJECT_DIR"
    
    local current=$(get_current_issue)
    [[ "$current" == "null" ]] && current=""
    
    local issues=$(gh issue list --state open --limit 20 2>/dev/null)
    
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local num=$(echo "$line" | awk '{print $1}')
        [[ -z "$num" ]] && continue
        [[ -n "$current" && "$num" == "$current" ]] && continue
        
        local pr_status=$(check_pr_status "$num")
        if [[ "$pr_status" != "none" ]]; then
            log "Issue #$num 已有 PR ($pr_status)，跳过"
            continue
        fi
        
        if branch_exists "$num"; then
            log "Issue #$num 有分支但无 PR，继续处理"
        fi
        
        echo "$num"
        return 0
    done <<< "$issues"
    
    return 1
}

create_branch() {
    local issue_num="$1"
    local branch_name="feature/issue-$issue_num"
    
    cd "$PROJECT_DIR"
    
    run_with_timeout 10 git pull origin main 2>/dev/null || true
    
    if git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
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

push_branch() {
    local branch_name="$1"
    cd "$PROJECT_DIR"
    
    local git_url="https://$(gh auth token)@github.com/ThomasLiu/ai-coding-fullstack.git"
    run_with_timeout 30 git push -u "$git_url" "$branch_name" 2>&1 | while read line; do
        log "  $line"
    done
}

create_pr() {
    local issue_num="$1" title="$2" branch_name="$3"
    cd "$PROJECT_DIR"
    
    gh pr create         --title "feat #$issue_num: $title"         --body "Closes #$issue_num"         --head "$branch_name"         --base main 2>&1 | while read line; do
        log "  $line"
    done
}

commit_changes() {
    local message="$1"
    cd "$PROJECT_DIR"
    
    git add .
    git commit -m "$message" 2>/dev/null || log "没有需要提交的内容"
}
