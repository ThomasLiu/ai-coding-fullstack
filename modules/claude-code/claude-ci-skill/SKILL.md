# Claude CI Skill

基于 Claude Code `--bare` flag 的零开销 CI 自动化工具。

## 特性

- `--bare` 模式：跳过 hooks/LSP/插件同步，启动时间 <500ms
- 标准化 CI 模板
- 批量代码审查
- 自动化测试生成
- 文档生成

## 快速开始

```bash
# 代码审查
claude -p --bare --system "$(cat << 'EOF'
Review this PR for security issues and code quality.
Focus on: SQL injection, XSS, authentication bypass.
EOF
)" < context.txt

# 测试生成
claude -p --bare --system "Generate unit tests for this function" < code.py
```

## 脚本

| 脚本 | 用途 |
|------|------|
| `scripts/review.sh` | 代码审查模板 |
| `scripts/test-gen.sh` | 测试生成模板 |
| `scripts/doc-gen.sh` | 文档生成模板 |

## CI 模板

### GitHub Actions

```yaml
- name: Claude Code Review
  run: |
    cat > context.txt << 'EOF'
    ${{ github.event.pull_request.body }}
    EOF
    claude -p --bare --system 'Review code for issues' < context.txt
```

## 测试

```bash
bash tests/review_test.sh
```
