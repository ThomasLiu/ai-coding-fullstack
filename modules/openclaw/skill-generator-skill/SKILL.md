# OpenClaw Skill 自动生成与追踪系统

## Overview

自动追踪 OpenClaw 和 Claude Code 的 changelog，分析新功能，并自动生成 Skill 草稿。

## Trigger

- `skill-generator`
- `generate-skill`
- `track-changes`
- `skill-tracker`

## Usage

```bash
# Parse skill spec structure
./scripts/parse-skill-spec.sh --sample

# Track Claude Code CLI parameters
./scripts/track-claude-params.sh --check
./scripts/track-claude-params.sh --json

# Generate skill from spec
./scripts/generate-skill.sh spec.json

# Generate skill from CLI parameter
./scripts/generate-skill.sh param.json --from-cli-param

# Generate skill from changelog entry
./scripts/generate-skill.sh changelog.json --from-changelog

# Monitor changelogs
./scripts/monitor-changelogs.sh --check openclaw
./scripts/monitor-changelogs.sh --check claude-code --json
./scripts/monitor-changelogs.sh --all

# Generate all skill drafts
./scripts/generate-drafts.sh
```

## Modules

### 1. parse-skill-spec.sh

Parse OpenClaw skill specification and validate structure.

**Required Fields:**
- `name` - Skill identifier (kebab-case)
- `description` - What the skill does
- `trigger` - Keyword to activate skill
- `tools` - Available tools (read, write, exec, etc.)

### 2. track-claude-params.sh

Track Claude Code CLI parameters and detect new additions.

**Known Parameters:**
- `--bare` - Skip hooks/LSP sync, zero-overhead CI
- `--channels` - Remote device control via phone
- `--effort` - Set task effort level (low/medium/high)
- `--model` - Specify model to use
- `--resume` - Resume from previous session
- `--max-tokens` - Maximum tokens in response

### 3. generate-skill.sh

Auto-generate OpenClaw skill from specification.

**Modes:**
- `--from-cli-param` - Generate from CLI parameter spec
- `--from-changelog` - Generate from changelog entry
- `--output-dir` - Write skill files to directory

### 4. monitor-changelogs.sh

Monitor changelogs for OpenClaw and Claude Code.

**Sources:**
- OpenClaw releases (GitHub)
- Claude Code releases (GitHub)

### 5. generate-drafts.sh

Generate multiple skill drafts from changelog monitoring.

## Config

- `config/sources.conf` - Change log source URLs
- `config/claude-params.json` - Known Claude Code parameters

## TDD Tests

```bash
./tests/skill_generator_test.sh
# Expected: 19/19 tests passed
```

## Output

Generates skill drafts in YAML frontmatter format:

```yaml
---
name: mcp-collapsible-tools
description: Skill for MCP collapsible tools feature
trigger: mcp-collapsible-tools
tools:
  - read
  - exec
  - web_fetch
---

# mcp-collapsible-tools

## Source

- Product: claude-code
- Version: v2.1.81
- Change: MCP read/search tools collapsible display
```

## Related

- Issue #15: OpenClaw Skill 自动生成与追踪系统
- OpenClaw release notes monitoring
- Claude Code changelog tracking
