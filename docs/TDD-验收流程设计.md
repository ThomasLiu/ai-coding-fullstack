# AI Coding Fullstack TDD + 验收流程设计方案

**版本**: v1.1.0
**日期**: 2026-03-23
**状态**: `draft`
**作者**: 程序猿🦍

---

## 一、核心问题回顾

| 问题 | 现状 | 影响 |
|------|------|------|
| **TDD 不完整** | 只有 RED (创建测试) | 没有 GREEN/REFACTOR，代码无法真正完成 |
| **没有验收** | PR 只是占位提交 | 没有基于 SPEC.md 验收标准 |
| **没有合并策略** | PR 创建后无人管 | 不知道何时合并，积压严重 |
| **职责不清** | Supervisor 做所有事 | 应该只做调度 |

---

## 二、改进后的架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         Supervisor (调度器)                          │
├─────────────────────────────────────────────────────────────────┤
│  职责：                                                              │
│  1. 选择下一个 Issue                                                │
│  2. 检查分支/PR 状态                                               │
│  3. 创建分支和 PR (draft)                                          │
│  4. 触发 Claude Code 执行各阶段                                     │
│  5. 检查各阶段完成状态                                              │
│  6. 决策合并                                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Claude Code (执行器)                              │
├─────────────────────────────────────────────────────────────────┤
│  职责：                                                              │
│  1. 验收清单评审 - 评审和优化验收标准                                │
│  2. TDD RED - 编写验收测试                                         │
│  3. 技术方案评审 - 设计方案评审和优化                                │
│  4. TDD GREEN - 实现功能让测试通过                                   │
│  5. TDD REFACTOR - 重构优化                                         │
│  6. 更新验收清单和评审记录                                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GitHub PR + Issues                             │
├─────────────────────────────────────────────────────────────────┤
│  状态机：                                                             │
│  selected → checklist-review → red → design-review → green → refactor → review → merged │
│                                                                   │
│  Issue Discussion: 作为评审记录的载体                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 三、TDD 完整流程 (v1.1)

### 流程图

```
┌──────────────────────────────────────────────────────────────────┐
│                         完整 TDD 流程                               │
└──────────────────────────────────────────────────────────────────┘

Issue Selected
     │
     ▼
┌───────────────────────────────────────┐
│  0. 验收清单评审 (Checklist Review)     │
│  ───────────────────────────────────  │
│  • Claude Code 评审验收标准               │
│  • 优化验收清单                         │
│  • 回复 Issue 作为评审记录                │
│  • 输出: 优化后的验收清单                 │
└───────────────────────────────────────┘
     │ 完成后更新 Issue 状态: checklist-review-done
     ▼
┌───────────────────────────────────────┐
│  1. TDD RED (验收测试)                  │
│  ───────────────────────────────────  │
│  • 基于优化后的验收清单编写测试           │
│  • 运行测试确认失败                      │
│  • 提交: "TDD RED: 验收测试 for #X"    │
└───────────────────────────────────────┘
     │ 完成后更新 Issue 状态: red-done
     ▼
┌───────────────────────────────────────┐
│  2. 技术方案评审 (Design Review)        │
│  ───────────────────────────────────  │
│  • Claude Code 设计技术方案             │
│  • 方案评审和优化                       │
│  • 回复 Issue 作为评审记录               │
│  • 输出: 技术方案文档                    │
└───────────────────────────────────────┘
     │ 完成后更新 Issue 状态: design-review-done
     ▼
┌───────────────────────────────────────┐
│  3. TDD GREEN (实现)                   │
│  ───────────────────────────────────  │
│  • 基于评审后的技术方案实现              │
│  • 运行测试确认通过                      │
│  • 提交: "TDD GREEN: 实现 #X"         │
└───────────────────────────────────────┘
     │ 完成后更新 Issue 状态: green-done
     ▼
┌───────────────────────────────────────┐
│  4. TDD REFACTOR (重构)                │
│  ───────────────────────────────────  │
│  • 代码重构和优化                        │
│  • 运行测试确认通过                      │
│  • 提交: "TDD REFACTOR: 重构 #X"      │
└───────────────────────────────────────┘
     │ 完成后更新 Issue 状态: refactor-done
     ▼
┌───────────────────────────────────────┐
│  5. 最终评审 (Final Review)             │
│  ───────────────────────────────────  │
│  • 检查所有验收标准是否满足               │
│  • 确认评审记录完整                      │
│  • 更新 PR 状态 → ready-to-merge       │
└───────────────────────────────────────┘
     │ 满足合并条件
     ▼
MERGED
```

