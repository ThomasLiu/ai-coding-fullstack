#!/bin/bash
# AI Coding Fullstack Supervisor - TDD Loop

PROJECT_DIR="$HOME/Projects/ai-coding-fullstack"
SESSION_FILE="$PROJECT_DIR/.supervisor/session"

log() { echo "[$(date +%H:%M:%S)] $*" ; }

get_state() {
    [[ -f "$SESSION_FILE" ]] && jq -r ".state // \"idle\"" "$SESSION_FILE" 2>/dev/null || echo "idle"
}

get_current_issue() {
    [[ -f "$SESSION_FILE" ]] && jq -r ".current_issue // \"null\"" "$SESSION_FILE" 2>/dev/null || echo "null"
}

update_session() {
    local state="$1" issue="$2" stage="${3:-checklist-review}"
    echo "{\"state\": \"$state\",\"current_issue\": $issue,\"stage\": \"$stage\"}" > "$SESSION_FILE"
}

post_to_github() {
    local issue_num=$1
    local output_file="$PROJECT_DIR/.supervisor/output_${issue_num}.txt"
    
    if [[ ! -f "$output_file" || ! -s "$output_file" ]]; then
        output_file="$PROJECT_DIR/.supervisor/output_red_${issue_num}.txt"
    fi
    
    if [[ ! -f "$output_file" || ! -s "$output_file" ]]; then
        log "Error: 没有输出文件 for #${issue_num}"
        return 1
    fi
    
    log "发帖到 Issue #${issue_num}"
    
    local body=$(awk "/^\`\`\`markdown\$/,/^\`\`\`\$/" "$output_file" | sed "1d;\$d")
    
    if [[ -z "$body" ]]; then
        body=$(cat "$output_file")
    fi
    
    gh issue comment "$issue_num" --body "$body"
    log "已发帖到 Issue #${issue_num}"
    
    rm -f "$output_file"
    rm -f "$PROJECT_DIR/.supervisor/pending_issue.txt"
}

select_next_issue() {
    cd "$PROJECT_DIR"
    local issues=$(gh issue list --state open --limit 80 --json number --jq ".[].number" 2>/dev/null)
    
    for num in $issues; do
        local pr_status=$(gh pr list --head "feature-issue-${num}" --state all --json number --jq ".[0].number" 2>/dev/null || echo "")
        if [[ -z "$pr_status" ]]; then
            echo "$num"
            return 0
        fi
    done
    return 1
}

create_pr() {
    local issue_num=$1
    cd "$PROJECT_DIR"
    
    local title=$(gh issue view "$issue_num" --json title --jq ".title")
    local branch_name="feature-issue-${issue_num}"
    
    log "创建 PR: Issue #${issue_num}"
    
    git fetch origin main 2>/dev/null || true
    git checkout -b "$branch_name" origin/main 2>/dev/null || git checkout "$branch_name" 2>/dev/null || true
    git commit --allow-empty -m "feat #${issue_num}: ${title}"
    git push -u origin "$branch_name" 2>/dev/null || true
    gh pr create --title "feat #${issue_num}: ${title}" --body "Feature branch for Issue #${issue_num}" 2>/dev/null || true
    
    log "PR 创建完成"
}

call_claude_code_checklist() {
    local issue_num=$1
    cd "$PROJECT_DIR"
    
    local title=$(gh issue view "$issue_num" --json title --jq ".title")
    local body=$(gh issue view "$issue_num" --json body --jq ".body")
    local output_file="$PROJECT_DIR/.supervisor/output_${issue_num}.txt"
    local prompt_file="/tmp/claude_prompt_${issue_num}.txt"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # 清理旧输出（防止中断后残留）
    rm -f "$output_file" "$prompt_file"
    
    log "调用 Claude Code (验收清单): Issue #${issue_num}"
    
    echo "## 任务：为 Issue #${issue_num} 评审验收清单" > "$prompt_file"
    echo "" >> "$prompt_file"
    echo "### Issue 信息" >> "$prompt_file"
    echo "- 标题: ${title}" >> "$prompt_file"
    echo "- 内容: ${body}" >> "$prompt_file"
    echo "" >> "$prompt_file"
    echo "### 输出格式（用 markdown 代码块）：" >> "$prompt_file"
    echo "\`\`\`markdown" >> "$prompt_file"
    echo "## 验收清单评审结果" >> "$prompt_file"
    echo "" >> "$prompt_file"
    echo "### 分析" >> "$prompt_file"
    echo "{分析内容}" >> "$prompt_file"
    echo "" >> "$prompt_file"
    echo "### 优化后的验收清单" >> "$prompt_file"
    echo "- [ ] P0 {验收点1}" >> "$prompt_file"
    echo "- [ ] P1 {验收点2}" >> "$prompt_file"
    echo "- [ ] P2 {验收点3}" >> "$prompt_file"
    echo "" >> "$prompt_file"
    echo "### 评审记录" >> "$prompt_file"
    echo "- 评审时间: ${timestamp}" >> "$prompt_file"
    echo "- 评审人: Claude Code" >> "$prompt_file"
    echo "" >> "$prompt_file"
    echo "Status: checklist-review done" >> "$prompt_file"
    echo "\`\`\`" >> "$prompt_file"
    
    claude -p --model minimax/MiniMax-M2.7 --system-prompt "你是一个专业的 AI Coding 助手，擅长 TDD 开发流程。" < "$prompt_file" > "$output_file"
    
    rm -f "$prompt_file"
    
    if [[ $? -eq 0 ]]; then
        echo "$issue_num" > "$PROJECT_DIR/.supervisor/pending_issue.txt"
        log "Claude Code (清单) 完成"
        return 0
    else
        log "Claude Code (清单) 失败"
        rm -f "$output_file"
        return 1
    fi
}

