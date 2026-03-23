# AI Coding Fullstack TDD + 验收流程设计方案

**版本**: v1.0.0
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
│  4. 触发 Claude Code 执行 TDD                                      │
│  5. 检查验收状态                                                    │
│  6. 决策合并                                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Claude Code (执行器)                              │
├─────────────────────────────────────────────────────────────────┤
│  职责：                                                              │
│  1. TDD RED - 阅读 Issue，编写验收测试                             │
│  2. TDD GREEN - 实现功能让测试通过                                 │
│  3. TDD REFACTOR - 重构优化                                        │
│  4. 基于 SPEC.md 更新验收清单                                        │
│  5. 提交代码更新                                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GitHub PR + Projects                            │
├─────────────────────────────────────────────────────────────────┤
│  状态机：                                                             │
│  draft → review → approved → merged                                 │
│                                                                   │
│  Project Fields:                                                   │
│  - Status (todo/in-progress/review/approved/done)                 │
│  - Priority (P0/P1/P2/P3)                                         │
│  - 评审阶段 (office-hours/ceo/eng/design)                        │
│  - 验收标准 (checklist)                                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 三、TDD 完整流程

### 阶段 1：选 Issue + 初始化 (Supervisor)

```bash
# 1. 检查状态
if (state == working) {
    check_pr_status(current_issue)
    if (PR is open) skip
    if (PR is merged) reset_state
}

# 2. 选择 Issue
next_issue = select_next_issue()  # 跳过已有 PR 的

# 3. 创建 PR (状态: draft)
create_pr_draft(next_issue)
update_state(working, next_issue)

# 4. 触发 Claude Code
trigger_claude_code_tdd(next_issue)
```

### 阶段 2：TDD RED + GREEN + REFACTOR (Claude Code)

#### RED (验收测试)

```
1. 阅读 Issue 详情 + SPEC.md 相关章节
2. 编写 bash 测试脚本 (验收标准)
3. 运行测试确认失败
4. 提交: "TDD RED: 验收测试 for #X"
5. 更新 PR 描述: 添加验收清单
```

#### GREEN (实现)

```
1. 基于 SPEC.md 设计方案
2. 实现最小功能
3. 运行测试确认通过
4. 提交: "TDD GREEN: 实现 #X"
```

#### REFACTOR (重构)

```
1. 检查代码质量和规范
2. 重构优化
3. 运行测试确认通过
4. 提交: "TDD REFACTOR: 重构 #X"
5. 更新 PR 状态 → review
```

### 阶段 3：验收 + 评审 (Supervisor + 人工)

#### 验收检查 (Supervisor)

```
1. 运行测试确认通过
2. 检查所有验收标准是否满足
3. 更新 PR 状态 → pending_review
4. 通知评审者
```

#### 分层评审 (基于 SPEC.md)

| 优先级 | 评审流程 |
|--------|----------|
| P0-P1 | Office Hours → CEO → Eng → Design (完整流程) |
| P2 | 简化为 Eng Review only |
| P3 | self-approve (有测试即可，24h 无 objection 自动合并) |

#### 合并决策

**必须满足**：
- ✅ 所有验收测试通过
- ✅ 评审通过 (或 P3 self-approve)
- ✅ 没有 blocking comments
- ✅ 分支是最新的

---

## 四、PR 模板

```markdown
## Issue
#32: [💡] 想法2: 将 /cso 安全审查能力集成到 AI Coding 自动化流水线

## 验收标准 (从 SPEC.md 提取)

### 核心功能
- [ ] 实现 /cso skill 集成
- [ ] 支持 OWASP Top 10 审计
- [ ] 支持 STRIDE 威胁建模

### 自动化
- [ ] 在 PR 创建时自动触发安全审查
- [ ] 安全问题自动报告到 PR comment

### 测试
- [ ] 有对应的验收测试
- [ ] 测试覆盖率 > 80%

## TDD 记录

### RED (2026-03-23)
- [x] 编写验收测试
- [x] 测试运行失败 ✓

### GREEN (2026-03-23)
- [x] 实现 /cso 集成
- [x] 测试运行通过 ✓

### REFACTOR (2026-03-23)
- [x] 代码重构
- [x] 规范检查通过 ✓

## 评审状态

| 阶段 | 状态 | 评审人 | 时间 |
|------|------|--------|------|
| Office Hours | ✅ | Thomas | 2026-03-23 |
| CEO Review | ⏳ | - | - |
| Eng Review | ⏳ | - | - |
| Design Review | ⏳ | - | - |

## 合并条件
- [x] 验收测试通过
- [ ] 评审通过
- [ ] 没有 blocking comments
```

---

## 五、Supervisor 完整状态机