---

### 阶段 0：验收清单评审 (Checklist Review)

**执行者**: Claude Code (专业 Agent)

**输入**:
- Issue 内容
- SPEC.md 相关章节

**Prompt 模板**:

```
## 任务：评审 Issue #X 的验收清单

### Issue 内容
{issue_body}

### SPEC.md 相关章节
{spec_section}

### 请完成以下任务：

1. **分析验收标准**
   - 识别核心功能需求
   - 识别边界情况
   - 识别非功能需求 (性能、安全、可维护性)

2. **评审现有验收清单**
   - 检查完整性
   - 检查可测试性
   - 检查优先级

3. **优化验收清单**
   - 添加遗漏的验收点
   - 修正不清晰的描述
   - 标注关键验收点 (P0/P1/P2)

4. **输出优化后的验收清单**
   - 使用 checkbox 格式
   - 包含具体的验收条件

### 回复格式
请在 Issue 下回复，格式如下：

---
## 验收清单评审结果

### 分析
{分析内容}

### 优化后的验收清单

- [ ] P0 {验收点1}
- [ ] P1 {验收点2}
- [ ] P2 {验收点3}

### 评审记录
- 评审时间: {timestamp}
- 评审人: Claude Code
---
```

---

### 阶段 1：TDD RED (验收测试)

**执行者**: Claude Code

**Prompt 模板**:

```
## 任务：为 Issue #X 实现验收测试

### Issue 内容
{issue_body}

### 验收清单
{checklist_from_review}

### 请完成以下任务：

1. **阅读验收清单**
   - 理解每个验收点的具体要求

2. **编写验收测试**
   - 在 modules/core/tests/ 目录创建 test_{issue}.sh
   - 使用 bash 脚本
   - 测试应该能验证验收清单中的每个点

3. **验证测试失败**
   - 运行测试确认失败 (因为功能还没实现)
   - 这是预期的 TDD RED 行为

4. **提交代码**
   - 提交信息: "TDD RED: 验收测试 for #X"
   - 包含测试文件

5. **更新 Issue 状态**
   - 在 Issue 评论中更新状态为 "RED done"

### 测试文件模板
```bash
#!/bin/bash
# Issue #X 验收测试

set -e

echo "=== Issue #X 验收测试 ==="

# 测试 1: 核心功能
test_core_function() {
    # 实现验收测试逻辑
    echo "测试: 核心功能"
}

# 测试 2: 边界情况
test_edge_case() {
    echo "测试: 边界情况"
}

# 运行所有测试
test_core_function
test_edge_case

echo "=== 测试完成 ==="
```

### 回复格式
请在 PR 下回复状态：
- TDD RED: 开始
- TDD RED: 完成 ({测试文件路径})
```

---

### 阶段 2：技术方案评审 (Design Review)

**执行者**: Claude Code (专业 Agent)

**输入**:
- Issue 内容
- 验收清单
- 现有代码结构

**Prompt 模板**:

