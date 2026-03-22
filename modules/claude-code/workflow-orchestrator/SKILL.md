# Workflow Orchestrator Skill - Claude Code + MCP 工作流编排器

## 概述

自动化工作流编排器，通过模板化配置 + /Loop + Subagent 实现编码任务的自动化流水线。

## 核心能力

- **工作流模板** - 内置 CRUD/Test/Deploy/Docs 模板
- **/Loop + Subagent 组合** - 周期性任务自动化
- **Browser Use CLI 2.0 集成** - 端到端浏览器自动化
- **任务队列** - 状态追踪和队列管理

## 架构

```
Workflow Orchestrator
├── Templates (模板定义)
│   ├── crud.yaml     - 创建/读取/更新/删除
│   ├── test.yaml     - 单元/集成测试
│   ├── deploy.yaml   - 部署流水线
│   └── docs.yaml     - 文档生成
├── /Loop Config      - 周期执行配置
├── Subagent Pool     - 并行任务池
└── Browser Use CLI   - 浏览器自动化
```

## 脚本说明

| 脚本 | 功能 |
|------|------|
| `scripts/list-templates.sh` | 列出所有可用模板 |
| `scripts/show-template.sh <name>` | 显示模板详情 |
| `scripts/generate-loop-config.sh` | 生成 /Loop 配置 |
| `scripts/generate-browser-task.sh` | 生成浏览器任务 |
| `scripts/queue-task.sh` | 添加任务到队列 |
| `scripts/get-task-status.sh` | 查询任务状态 |
| `scripts/update-task-status.sh` | 更新任务状态 |
| `scripts/list-queued-tasks.sh` | 列出队列任务 |
| `scripts/check-browser-use.sh` | 检测 Browser Use CLI |
| `scripts/run-workflow.sh` | 运行工作流 |

## 子任务进度

- [x] 分析日常高频编码任务，归纳为工作流模板
- [x] 设计 /Loop + Subagent 组合的配置文件格式
- [x] 集成 Browser Use CLI 2.0 到编排流程
- [x] 实现简单的任务队列和状态追踪

## 标签

- claude-code
- workflow
- automation
- mcp