# TDD RED - 创建占位测试文件（简化版，跳过 Claude Code 调用）
call_claude_code_red() {
    local issue_num=$1
    cd "$PROJECT_DIR"

    local title=$(gh issue view "$issue_num" --json title --jq ".title")
    local body=$(gh issue view "$issue_num" --json body --jq ".body")
    local output_file="$PROJECT_DIR/.supervisor/output_red_${issue_num}.txt"
    local prompt_file="/tmp/claude_prompt_red_${issue_num}.txt"
    local test_file="$PROJECT_DIR/modules/core/tests/test_${issue_num}.sh"

    rm -f "$output_file" "$prompt_file"

    log "调用 Claude Code (TDD RED): Issue #${issue_num}"

    cat > "$prompt_file" << 'PROMPTEOF'
## 任务：为 Issue 生成 TDD RED 验收测试

### Issue 信息
- 标题: TITLE_REPLACED
- 内容: BODY_REPLACED

### 测试要求
1. 创建可执行的 bash 测试脚本
2. 验证 Issue 描述的核心功能
3. 使用 set -e
4. 功能未实现时 FAIL（exit 1）
5. 功能正确实现时 PASS（exit 0）
6. 输出清晰的诊断消息

### 输出格式
用 markdown bash 代码块输出完整的测试脚本。
PROMPTEOF

    # 使用 Python 创建 prompt 文件，正确处理特殊字符
    local python_script="/tmp/gen_prompt_red_${issue_num}.py"
    cat > "$python_script" << 'PYCREATE'
import sys
title_text = sys.argv[1] if len(sys.argv) > 1 else ""
body_text = sys.argv[2] if len(sys.argv) > 2 else ""

template = """## 任务：为 Issue 生成 TDD RED 验收测试

### Issue 信息
- 标题: {title}
- 内容: {body}

### 测试要求
1. 创建可执行的 bash 测试脚本
2. 验证 Issue 描述的核心功能
3. 使用 set -e
4. 功能未实现时 FAIL（exit 1）
5. 功能正确实现时 PASS（exit 0）
6. 输出清晰的诊断消息

### 输出格式（必须严格遵循）
直接输出以下格式的 markdown 代码块，不要包含任何其他说明文字：

```bash
#!/bin/bash
# 这里是测试代码
set -e
# ... 测试逻辑 ...
```

重要：
- 输出必须以 ```bash 开头，以 ``` 结尾
- 代码块内只包含 bash 测试脚本，不要有任何解释性文字
- 不要在代码块外输出任何内容
"""

print(template.format(title=title_text, body=body_text))
PYCREATE

    python3 "$python_script" "$title" "$body" > "$prompt_file"
    rm -f "$python_script"

    claude -p --model minimax/MiniMax-M2.7 --system-prompt "你是一个专业的 TDD 工程师，擅长编写精确的验收测试。" < "$prompt_file" > "$output_file"
    rm -f "$prompt_file"

    if [[ $? -ne 0 ]]; then
        log "Claude Code (RED) 调用失败"
        rm -f "$output_file"
        return 1
    fi

    mkdir -p "$PROJECT_DIR/modules/core/tests"

    # 尝试多种提取策略
    local extracted=false

    # 策略1: 提取 ```bash 代码块
    if awk '/^```bash$/,/^```$/' "$output_file" | sed '1d;$d' > "$test_file" 2>/dev/null && [[ -s "$test_file" ]]; then
        extracted=true
        log "策略1成功：提取到 ```bash 代码块"
    # 策略2: 提取 ``` 代码块（无语言标识）
    elif awk '/^```$/,/^```$/' "$output_file" | grep -v '^```$' | sed '1d' > "$test_file" 2>/dev/null && [[ -s "$test_file" ]]; then
        extracted=true
        log "策略2成功：提取到 ``` 代码块"
    # 策略3: 提取 #!/bin/bash 开头的脚本
    elif awk '/^#!/,/^[^#]/' "$output_file" | grep -v '^[^#]' | head -50 > "$test_file" 2>/dev/null && [[ -s "$test_file" ]]; then
        extracted=true
        log "策略3成功：提取到 #!/bin/bash 脚本"
    fi

    if [[ "$extracted" != "true" ]]; then
        # 策略4: 生成基础测试框架
        log "策略4：生成基础测试框架"
        cat > "$test_file" << 'TESHEOF'
#!/bin/bash
# TDD RED 测试框架 - Issue #ISSUE_NUM_PLACEHOLDER
# 由 Claude Code TDD RED 自动生成

set -e

echo "=== TDD RED Test for Issue #ISSUE_NUM_PLACEHOLDER ==="
echo "Status: 待实现"
echo "FAIL: 测试框架已创建，功能尚未实现"

# TODO: 实现 Issue #ISSUE_NUM_PLACEHOLDER 的验收测试
# 验收标准:
# 1. [待填充]

exit 1
TESHEOF
        sed -i '' "s/ISSUE_NUM_PLACEHOLDER/$issue_num/g" "$test_file"
    fi

    if [[ ! -s "$test_file" ]]; then
        log "错误：未能提取测试脚本"
        echo "$issue_num" > "$PROJECT_DIR/.supervisor/pending_issue.txt"
        return 0
    fi

    chmod +x "$test_file"
    git add "modules/core/tests/test_${issue_num}.sh"
    git commit -m "TDD RED: 验收测试 for #${issue_num}" || true
    git push origin "feature-issue-${issue_num}" || true

    echo "$issue_num" > "$PROJECT_DIR/.supervisor/pending_issue.txt"
    log "Claude Code (RED) 完成"
    return 0
}