```
## 任务：为 Issue #X 设计技术方案

### Issue 内容
{issue_body}

### 验收清单 (已优化)
{checklist}

### 现有代码结构
{code_structure}

### 请完成以下任务：

1. **技术方案设计**
   - 确定实现方式 (新增模块 / 修改现有代码 / 配置文件)
   - 数据流设计
   - 接口设计 (如果有)
   - 依赖分析

2. **技术方案评审**
   - 评估可行性
   - 评估性能影响
   - 评估安全影响
   - 识别风险点

3. **优化技术方案**
   - 解决评审中发现的问题
   - 添加必要的异常处理
   - 优化实现路径

4. **输出技术方案文档**
   - 在 Issue 或 PR 中创建技术方案

### 技术方案文档模板
```markdown
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
```

### 回复格式
请在 Issue/PR 下回复：
- TDD Design Review: 开始
- TDD Design Review: 完成 (附技术方案文档链接)
```

---

### 阶段 3：TDD GREEN (实现)

**执行者**: Claude Code

**Prompt 模板**:

```
## 任务：为 Issue #X 实现功能

### Issue 内容
{issue_body}

### 验收清单
{checklist}

### 技术方案
{design_doc}

### 请完成以下任务：

1. **阅读技术方案**
   - 理解实现路径
   - 确认依赖已满足

2. **实现功能**
   - 在 modules/core/impl/ 目录实现
   - 遵循项目代码规范

3. **运行测试**
   - 运行验收测试确认通过
   - 如有测试失败，修复实现

4. **提交代码**
   - 提交信息: "TDD GREEN: 实现 #X"
   - 包含实现代码

5. **更新 Issue 状态**
   - 在 Issue 评论中更新状态为 "GREEN done"

### 回复格式
请在 PR 下回复状态：
- TDD GREEN: 开始
- TDD GREEN: 完成 (测试通过/失败)
```

---

### 阶段 4：TDD REFACTOR (重构)

**执行者**: Claude Code

**Prompt 模板**:

```
## 任务：重构 Issue #X 的实现

### Issue 内容
{issue_body}

### 当前实现
{current_impl}

### 请完成以下任务：

1. **代码质量检查**
   - 检查代码规范
   - 检查重复代码
   - 检查可读性

2. **重构优化**
   - 提取公共函数
   - 优化命名
   - 添加必要的注释
   - 优化性能 (如有需要)

3. **运行测试**
   - 确保重构后测试仍然通过

4. **提交代码**
   - 提交信息: "TDD REFACTOR: 重构 #X"

5. **更新 Issue 状态**
   - 在 Issue 评论中更新状态为 "REFACTOR done"
```

---

### 阶段 5：最终评审 (Final Review)

**执行者**: Supervisor + Claude Code

**检查项**:

```bash
# 最终评审检查脚本
final_review_check() {
    local issue_num=$1
    local pr_num=$2
    
    # 1. 检查验收清单完成情况
    local checklist_complete=$(gh issue view $issue_num --json body | jq -r '.body' | grep -c "^- \[x\]")
    [[ $checklist_complete -eq 0 ]] && { echo "❌ 无验收清单完成记录"; return 1; }
    
    # 2. 检查 TDD 提交记录
    local tdd_commits=$(gh pr commits $pr_num | grep -c "TDD RED\|TDD GREEN\|TDD REFACTOR")
    [[ $tdd_commits -lt 3 ]] && { echo "❌ TDD 流程不完整"; return 1; }
    
    # 3. 检查 CI 状态
    local ci_status=$(gh pr checks $pr_num --json status | jq -r '.[0].status')
    [[ "$ci_status" != "COMPLETED" ]] && { echo "❌ CI 未完成"; return 1; }
    
    # 4. 检查评审记录
    local review_comments=$(gh issue comments $issue_num | grep -c "Review:\|review:")
    [[ $review_comments -lt 2 ]] && { echo "❌ 评审记录不足"; return 1; }
    
    echo "✅ 最终评审通过"
    return 0
}
```

---

## 四、Supervisor 完整状态机 (v2)

