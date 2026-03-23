#!/bin/bash
# AI Coding Fullstack Supervisor v2
# 基于 TDD + 验收流程设计文档
# 状态: draft

set -e

PROJECT_DIR="$HOME/Projects/ai-coding-fullstack"
LOG_FILE="$HOME/Projects/ai-coding-fullstack/logs/supervisor_v2.log"
SESSION_FILE="$HOME/Projects/ai-coding-fullstack/.supervisor/session"
TDD_DIR="$PROJECT_DIR/scripts/tdd"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$SESSION_FILE")"

# 加载工具函数
source "$PROJECT_DIR/scripts/github-utils.sh"

# ============================================
# 日志
# ============================================
log() { 
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# ============================================
# 状态管理
# ============================================
get_state() {
    [[ -f "$SESSION_FILE" ]] && python3 -c "import sys,json; print(json.load(open('$SESSION_FILE')).get('state','idle'))" 2>/dev/null || echo "idle"
}

get_current_issue() {
    [[ -f "$SESSION_FILE" ]] && python3 -c "import sys,json; print(json.load(open('$SESSION_FILE')).get('current_issue','null'))" 2>/dev/null || echo "null"
}

get_last_issue() {
    [[ -f "$SESSION_FILE" ]] && python3 -c "import sys,json; print(json.load(open('$SESSION_FILE')).get('last_issue','null'))" 2>/dev/null || echo "null"
}

update_state() {
    local state="$1" current_issue="$2" last_issue="$3"
    [[ "$current_issue" == "null" ]] && current_issue="null" || current_issue="\"$current_issue\""
    [[ "$last_issue" == "null" ]] && last_issue="null" || last_issue="\"$last_issue\""
    
    cat > "$SESSION_FILE" << EOF
{
    "state": "$state",
    "current_issue": $current_issue,
    "last_issue": $last_issue,
    "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    log "状态更新: state=$state, current=$current_issue, last=$last_issue"
}

# ============================================
# 阶段检查函数
# ============================================
check_stage_complete() {
    local issue_num=$1
    local stage=$2
    cd "$PROJECT_DIR"
    local count
    count=$(gh issue comments "$issue_num" 2>/dev/null | grep -c "Status.*${stage}.*done" 2>/dev/null || echo "0")
    count=$(echo "$count" | tr -d '[:space:]')
    [[ "$count" -gt 0 ]]
}

run_acceptance_tests() {
    local issue_num=$1
    local test_file="$PROJECT_DIR/modules/core/tests/test_$issue_num.sh"
    
    if [[ ! -f "$test_file" ]]; then
        log "X 验收测试文件不存在: $test_file"
        return 1
    fi
    
    bash "$test_file"
}

check_ci_status() {
    local pr_num=$1
    cd "$PROJECT_DIR"
    
    local checks=$(gh pr checks "$pr_num" --json status,conclusion 2>/dev/null)
    local failed=$(echo "$checks" | jq -r '.[] | select(.conclusion=="failure") | .id' 2>/dev/null | wc -l)
    [[ $failed -eq 0 ]]
}

check_mergeable() {
    local pr_num=$1
    cd "$PROJECT_DIR"
    
    local mergeable=$(gh pr view "$pr_num" --json mergeable --jq '.mergeable' 2>/dev/null)
    [[ "$mergeable" == "true" ]]
}

check_review_comments() {
    local issue_num=$1
    cd "$PROJECT_DIR"
    
    local count=$(gh issue comments "$issue_num" 2>/dev/null | \
        grep -c "验收清单评审\|技术方案评审\|Design Review\|Checklist Review" || echo 0)
    
    [[ $count -ge 2 ]]
}

get_issue_priority() {
    local issue_num=$1
    cd "$PROJECT_DIR"
    
    gh issue view "$issue_num" --json labels --jq '.labels[] | select(.name | startswith("P")) | .name' 2>/dev/null | \
        head -1 || echo "P3"
}

get_pr_number() {
    local issue_num=$1
    cd "$PROJECT_DIR"
    
    gh pr list --head "feature/issue-$issue_num" --state open --json number --jq '.[0].number' 2>/dev/null || echo ""
}

# ============================================
# 调用 Claude Code 执行任务
# ============================================
run_with_timeout() {
    local seconds=$1
    shift
    if command -v timeout &>/dev/null; then
        timeout "$seconds" $@
    else
        perl -e 'alarm shift; exec @ARGV' "$seconds" $@
    fi
}

call_claude_code() {
    local task="$1"
    local prompt="$2"
    
    log "调用 Claude Code: $task"
    
    # 使用 claude -p 执行任务
    # 超时 5 分钟
    run_with_timeout 300 claude -p --model minimax/MiniMax-M2.7 --system-prompt "你是一个专业的 AI Coding 助手，擅长 TDD 开发流程。" << EOF
$prompt
EOF
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log "Claude Code 完成: $task"
        return 0
    elif [[ $exit_code -eq 124 ]]; then
        log "Claude Code 超时: $task"
        return 1
    else
        log "Claude Code 失败: $task, exit_code=$exit_code"
        return 1
    fi
}


# ============================================
# 辅助函数：发帖到 GitHub
# ============================================
post_to_github() {
    local issue_num=$1
    local comment_file=$2
    
    cd "$PROJECT_DIR"
    log "DEBUG post_to_github: issue_num=$issue_num, file=$comment_file"
    
    if [[ -f "$comment_file" && -s "$comment_file" ]]; then
        log "DEBUG: 文件存在且非空"
        # 提取 markdown 代码块内容
        local body
        body=$(awk '/^```markdown$/,/^```$/' "$comment_file" | sed '1d;$d')
        log "DEBUG: 提取的 body 长度: ${#body}"
        
        if [[ -n "$body" ]]; then
            log "DEBUG: 发帖到 Issue #$issue_num (markdown)"
            gh issue comment "$issue_num" --body "$body"
            echo "已发帖到 Issue #$issue_num"
        else
            log "DEBUG: 没有 markdown 代码块，使用全文"
            # 如果没有 markdown 代码块，直接发帖整个内容
            gh issue comment "$issue_num" --body "$(cat "$comment_file")"
            echo "已发帖到 Issue #$issue_num (全文)"
        fi
    else
        log "DEBUG: 文件不存在或为空"
    fi
}

# ============================================
# 阶段 0: 验收清单评审
# ============================================
trigger_checklist_review() {
    local issue_num=$1
    cd "$PROJECT_DIR"
    
    local title=$(gh issue view "$issue_num" --json title --jq '.title')
    local body=$(gh issue view "$issue_num" --json body --jq '.body')
    local pr_num=$(get_pr_number "$issue_num")
    
    log "TDD Checklist Review: Issue #$issue_num"
    
    local prompt="## 任务：评审 Issue #$issue_num 的验收清单

### Issue 信息
- 标题: $title
- 内容: $body

### 你的任务：

1. **分析验收标准**
   - 识别核心功能需求
   - 识别边界情况
   - 识别非功能需求 (性能、安全、可维护性)

2. **评审现有验收清单**（如有）
   - 检查完整性
   - 检查可测试性
   - 检查优先级

3. **优化验收清单**
   - 添加遗漏的验收点
   - 修正不清晰的描述
   - 标注关键验收点 (P0/P1/P2)

4. **在 Issue 下回复评审结果**

请回复格式如下：

\`\`\`
## 验收清单评审结果

### 分析
{分析内容}

### 优化后的验收清单

- [ ] P0 {验收点1}
- [ ] P1 {验收点2}
- [ ] P2 {验收点3}

### 评审记录
- 评审时间: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- 评审人: Claude Code

Status: checklist-review done
\`\`\`
"
    
    # 调用 Claude Code，文件名包含 issue_num
    local output_file="/tmp/claude_output_${issue_num}.txt"
    call_claude_code "checklist-review" "$prompt" > "$output_file"
    
    if [[ $? -eq 0 && -s "$output_file" ]]; then
        log "验收清单评审完成"
        # 发帖到 GitHub
        post_to_github "$issue_num" "$output_file"
    else
        log "验收清单评审失败"
    fi
    rm -f "$output_file"
}

# ============================================
# 阶段 1: TDD RED
# ============================================
trigger_tdd_red() {
    local issue_num=$1
    local pr_num=$2
    cd "$PROJECT_DIR"
    
    local title=$(gh issue view "$issue_num" --json title --jq '.title')
    local body=$(gh issue view "$issue_num" --json body --jq '.body')
    local branch_name="feature/issue-$issue_num"
    
    log "TDD RED: Issue #$issue_num"
    
    # 确保在正确分支
    git checkout "$branch_name" 2>/dev/null || true
    
    local prompt="## 任务：为 Issue #$issue_num 编写验收测试

### Issue 信息
- 标题: $title
- 内容: $body

### 你的任务：

1. **阅读 Issue 和验收清单**
   - 理解核心功能需求
   - 确认验收标准

2. **编写验收测试**
   - 在 $PROJECT_DIR/modules/core/tests/ 目录创建 test_$issue_num.sh
   - 使用 bash 脚本
   - 测试应该覆盖验收清单中的每个点
   - 测试应该在功能未实现时失败

3. **运行测试确认失败**
   - 运行测试，应该失败（因为功能还没实现）
   - 这是 TDD RED 的预期行为

4. **提交代码**
   - 提交信息: \"TDD RED: 验收测试 for #$issue_num\"

5. **在 Issue 下回复状态**

请回复格式如下：

\`\`\`
## TDD RED 完成

### 测试文件
$PROJECT_DIR/modules/core/tests/test_$issue_num.sh

### 测试结果
运行测试结果（应该失败）

### 提交
已提交 "TDD RED: 验收测试 for #$issue_num"

Status: red done
\`\`\`
"
    
    if call_claude_code "tdd-red" "$prompt"; then
        log "TDD RED 完成"
        # 推送分支
        git push origin "$branch_name" 2>/dev/null || true
    else
        log "TDD RED 失败"
    fi
}

# ============================================
# 阶段 2: 技术方案评审
# ============================================
trigger_design_review() {
    local issue_num=$1
    cd "$PROJECT_DIR"
    
    local title=$(gh issue view "$issue_num" --json title --jq '.title')
    local body=$(gh issue view "$issue_num" --json body --jq '.body')
    local pr_num=$(get_pr_number "$issue_num")
    
    log "TDD Design Review: Issue #$issue_num"
    
    local prompt="## 任务：为 Issue #$issue_num 设计技术方案

### Issue 信息
- 标题: $title
- 内容: $body

### 你的任务：

1. **阅读验收清单和现有代码**
   - 理解验收标准
   - 查看 modules/core/impl/ 目录结构

2. **设计技术方案**
   - 确定实现方式 (新增模块 / 修改现有代码)
   - 数据流设计
   - 接口设计 (如果有)
   - 依赖分析

3. **技术方案评审**
   - 评估可行性
   - 评估性能影响
   - 评估安全影响
   - 识别风险点

4. **输出技术方案文档**

请在 Issue 下回复格式如下：

\`\`\`
## 技术方案

### 实现方式
{描述}

### 数据流
{描述}

### 接口设计
| 接口 | 输入 | 输出 |
|------|------|------|
| xxx | yyy | zzz |

### 依赖
- 依赖 A
- 依赖 B

### 风险评估
| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| xxx  | 高   | yyy      |

### 实现步骤
1. 步骤1
2. 步骤2

Status: design-review done
\`\`\`
"
    
    if call_claude_code "design-review" "$prompt"; then
        log "技术方案评审完成"
    else
        log "技术方案评审失败"
    fi
}

# ============================================
# 阶段 3: TDD GREEN
# ============================================
trigger_tdd_green() {
    local issue_num=$1
    local pr_num=$2
    cd "$PROJECT_DIR"
    
    local title=$(gh issue view "$issue_num" --json title --jq '.title')
    local body=$(gh issue view "$issue_num" --json body --jq '.body')
    local branch_name="feature/issue-$issue_num"
    
    log "TDD GREEN: Issue #$issue_num"
    
    # 确保在正确分支
    git checkout "$branch_name" 2>/dev/null || true
    
    local prompt="## 任务：为 Issue #$issue_num 实现功能

### Issue 信息
- 标题: $title
- 内容: $body

### 你的任务：

1. **阅读技术方案**
   - 理解实现路径
   - 确认依赖已满足

2. **实现功能**
   - 在 $PROJECT_DIR/modules/core/impl/ 目录实现
   - 遵循项目代码规范

3. **运行测试确认通过**
   - 运行验收测试 test_$issue_num.sh
   - 测试应该通过

4. **提交代码**
   - 提交信息: \"TDD GREEN: 实现 #$issue_num\"

5. **在 Issue 下回复状态**

请回复格式如下：

\`\`\`
## TDD GREEN 完成

### 实现文件
modules/core/impl/

### 测试结果
运行测试结果（应该通过）

### 提交
已提交 "TDD GREEN: 实现 #$issue_num"

Status: green done
\`\`\`
"
    
    if call_claude_code "tdd-green" "$prompt"; then
        log "TDD GREEN 完成"
        # 推送分支
        git push origin "$branch_name" 2>/dev/null || true
    else
        log "TDD GREEN 失败"
    fi
}

# ============================================
# 阶段 4: TDD REFACTOR
# ============================================
trigger_tdd_refactor() {
    local issue_num=$1
    local pr_num=$2
    cd "$PROJECT_DIR"
    
    local title=$(gh issue view "$issue_num" --json title --jq '.title')
    local branch_name="feature/issue-$issue_num"
    
    log "TDD REFACTOR: Issue #$issue_num"
    
    # 确保在正确分支
    git checkout "$branch_name" 2>/dev/null || true
    
    local prompt="## 任务：重构 Issue #$issue_num 的实现

### Issue 信息
- 标题: $title

### 你的任务：

1. **代码质量检查**
   - 检查代码规范
   - 检查重复代码
   - 检查可读性

2. **重构优化**
   - 提取公共函数
   - 优化命名
   - 添加必要的注释
   - 优化性能 (如有需要)

3. **运行测试确认通过**
   - 确保重构后测试仍然通过

4. **提交代码**
   - 提交信息: \"TDD REFACTOR: 重构 #$issue_num\"

5. **在 Issue 下回复状态**

请回复格式如下：

\`\`\`
## TDD REFACTOR 完成

### 重构内容
{重构点}

### 测试结果
运行测试结果（应该通过）

### 提交
已提交 "TDD REFACTOR: 重构 #$issue_num"

Status: refactor done
\`\`\`
"
    
    if call_claude_code "tdd-refactor" "$prompt"; then
        log "TDD REFACTOR 完成"
        # 推送分支
        git push origin "$branch_name" 2>/dev/null || true
    else
        log "TDD REFACTOR 失败"
    fi
}

# ============================================
# 阶段 5: 最终评审
# ============================================
trigger_final_review() {
    local issue_num=$1
    local pr_num=$2
    cd "$PROJECT_DIR"
    
    local title=$(gh issue view "$issue_num" --json title --jq '.title')
    
    log "Final Review: Issue #$issue_num"
    
    local prompt="## 任务：最终评审 Issue #$issue_num

### Issue 信息
- 标题: $title

### 你的任务：

1. **验收清单确认**
   - 阅读 Issue 下的验收清单
   - 确认 P0/P1 验收点都已满足
   - 检查是否有遗留问题

2. **代码质量确认**
   - 检查实现代码是否符合规范
   - 检查是否有明显的安全问题
   - 检查是否有性能问题

3. **测试确认**
   - 确认验收测试覆盖充分
   - 确认测试能够捕获关键 bug

4. **生成最终评审报告**

请在 Issue 下回复格式如下：

\`\`\`
## 最终评审报告

### 验收清单确认
- P0: 全部通过 / X 项未通过
- P1: 全部通过 / X 项未通过

### 代码质量
- 规范: 通过 / 问题
- 安全: 通过 / 问题
- 性能: 通过 / 问题

### 测试
- 覆盖率: XX%
- 关键路径: 全覆盖 / 缺失

### 结论
可以合并 / 需要修改

### 建议
{如有建议请列出}
\`\`\`
"
    
    if call_claude_code "final-review" "$prompt"; then
        log "最终评审完成"
    else
        log "最终评审失败"
    fi
}

# ============================================
# 触发 Claude Code 执行各阶段
# ============================================
trigger_claude_code() {
    local stage="$1"
    local issue_num="$2"
    local pr_num="$3"
    
    log "触发 Claude Code: stage=$stage, issue=$issue_num"
    
    case "$stage" in
        checklist-review)
            trigger_checklist_review "$issue_num"
            ;;
        red)
            trigger_tdd_red "$issue_num" "$pr_num"
            ;;
        design-review)
            trigger_design_review "$issue_num"
            ;;
        green)
            trigger_tdd_green "$issue_num" "$pr_num"
            ;;
        refactor)
            trigger_tdd_refactor "$issue_num" "$pr_num"
            ;;
        final-review)
            trigger_final_review "$issue_num" "$pr_num"
            ;;
    esac
}

# ============================================
# 人工确认流程
# ============================================
request_human_review() {
    local issue_num=$1
    local pr_num=$2
    
    cd "$PROJECT_DIR"
    
    gh issue comment "$issue_num" --body "
## ⚠️ 最终评审待确认

Issue #$issue_num (PR #$pr_num) 已完成 TDD 流程，请确认：

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
    
    log "已请求人工确认 Issue #$issue_num"
}

# ============================================
# 自动合并
# ============================================
auto_merge() {
    local pr_num=$1
    local issue_num=$2
    
    cd "$PROJECT_DIR"
    
    if gh pr merge "$pr_num" --admin --merge --body "Auto-merged by AI Coding Fullstack Supervisor v2" 2>/dev/null; then
        log "合并成功 PR #$pr_num"
        gh issue close "$issue_num" --comment "✅ 已合并" 2>/dev/null || true
        return 0
    else
        log "合并失败 PR #$pr_num"
        return 1
    fi
}

# ============================================
# 最终评审 (来自 final_review.sh)
# ============================================
final_review() {
    local issue_num=$1
    local pr_num=$(get_pr_number "$issue_num")
    
    [[ -z "$pr_num" ]] && { log "Issue #$issue_num 没有 PR"; return 1; }
    
    log "=== 最终评审: Issue #$issue_num (PR #$pr_num) ==="
    
    # 检查阶段完成状态
    local stages=("checklist-review" "red" "design-review" "green" "refactor")
    for stage in "${stages[@]}"; do
        if ! check_stage_complete "$issue_num" "$stage"; then
            log "X 阶段 $stage 未完成"
            return 1
        fi
        log "  ✅ 阶段 $stage 完成"
    done
    
    # 运行验收测试
    log "运行验收测试..."
    if ! run_acceptance_tests "$issue_num"; then
        log "X 验收测试失败"
        return 1
    fi
    log "  ✅ 验收测试通过"
    
    # 检查 CI 状态
    log "检查 CI 状态..."
    if ! check_ci_status "$pr_num"; then
        log "X CI 未通过"
        return 1
    fi
    log "  ✅ CI 通过"
    
    # 检查合并冲突
    log "检查合并冲突..."
    if ! check_mergeable "$pr_num"; then
        log "X 有合并冲突"
        return 1
    fi
    log "  ✅ 无合并冲突"
    
    # 检查评审记录
    log "检查评审记录..."
    if ! check_review_comments "$issue_num"; then
        log "X 评审记录不足"
        return 1
    fi
    log "  ✅ 评审记录完整"
    
    # 根据优先级决策
    local priority=$(get_issue_priority "$issue_num")
    log "Issue 优先级: $priority"
    
    case "$priority" in
        P0|P1)
            log "⚠️ P0/P1 需要人工确认"
            request_human_review "$issue_num" "$pr_num"
            ;;
        P2|P3|*)
            log "💚 P2/P3 自动合并"
            auto_merge "$pr_num" "$issue_num"
            ;;
    esac
    
    return 0
}

# ============================================
# 选择下一个 Issue
# ============================================
select_next_issue() {
    cd "$PROJECT_DIR"
    
    local current=$(get_current_issue)
    [[ "$current" == "null" ]] && current=""
    local last=$(get_last_issue)
    [[ "$last" == "null" ]] && last=""
    
    local issues=$(gh issue list --state open --limit 20 2>/dev/null)
    
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local num=$(echo "$line" | awk '{print $1}')
        [[ -z "$num" ]] && continue
        [[ -n "$current" && "$num" == "$current" ]] && continue
        [[ -n "$last" && "$num" == "$last" ]] && continue
        
        # 检查是否有 PR
        local pr_status=$(check_pr_status "$num")
        if [[ "$pr_status" != "none" ]]; then
            log "Issue #$num 已有 PR ($pr_status)，跳过"
            continue
        fi
        
        # 检查是否有分支
        if branch_exists "$num"; then
            log "Issue #$num 有分支但无 PR，继续处理"
        fi
        
        echo "$num"
        return 0
    done <<< "$issues"
    
    return 1
}

# ============================================
# 创建 PR Draft
# ============================================
create_pr_draft() {
    local issue_num=$1
    cd "$PROJECT_DIR"
    
    local branch_name="feature/issue-$issue_num"
    local title=$(gh issue view "$issue_num" --json title --jq '.title')
    
    # 保存 issue_num 到文件，供恢复时使用
    echo "$issue_num" > "$PROJECT_DIR/.supervisor/current_issue"
    
    # 创建分支
    if ! git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
        git checkout -b "$branch_name" 2>/dev/null || true
        log "创建分支: $branch_name"
    else
        git checkout "$branch_name" 2>/dev/null || true
        log "切换到分支: $branch_name"
    fi
    
    # 创建测试目录
    mkdir -p "$PROJECT_DIR/modules/core/tests"
    
    # 创建占位测试文件
    cat > "$PROJECT_DIR/modules/core/tests/test_$issue_num.sh" << 'TESTEOF'
#!/bin/bash
# TDD RED 占位 - 待 Claude Code 填充
echo "Issue #PLACEHOLDER 验收测试 (占位)"
exit 1  # 故意失败，因为功能还没实现
TESTEOF
    sed -i '' 's/PLACEHOLDER/$issue_num/g' "$PROJECT_DIR/modules/core/tests/test_$issue_num.sh"
    chmod +x "$PROJECT_DIR/modules/core/tests/test_$issue_num.sh"
    
    git add .
    git commit -m "TDD RED: 验收测试 for #$issue_num" 2>/dev/null || true
    
    # 推送分支
    log "推送分支..."
    git push -u origin "$branch_name" 2>/dev/null || true
    
    # 创建 PR
    local pr_url=$(gh pr create \
        --title "feat #$issue_num: $title" \
        --body "## Issue
#$issue_num: $title

## TDD 流程进行中

- [ ] Checklist Review
- [ ] TDD RED
- [ ] Design Review
- [ ] TDD GREEN
- [ ] TDD REFACTOR
- [ ] Final Review
" \
        --head "$branch_name" \
        --base main 2>&1 | head -1)
    
    log "PR 创建: $pr_url"
}

# ============================================
# 检查 TDD 状态并推进
# ============================================
check_and_advance() {
    local issue_num=$(get_current_issue)
    [[ "$issue_num" == "null" || -z "$issue_num" ]] && { log "没有正在处理的 Issue"; return 1; }
    
    local pr_num=$(get_pr_number "$issue_num")
    [[ -z "$pr_num" ]] && { log "Issue #$issue_num 没有 PR"; return 1; }
    
    local stages=("checklist-review" "red" "design-review" "green" "refactor")
    local next_stage=""
    
    for stage in "${stages[@]}"; do
        if ! check_stage_complete "$issue_num" "$stage"; then
            next_stage="$stage"
            break
        fi
    done
    
    if [[ -z "$next_stage" ]]; then
        log "所有阶段完成，执行最终评审"
        final_review "$issue_num" "$pr_num"
        return $?
    fi
    
    log "下一阶段: $next_stage"
    trigger_claude_code "$next_stage" "$issue_num" "$pr_num"
}

# ============================================
# 主流程
# ============================================
# 检查是否有未完成的输出需要发帖
check_pending_output() {
    # 查找所有未完成的输出文件
    local pending_files
    pending_files=$(ls -t /tmp/claude_output_*.txt 2>/dev/null)
    log "DEBUG: pending_files = [$pending_files]"
    if [[ -n "$pending_files" ]]; then
        for f in $pending_files; do
            # 从文件名提取 issue_num: /tmp/claude_output_42.txt -> 42
            local issue_num
            issue_num=$(echo "$f" | grep -oE '_[0-9]+\.txt$' | grep -oE '[0-9]+')
            log "DEBUG: processing file=$f, issue_num=[$issue_num]"
            if [[ -n "$issue_num" ]]; then
                log "发现未完成的输出，发帖到 Issue #$issue_num"
                post_to_github "$issue_num" "$f"
                rm -f "$f"
            fi
        done
    else
        log "DEBUG: 没有发现待处理的输出文件"
    fi
}

main() {
    log "=== AI Coding Supervisor v2 ==="
    
    cd "$PROJECT_DIR"
    
    # 先检查是否有未完成的输出
    check_pending_output
    
    local state=$(get_state)
    local current_issue=$(get_current_issue)
    
    log "当前状态: state=$state, current_issue=$current_issue"
    
    case "$state" in
        idle)
            # 选择下一个 Issue
            local next=$(select_next_issue)
            if [[ -z "$next" ]]; then
                log "没有待处理的 Issue"
                return 0
            fi
            
            log "选取 Issue #$next"
            create_pr_draft "$next"
            update_state "working" "$next" "null"
            
            # 触发第一个阶段
            trigger_claude_code "checklist-review" "$next" ""
            ;;
            
        working)
            # 检查并推进 TDD 流程
            check_and_advance
            ;;
            
        *)
            log "未知状态: $state，重置"
            update_state "idle" "null" "null"
            ;;
    esac
    
    log "=== Supervisor v2 完成 ==="
}

main "$@"
