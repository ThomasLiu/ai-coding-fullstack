# AI Coding 全自动开发方案

基于 OpenClaw + Claude Code 的 AI Coding 工作流自动化方案。

## 核心架构

```
OpenClaw (调度器/控制器)
    ├── Cron Jobs (定时触发)
    ├── Skills (功能扩展)
    └── Claude Code (执行器)
```

## 定时任务

| 任务 | 频率 | 功能 |
|------|------|------|
| HuggingFace 模型监测 | 每6h | 追踪最新模型发布 |
| OpenClaw 源码同步 | 每8h | 监测框架变更 |
| Claude Code 源码同步 | 每8h | 追踪版本更新 |
| AI 新闻每日分享 | 每天10:00 | 资讯聚合+头脑风暴 |

## 提效想法

所有ideas见 [Issues](https://github.com/ThomasLiu/ai-coding-fullstack/issues)