```
┌──────────────────────────────────────────────────────────────────┐
│                         Supervisor v2 状态机                              │
└──────────────────────────────────────────────────────────────────┘

IDLE
  │
  ▼
SELECT_ISSUE
  │
  ▼
CHECKLIST_REVIEW
  │ 触发 Claude Code 评审验收清单
  │ 等待 Issue 评论中出现 "验收清单评审结果"
  ▼
CHECKLIST_REVIEW_DONE
  │
  ▼
TDD_RED
  │ 触发 Claude Code 编写验收测试
  │ 等待 PR commit "TDD RED"
  ▼
RED_DONE
  │
  ▼
DESIGN_REVIEW
  │ 触发 Claude Code 设计技术方案
  │ 等待 Issue 评论中出现 "技术方案" 或 "Design Review"
  ▼
DESIGN_REVIEW_DONE
  │
  ▼
TDD_GREEN
  │ 触发 Claude Code 实现功能
  │ 等待 PR commit "TDD GREEN"
  ▼
GREEN_DONE
  │
  ▼
TDD_REFACTOR
  │ 触发 Claude Code 重构
  │ 等待 PR commit "TDD REFACTOR"
  ▼
REFACTOR_DONE
  │
  ▼
FINAL_REVIEW
  │ 运行最终评审检查
  │ 检查所有阶段完成状态
  ▼
READY_TO_MERGE / NEEDS_FIX
  │
  ▼ (READY_TO_MERGE)
MERGED ──► IDLE
```

---

## 五、Issue 状态标签

使用 GitHub Labels 管理状态：

| Label | 描述 | 触发时机 |
|-------|------|----------|
| `status:selected` | 已选择 | Supervisor 选中 Issue |
| `status:checklist-review` | 验收清单评审中 | 触发 Claude Code 评审 |
| `status:red` | TDD RED 进行中 | 编写验收测试 |
| `status:design-review` | 技术方案评审中 | 触发 Claude Code 设计 |
| `status:green` | TDD GREEN 进行中 | 实现功能 |
| `status:refactor` | TDD REFACTOR 进行中 | 重构代码 |
| `status:review` | 最终评审 | 所有阶段完成 |
| `status:ready` | 可合并 | 评审通过 |
| `status:merged` | 已合并 | PR 已合并 |

---

## 六、PR 模板 (更新版)

```markdown
## Issue
#X: {title}

## 验收清单

### P0 (必须满足)
- [ ] {验收点1}
- [ ] {验收点2}

### P1 (重要)
- [ ] {验收点3}
- [ ] {验收点4}

### P2 (优化)
- [ ] {验收点5}

## 评审记录

| 阶段 | 状态 | 评审人 | 时间 |
|------|------|--------|------|
| 验收清单评审 | ✅ | Claude Code | 2026-03-23 |
| 技术方案评审 | ✅ | Claude Code | 2026-03-23 |
| 最终评审 | ⏳ | - | - |

## TDD 记录

| 阶段 | Commit | 状态 |
|------|--------|------|
| RED | abc123 | ✅ |
| GREEN | def456 | ✅ |
| REFACTOR | ghi789 | ✅ |

## 合并条件

- [x] 验收清单全部完成
- [x] TDD 流程完成
- [x] CI 通过
- [ ] 人工评审通过
```

---

## 七、Claude Code 调用方式

### 通过 OpenClaw Cron Job 触发