main() {
    local state=$(get_state)
    local current_issue=$(get_current_issue)
    
    log "启动: state=$state, issue=$current_issue"
    
    case "$state" in
        idle|done)
            local next_issue=$(select_next_issue)
            if [[ -z "$next_issue" ]]; then
                log "没有待处理的 Issue"
                update_session "done" "null"
                return 0
            fi
            create_pr "$next_issue"
            update_session "checklist-call" "$next_issue" "checklist-review"
            ;;
        checklist-call)
            if [[ "$current_issue" == "null" ]]; then
                log "Error: current_issue is null"
                update_session "idle" "null"
                return 1
            fi
            
            # 检查是否有已生成的输出（避免重复调用）
            local existing_output="$PROJECT_DIR/.supervisor/output_${current_issue}.txt"
            if [[ -f "$existing_output" && -s "$existing_output" ]]; then
                log "发现已有清单输出，跳过调用"
                update_session "checklist-post" "$current_issue" "checklist-review"
            else
                call_claude_code_checklist "$current_issue"
                update_session "checklist-post" "$current_issue" "checklist-review"
            fi
            ;;
        checklist-post)
            if [[ "$current_issue" == "null" ]]; then
                log "Error: current_issue is null"
                update_session "idle" "null"
                return 1
            fi
            post_to_github "$current_issue"
            update_session "red-call" "$current_issue" "red"
            ;;
        red-call)
            if [[ "$current_issue" == "null" ]]; then
                log "Error: current_issue is null"
                update_session "idle" "null"
                return 1
            fi
            
            # 检查是否有已生成的输出（避免重复调用）
            local existing_output="$PROJECT_DIR/.supervisor/output_red_${current_issue}.txt"
            if [[ -f "$existing_output" && -s "$existing_output" ]]; then
                log "发现已有 RED 输出，跳过调用"
                update_session "red-post" "$current_issue" "red"
            else
                call_claude_code_red "$current_issue"
                update_session "red-post" "$current_issue" "red"
            fi
            ;;
        red-post)
            if [[ "$current_issue" == "null" ]]; then
                log "Error: current_issue is null"
                update_session "idle" "null"
                return 1
            fi
            post_to_github "$current_issue"
            update_session "idle" "null" "done"
            ;;
        *)
            log "未知状态: $state"
            update_session "idle" "null"
            ;;
    esac
    
    log "完成"
}

main "$@"
