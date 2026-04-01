#!/bin/bash
PROJECT_DIR="$HOME/Projects/ai-coding-fullstack"
LOG_FILE="$HOME/Projects/ai-coding-fullstack/logs/supervisor.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }
run_with_timeout() {
    local s=$1; shift
    if command -v timeout &>/dev/null; then timeout "$s" $@
    else perl -e 'alarm shift; exec @ARGV' "$s" $@; fi
}
check_pr_status() {
    local n=$1
    local bn="feature/issue-$n"
    local c
    cd "$PROJECT_DIR"
    c=$(gh pr list --head "$bn" --state merged 2>/dev/null | wc -l | tr -d ' ')
    [[ -z "$c" ]] && c=0; [[ "$c" -gt 0 ]] && { echo merged; return; }
    c=$(gh pr list --head "$bn" --state open 2>/dev/null | wc -l | tr -d ' ')
    [[ -z "$c" ]] && c=0; [[ "$c" -gt 0 ]] && { echo open; return; }
    echo none
}
branch_exists() {
    local n=$1
    local bn="feature/issue-$n"
    cd "$PROJECT_DIR"
    run_with_timeout 10 git -C "$PROJECT_DIR" ls-remote --heads origin "$bn" 2>/dev/null | grep -q . && return 0
    git -C "$PROJECT_DIR" rev-parse --verify "$bn" >/dev/null 2>&1 && return 0
    return 1
}
get_current_issue() {
    local f="$PROJECT_DIR/.supervisor/session"
    [[ -f "$f" ]] && jq -r '.current_issue // "null"' "$f" 2>/dev/null || echo "null"
}
get_current_state() {
    local f="$PROJECT_DIR/.supervisor/session"
    [[ -f "$f" ]] && python3 -c "import sys,json; print(json.load(open('$f')).get('state','idle'))" 2>/dev/null || echo idle
}
update_state() {
    local s=$1 i=$2 l=$3
    local f="$PROJECT_DIR/.supervisor/session"
    mkdir -p "$(dirname "$f")"
    [[ "$i" == null ]] && i=null || i="\"$i\""
    [[ "$l" == null ]] && l=null || l="\"$l\""
    cat > "$f" << EOF
{"state": "$s", "current_issue": $i, "last_issue": $l, "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF
    log "状态更新: state=$s, current=$i"
}
get_pending_branch() {
    local branches=$(run_with_timeout 10 git -C "$PROJECT_DIR" branch -r 2>/dev/null | grep "feature/" | grep -v "feature/issue-1" | grep -v "feature/issue-None")
    [[ -z "$branches" ]] && return 1
    while IFS= read -r branch; do
        local bn=$(echo "$branch" | sed 's/.*origin\///' | tr -d ' ')
        [[ -z "$bn" ]] && continue
        local issue_num=$(echo "$bn" | grep -oE "[0-9]+" | tail -1)
        [[ -z "$issue_num" ]] && continue
        # Check if there's an open PR for this branch
        cd "$PROJECT_DIR"
        local pr_count=$(gh pr list --head "$bn" --state open 2>/dev/null | wc -l | tr -d ' ')
        [[ "$pr_count" -gt 0 ]] && continue
        echo "$bn"
        return 0
    done <<< "$branches"
    return 1
}
select_next_issue() {
    cd "$PROJECT_DIR"
    local cur=$(get_current_issue); [[ "$cur" == null ]] && cur=""
    local last=$(python3 -c "import sys,json; f=open('$PROJECT_DIR/.supervisor/session'); print(json.load(f).get('last_issue','null'))" 2>/dev/null || echo null)
    [[ "$last" == null ]] && last=""
    local issues=$(gh issue list --state open --limit 20 2>/dev/null)
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local num=$(echo "$line" | awk '{print $1}')
        [[ -z "$num" ]] && continue
        [[ -n "$cur" && "$num" == "$cur" ]] && continue
        [[ -n "$last" && "$num" == "$last" ]] && continue
        local pr=$(check_pr_status "$num")
        if [[ "$pr" != none ]]; then log "Issue #$num 已有 PR ($pr)，跳过"; continue; fi
        if branch_exists "$num"; then log "Issue #$num 有分支但无 PR，继续"; fi
        echo "$num"; return 0
    done <<< "$issues"
    return 1
}
create_branch() {
    local n=$1
    local bn="feature/issue-$n"
    cd "$PROJECT_DIR"
    run_with_timeout 10 git pull origin main 2>/dev/null || true
    if git rev-parse --verify "$bn" >/dev/null 2>&1; then
        git checkout "$bn" 2>/dev/null || true; log "切换到已有分支: $bn"
    else
        git checkout -b "$bn" 2>/dev/null || { git checkout -b "$bn" --track "origin/$bn" 2>/dev/null || { log "分支创建失败"; return 1; }; }; log "创建新分支: $bn"
    fi; return 0
}
push_branch() {
    local bn=$1; cd "$PROJECT_DIR"
    log "正在推送分支..."
    if run_with_timeout 30 git push -u origin "$bn" 2>&1; then log "推送成功"; return 0
    else log "推送失败"; return 1; fi
}
create_pr() {
    local n=$1 t=$2 bn=$3; cd "$PROJECT_DIR"
    local url=$(gh pr create --title "feat #$n: $t" --body "Closes #$n" --head "$bn" --base main 2>&1)
    if [[ "$url" == http* ]]; then log "PR 创建成功: $url"
    else log "PR 创建结果: $url"; fi
}
commit_changes() {
    local m=$1; cd "$PROJECT_DIR"
    git add .
    if git commit -m "$m" 2>&1 | grep -q "nothing to commit"; then log "没有需要提交的内容"
    else log "提交成功"; fi
}