```yaml
# .github/workflows/tdd-trigger.yml
name: TDD Stage Trigger
on:
  issue_comment:
    types: [created]
  pull_request:
    types: [synchronize, opened]

jobs:
  trigger-claude:
    runs-on: ubuntu-latest
    steps:
      - name: Detect stage
        id: detect
        run: |
          COMMENT=${{ github.event.comment.body }}
          if [[ "$COMMENT" == *"验收清单评审结果"* ]]; then
            echo "stage=CHECKLIST_REVIEW_DONE" >> $GITHUB_OUTPUT
          elif [[ "$COMMENT" == *"TDD RED: 完成"* ]]; then
            echo "stage=RED_DONE" >> $GITHUB_OUTPUT
          elif [[ "$COMMENT" == *"Design Review: 完成"* ]]; then
            echo "stage=DESIGN_REVIEW_DONE" >> $GITHUB_OUTPUT
          # ... more stages
          
      - name: Trigger next stage
        run: |
          # 调用 OpenClaw 执行下一阶段
          curl -X POST ${{ secrets.OPENCLAW_WEBHOOK }} \
            -d "stage=${{ steps.detect.outputs.stage }}"
```

### 或者通过 Supervisor 直接触发

```bash
# Supervisor 调用 Claude Code 执行评审
trigger_claude_code_review() {
    local stage=$1
    local issue_num=$2
    
    case "$stage" in
        CHECKLIST_REVIEW)
            # 构造 Prompt 并调用 Claude Code
            claude -p --system "你是一个专业的技术评审专家..." << EOF
            评审 Issue #$issue_num 的验收清单...
            EOF
            ;;
        DESIGN_REVIEW)
            # 构造技术方案设计 Prompt
            ;;
        # ...
    esac
}
```

---

## 八、后续计划

- [ ] 实现 Supervisor v2 (带评审状态机)
- [ ] 创建各阶段 Claude Code Prompt 模板
- [ ] 配置 GitHub Actions 自动触发
- [ ] 测试完整流程

---

## Changelog

| 日期 | 版本 | 描述 |
|------|------|------|
| 2026-03-23 | v1.0.0 | 初始版本 |
| 2026-03-23 | v1.1.0 | 添加验收清单评审和技术方案评审阶段 |


---

## 九、最终评审 (Final Review) 详细实现

详细实现待补充，包括：
- 自动检查脚本 (final_review.sh)
- 检查函数 (check_stage_complete, run_acceptance_tests, check_ci_status 等)
- Claude Code 最终确认 Prompt
- 人工确认流程
- 合并条件检查清单

是否需要我继续完善这部分？


---

## 九、最终评审 (Final Review) 详细实现

### 9.1 最终评审流程图

```
REFACTOR_DONE
    │
    ▼
┌───────────────────────────────────────┐
│ 5.1 自动检查 (Supervisor)              │
│ • 检查所有阶段完成状态                 │
│ • 运行验收测试                        │
│ • 检查 CI 状态                        │
│ • 检查评审记录                         │
└───────────────────────────────────────┘
    │ 检查结果
    ▼
┌───────────────────────────────────────┐
│ 5.2 Claude Code 最终确认               │
│ • 确认验收清单全部满足                │
│ • 确认无 blocking issues             │
│ • 生成最终评审报告                    │
└───────────────────────────────────────┘
    │ 确认结果
    ▼
┌───────────────────────────────────────┐
│ 5.3 合并决策                          │
│ P0-P1: 需要人工确认                   │
│ P2:   Supervisor 自动合并             │
│ P3:   自动合并                       │
└───────────────────────────────────────┘
    │
    ▼
MERGED / NEEDS_WORK
```

### 9.2 自动检查脚本 (Supervisor)

```bash
#!/bin/bash
# scripts/tdd/final_review.sh

final_review() {
    local issue_num=$1
    local pr_num=$2
    
    log "=== 最终评审: Issue #$issue_num ==="
    
    # 检查阶段完成状态
    local stages=("checklist-review" "red" "design-review" "green" "refactor")
    for stage in "${stages[@]}"; do
        if ! check_stage_complete "$issue_num" "$stage"; then
            log "X 阶段 $stage 未完成"
            return 1
        fi
    done
    
    # 运行验收测试
    if ! run_acceptance_tests "$issue_num"; then
        log "X 验收测试失败"
        return 1
    fi
    
    # 检查 CI 状态
    if ! check_ci_status "$pr_num"; then
        log "X CI 未通过"
        return 1
    fi
    
    # 检查合并冲突
    if ! check_mergeable "$pr_num"; then
        log "X 有合并冲突"
        return 1
    fi
    
    # 检查评审记录
    if ! check_review_comments "$issue_num"; then
        log "X 评审记录不足"
        return 1
    fi
    
    # 根据优先级决策
    local priority=$(get_issue_priority "$issue_num")
    
    case "$priority" in
        P0|P1)
            request_human_review "$issue_num" "$pr_num"
            ;;
        P2|P3)
            auto_merge "$pr_num"
            ;;
    esac
}
```

