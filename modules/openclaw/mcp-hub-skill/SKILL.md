# MCP Hub Skill - MCP 集成中枢

## 概述

以 OpenClaw 为总控，构建统一管理多个 MCP Server 的集成中枢，实现总控 + 执行的双层 Agent 架构。

## 核心能力

- **MCP Server 发现与注册** - 统一管理 Chrome、GitHub、Filesystem、Memory 等 MCP Server
- **工具调用路由** - 标准化 MCP 工具调用接口
- **会话共享机制** - OpenClaw 与 Claude Code 之间共享会话上下文
- **编排引擎** - 支持 sequential / parallel / fallback 多种编排模式

## 架构

```
OpenClaw (总控层)
    ├── MCP Hub (编排层)
    │   ├── Chrome MCP (浏览器自动化)
    │   ├── GitHub MCP (代码管理)
    │   ├── Filesystem MCP (文件系统)
    │   └── Memory MCP (记忆系统)
    └── Claude Code (执行层)
```

## 脚本说明

| 脚本 | 功能 |
|------|------|
| `scripts/list-servers.sh` | 列出已注册的 MCP Server |
| `scripts/check-server.sh <name>` | 检查 server 状态 |
| `scripts/call-tool.sh <server> <tool> [args]` | 调用 MCP 工具 |
| `scripts/orchestrate.sh --mode <mode> --tasks <tasks>` | 多工具编排 |
| `scripts/share-session.sh --export/--import <id>` | 会话共享 |
| `scripts/hub-init.sh` | 初始化 Hub |
| `scripts/hub-status.sh` | 查看 Hub 状态 |
| `scripts/hub-validate.sh` | 验证配置 |

## 使用示例

### 列出可用 Server
```bash
bash scripts/list-servers.sh
# chrome,github,filesystem,memory
```

### 调用 GitHub 工具
```bash
bash scripts/call-tool.sh github list-repos
```

### 编排多个任务
```bash
bash scripts/orchestrate.sh --mode sequential --tasks "github:list-repos,filesystem:read-file:/tmp/test.txt"
bash scripts/orchestrate.sh --mode parallel --tasks "github:list-repos,github:list-repos"
```

### 会话共享
```bash
# 导出当前会话
bash scripts/share-session.sh --export my-session

# 在 Claude Code 中导入
bash scripts/share-session.sh --import my-session
```

## 子任务进度

- [x] 调研已有 MCP Server 能力
- [x] 设计 OpenClaw Skill 作为 MCP 编排层
- [x] 实现 Claude Code 与 OpenClaw 会话共享机制
- [x] 产出可用的 MCP 编排 skill 示例

## 标签

- openclaw
- mcp
- integration
- automation
