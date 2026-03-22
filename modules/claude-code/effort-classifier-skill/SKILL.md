# Effort Classifier Skill

基于 Claude Code effort frontmatter 的分级 Skill 系统。

## 背景

Claude Code v2.1.81 新增 effort frontmatter 支持，Skills/slash commands 可覆盖模型 effort 级别。

## 特性

- 关键词分析自动分类
- 三级 effort 分层：low / medium / high
- 支持 frontmatter 格式输出
- 自动生成带 effort 标记的 skill 文件

## Effort 分级标准

| 级别 | 场景 | 预估 token | 示例 |
|------|------|-----------|------|
| low | 补全、注释、简单修复 | < 1k | 添加注释，修复 typo |
| medium | 功能实现、测试、API 开发 | 1k-5k | 实现用户认证，编写单元测试 |
| high | 重构、架构设计、系统迁移 | > 5k | 微服务拆分，数据库迁移 |

## 使用方式

### 命令行分类

```bash
# 分类任务
./scripts/classify.sh --task "Add validation to form"

# 输出 frontmatter 格式
./scripts/classify.sh --task "Implement JWT auth" --format frontmatter
```

### 生成 Skill 文件

```bash
# 生成 medium effort 的 skill
./scripts/generate-skill.sh --name "auth-skill" --effort medium --output ./skills

# 生成 low effort 的 quick-fix skill
./scripts/generate-skill.sh --name "quick-fix" --effort low
```

### 集成到 Claude Code

```bash
# 使用 effort frontmatter
claude -p --effort high << 'EOF'
Redesign the microservices architecture...
EOF
```

## 脚本

| 脚本 | 用途 |
|------|------|
| `scripts/classify.sh` | 任务 effort 分类器 |
| `scripts/generate-skill.sh` | 自动生成 skill 文件 |

## 测试

```bash
./tests/effort_test.sh
```

## 集成规划

- [ ] 与 skill-creator 集成，自动分析任务复杂度
- [ ] 支持 token 计数精确估算
- [ ] 支持批量任务分类