### 9.3 详细检查函数

```bash
# 检查某阶段是否完成
check_stage_complete() {
    local issue_num=$1
    local stage=$2
    gh issue comments "$issue_num" | grep -q "Status.*$stage.*done" && return 0 || return 1
}

# 运行验收测试
run_acceptance_tests() {
    local issue_num=$1
    bash "modules/core/tests/test_$issue_num.sh"
}

# 检查 CI 状态
check_ci_status() {
    local pr_num=$1
    local failed=$(gh pr checks "$pr_num" --json conclusion | jq -r '.[] | select(.conclusion=="failure") | .id' | wc -l)
    [[ $failed -eq 0 ]]
}

# 检查是否可以合并
check_mergeable() {
    local pr_num=$1
    gh pr view "$pr_num" --json mergeable | jq -qr '.mergeable' | grep -q true
}

# 检查评审记录
check_review_comments() {
    local issue_num=$1
    local count=$(gh issue comments "$issue_num" | grep -c "验收清单评审|技术方案评审")
    [[ $count -ge 2 ]]
}

# 获取 Issue 优先级
get_issue_priority() {
    local issue_num=$1
    gh issue view "$issue_num" --json labels | jq -r '.labels[] | select(.name | startswith("P")) | .name' | head -1 || echo "P3"
}
```

### 9.4 Claude Code 最终确认 Prompt

```bash
trigger_final_review() {
    local issue_num=$1
    claude -p --model minimax/MiniMax-M2.7 << 'EOF'
## 任务：最终评审 Issue #$issue_num

### 请确认：

1. **验收清单** - P0/P1 全部满足？
2. **代码质量** - 规范/安全/性能
3. **测试覆盖** - 是否充分

### 输出格式
---
## 最终评审报告

### 结论
可以合并 / 需要修改

### 建议
{如有}
---
EOF
}
```

### 9.5 人工确认流程 (P0/P1)

```bash
request_human_review() {
    local issue_num=$1
    local pr_num=$2
    
    gh issue comment "$issue_num" --body "
## 最终评审待确认

Issue #$issue_num 已完成 TDD 流程，请确认：

- [ ] P0 验收清单满足
- [ ] P1 验收清单满足  
- [ ] 无安全问题

回复: LGTM 合并 / NEEDS_CHANGE 说明原因
"
}
```

### 9.6 合并条件检查清单

| # | 检查项 | 方法 | 失败处理 |
|---|--------|------|----------|
| 1 | 阶段完成 | check_stage_complete | 继续等待 |
| 2 | 验收测试 | run_acceptance_tests | 通知修复 |
| 3 | CI通过 | check_ci_status | 继续等待 |
| 4 | 无冲突 | check_mergeable | 通知解决 |
| 5 | 评审记录 | check_review_comments | 继续等待 |
| 6 | 人工确认(P0/P1) | request_human_review | 等待确认 |

---

## Changelog

| 日期 | 版本 | 描述 |
|------|------|------|
| 2026-03-23 | v1.0.0 | 初始版本 |
| 2026-03-23 | v1.1.0 | 添加验收清单评审和技术方案评审阶段 |
| 2026-03-23 | v1.2.0 | 细化 FINAL_REVIEW 详细实现 |
