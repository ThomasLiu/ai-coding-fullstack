# claude-ci-skill

利用 Claude Code `--bare` flag 打造零开销 CI/CD 自动化流程。

## 核心能力

`--bare` flag 使 Claude Code 跳过 hooks/LSP/插件同步，适合 CI/CD 场景：
- 启动时间：~3s → <500ms
- 适合高频率自动化任务

## 使用场景

### 1. 代码审查
```bash
claude -p --bare --system '你是一个代码审查助手' <<'EOF'
审查这个 PR 的代码质量，重点关注：
1. 安全性
2. 性能
3. 可维护性
EOF
```

### 2. 测试生成
```bash
claude -p --bare --system '基于以下代码生成测试用例' <<'EOF'
[粘贴代码]
EOF
```

### 3. 文档生成
```bash
claude -p --bare --system '为以下代码生成 API 文档' <<'EOF'
[粘贴代码]
EOF
```

## 模板脚本

| 脚本 | 用途 |
|------|------|
| `scripts/review.sh` | 代码审查模板 |
| `scripts/test-gen.sh` | 测试生成模板 |
| `scripts/doc-gen.sh` | 文档生成模板 |

## CI 集成

### GitHub Actions
参考 `.github/workflows/claude-ci.yml`

### GitLab CI
```yaml
claude-review:
  image: ghcr.io/anthropics/claude-code:latest
  script:
    - claude -p --bare --system '你是一个代码审查助手' < review_prompt.txt
```

## 性能对比

| 方式 | 启动时间 | 适用场景 |
|------|----------|----------|
| `claude -p` | ~3s | 交互式开发 |
| `claude -p --bare` | <500ms | CI/CD 批量任务 |