```
┌──────────────────────────────────────────────────────────────────┐
│                         Supervisor 状态机                              │
└──────────────────────────────────────────────────────────────────┘

IDLE
  │
  ▼
SELECT_ISSUE ──────────────────────────────────────────────────────┐
  │                                                                  │
  ▼                                                                  │
ISSUE_SELECTED ─────────────────────────────────────────────────┐  │
  │                                                              │  │
  ▼                                                              │  │
CREATE_PR_DRAFT ───────────────────────────────────────────────┐ │  │
  │                                                            │ │  │
  ▼                                                            │ │  │
WAIT_TDD ─────────────────────────────────────────────────────┐ │ │  │
  │ (触发 Claude Code)                                         │ │ │  │
  ▼                                                            │ │ │  │
CHECK_TDD_STATUS                                                │ │ │  │
  │                                                              │ │ │  │
  ├─ TDD_IN_PROGRESS ──► WAIT_TDD (等待)                       │ │ │  │
  │                                                              │ │ │  │
  ├─ TDD_COMPLETE ──► RUN验收测试                               │ │ │  │
  │                                                              │ │ │  │
  └─ TDD_FAILED ──► MARK_FAILED ──► IDLE (需人工介入)          │ │ │  │
                                                                    │ │ │  │
                                                                    │ │ │  │
RUN验收测试 ─────────────────────────────────────────────────────┘ │ │
  │                                                                  │ │
  ├─ 测试通过 ──► PENDING_REVIEW (评审)                            │ │
  │                                                                  │ │
  └─ 测试失败 ──► TDD_FAILED ──► IDLE                             │ │
                                                                       │ │
PENDING_REVIEW ─────────────────────────────────────────────────────┘ │
  │                                                                    │
  ▼                                                                    │
分层评审 (基于优先级)                                                   │
  │                                                                    │
  ├─ P0/P1: Office Hours → CEO → Eng → Design                       │
  ├─ P2: Eng Review only                                             │
  └─ P3: self-approve (24h 无 objection)                            │
  │                                                                    │
  ▼                                                                    │
REVIEW_PASSED ─────────────────────────────────────────────────────────┐
  │                                                                   │
  ▼                                                                   │
AUTO_MERGEABLE                                                        │
  │                                                                   │
  ▼                                                                   │
MERGED ──► IDLE                                                      │
```

---

## 六、关键文件结构

```
ai-coding-fullstack/
├── SPEC.md                           # 设计规格
├── docs/
│   └── TDD-验收流程设计.md           # 本文档
├── .github/
│   └── workflows/
│       └── tdd-trigger.yml           # TDD 触发 workflow
├── scripts/
│   ├── supervisor.sh                 # 调度器
│   ├── github-utils.sh               # GitHub 操作
│   └── tdd/
│       ├── red.sh                   # TDD RED 模板
│       ├── green.sh                 # TDD GREEN 模板
│       └── refactor.sh              # TDD REFACTOR 模板
├── modules/
│   └── core/
│       ├── tests/
│       │   ├── test_32.sh          # 验收测试
│       │   └── verify_32.sh        # 验证脚本
│       └── impl/                    # 实现目录
│           └── cso-integration/
└── pr-templates/
    └── tdd-pr.md                    # PR 模板
```

---

## 七、合并条件检查脚本

```bash
#!/bin/bash
# scripts/tdd/can_merge.sh

check_can_merge() {
    local pr_num=$1
    
    # 1. 检查 CI 状态
    if ! gh pr checks "$pr_num" --all passing 2>/dev/null; then
        echo "❌ CI 未通过"
        return 1
    fi
    
    # 2. 检查评审状态
    local reviews=$(gh pr view "$pr_num" --json reviews --jq '.reviews')
    if [[ $(echo "$reviews" | jq length 2>/dev/null || echo 0) -eq 0 ]]; then
        echo "❌ 没有评审"
        return 1
    fi
    
    # 3. 检查 blocking comments
    if gh pr view "$pr_num" --json comments --jq '.comments[].body' 2>/dev/null | grep -q "BLOCKING"; then
        echo "❌ 有 blocking comments"
        return 1
    fi
    
    # 4. 检查分支状态
    if ! gh pr view "$pr_num" --json mergeable --jq '.mergeable' 2>/dev/null | grep -q true; then
        echo "❌ 分支有冲突或落后"
        return 1
    fi
    
    echo "✅ 可以合并"
    return 0
}
```

---

## 八、Supervisor v2 流程

```bash
#!/bin/bash
# scripts/supervisor_v2.sh

source "$(dirname "$0")/github-utils.sh"

main() {
    log "=== Supervisor v2 ==="
    
    local state=$(get_state)
    local current_issue=$(get_current_issue)
    
    case "$state" in
        idle)
            select_and_init_issue
            ;;
        working)
            check_tdd_status
            ;;
        pending_review)
            check_review_status
            ;;
        mergeable)
            auto_merge
            ;;
    esac
}

select_and_init_issue() {
    local next=$(select_next_issue)
    [[ -z "$next" ]] && { log "没有待处理 Issue"; return; }
    
    create_pr_draft "$next"
    update_state working "$next"
    trigger_claude_code_tdd "$next"
}

check_tdd_status() {
    local issue=$1
    
    if has_tdd_complete "$issue"; then
        if run_verify_tests "$issue"; then
            update_state pending_review "$issue"
            notify_reviewers "$issue"
        else
            update_state working "$issue"  # 让 Claude Code 继续
        fi
    else
        log "TDD 进行中..."
    fi
}
```

---

## 九、后续计划

- [ ] 实现 Supervisor v2 (状态机)
- [ ] 实现 TDD 触发 workflow
- [ ] 创建 PR 模板
- [ ] 实现合并条件检查脚本
- [ ] 配置 GitHub Project 自动化

---

## Changelog

| 日期 | 版本 | 描述 |
|------|------|------|
| 2026-03-23 | v1.0.0 | 初始版本 |
