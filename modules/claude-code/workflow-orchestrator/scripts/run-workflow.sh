#!/bin/bash
# Workflow Orchestrator 主脚本
# Usage: run-workflow.sh --template <name> [--dry-run]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

show_help() {
    cat << EOF
Workflow Orchestrator - Claude Code + MCP Automation

Usage:
    run-workflow.sh --template <name> [options]
    run-workflow.sh --help

Options:
    --template <name>    工作流模板 (crud, test, deploy, docs)
    --dry-run            模拟运行，不执行实际操作
    --loop               生成 /Loop 配置并启用循环执行
    --interval <sec>     循环间隔（秒），默认 60

Examples:
    run-workflow.sh --template crud
    run-workflow.sh --template test --dry-run
    run-workflow.sh --template deploy --loop --interval 300

Templates:
    crud    - Create/Read/Update/Delete workflow
    test    - Test automation (unit/integration/e2e)
    deploy  - Deployment pipeline
    docs    - Documentation generation

EOF
}

TEMPLATE=""
DRY_RUN=false
ENABLE_LOOP=false
INTERVAL=60

while [[ $# -gt 0 ]]; do
    case $1 in
        --template)
            TEMPLATE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --loop)
            ENABLE_LOOP=true
            shift
            ;;
        --interval)
            INTERVAL="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [ -z "$TEMPLATE" ]; then
    echo "Error: --template required" >&2
    show_help >&2
    exit 1
fi

# 验证模板
VALID_TEMPLATES="crud test deploy docs"
if ! echo "$VALID_TEMPLATES" | grep -qw "$TEMPLATE"; then
    echo "Error: invalid template '$TEMPLATE'" >&2
    echo "Valid templates: $VALID_TEMPLATES" >&2
    exit 1
fi

if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] Would execute workflow: $TEMPLATE"
    if [ "$ENABLE_LOOP" = true ]; then
        echo "[DRY-RUN] Loop enabled with interval: ${INTERVAL}s"
    fi
    "$SCRIPT_DIR/show-template.sh" "$TEMPLATE"
    exit 0
fi

# 显示模板信息
echo "Executing workflow: $TEMPLATE"
"$SCRIPT_DIR/show-template.sh" "$TEMPLATE"

if [ "$ENABLE_LOOP" = true ]; then
    echo ""
    echo "Generating /Loop configuration..."
    "$SCRIPT_DIR/generate-loop-config.sh" --template "$TEMPLATE" --interval "$INTERVAL"
fi

echo ""
echo "Workflow '$TEMPLATE' queued for execution."
