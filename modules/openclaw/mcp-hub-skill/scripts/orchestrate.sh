#!/bin/bash
# MCP 编排脚本 - 多 server 协同调用
# Usage: orchestrate.sh --mode <mode> --tasks <task1,task2,...>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CALL_TOOL="${SCRIPT_DIR}/call-tool.sh"

show_help() {
    cat << EOF
MCP Orchestrator - 编排多个 MCP Server 任务

Usage:
    orchestrate.sh --mode <mode> --tasks <tasks>
    orchestrate.sh --list-modes
    orchestrate.sh --help

Modes:
    sequential   - 按顺序执行任务（前一个失败则停止）
    parallel      - 并行执行所有任务
    fallback      - 依次尝试，第一个成功的为止

Tasks:
    格式: server:tool:args
    示例: github:list-repos
          filesystem:read-file:/path/to/file

Examples:
    orchestrate.sh --mode sequential --tasks "github:list-repos,filesystem:read-file:/tmp/test.txt"
    orchestrate.sh --mode parallel --tasks "github:list-repos,github:list-repos"
    orchestrate.sh --mode fallback --tasks "chrome:search,github:search"

EOF
}

list_modes() {
    echo "sequential parallel fallback"
}

# 解析参数
MODE=""
TASKS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            MODE="$2"
            shift 2
            ;;
        --tasks)
            TASKS="$2"
            shift 2
            ;;
        --list-modes)
            list_modes
            exit 0
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

if [[ -z "$MODE" ]]; then
    echo "Error: --mode is required" >&2
    exit 1
fi

if [[ -z "$TASKS" ]]; then
    echo "Error: --tasks is required" >&2
    exit 1
fi

# 验证 mode
VALID_MODES="sequential parallel fallback"
if ! echo "$VALID_MODES" | grep -qw "$MODE"; then
    echo "Error: invalid mode '$MODE'. Valid: $VALID_MODES" >&2
    exit 1
fi

# 解析任务
IFS=',' read -ra TASK_ARRAY <<< "$TASKS"

run_sequential() {
    local results=()
    for task in "${TASK_ARRAY[@]}"; do
        IFS=':' read -ra PARTS <<< "$task"
        local server="${PARTS[0]}"
        local tool="${PARTS[1]}"
        local args="${PARTS[*]:2}"

        echo "Running: $server:$tool" >&2
        result=$("$CALL_TOOL" "$server" "$tool" $args 2>&1) || {
            echo "Task failed: $server:$tool" >&2
            echo "{\"error\":\"task failed\",\"task\":\"$task\"}"
            return 1
        }
        results+=("$result")
    done
    printf '%s\n' "${results[@]}"
}

run_parallel() {
    local pids=()
    local results=()
    local tmpdir=$(mktemp -d)

    for task in "${TASK_ARRAY[@]}"; do
        IFS=':' read -ra PARTS <<< "$task"
        local server="${PARTS[0]}"
        local tool="${PARTS[1]}"
        local args="${PARTS[*]:2}"
        local index=${#pids[@]}

        ("$CALL_TOOL" "$server" "$tool" $args > "$tmpdir/result_$index" 2>&1) &
        pids+=($!)
    done

    # 等待所有完成
    for pid in "${pids[@]}"; do
        wait $pid
    done

    # 收集结果
    for i in "${!pids[@]}"; do
        if [[ -f "$tmpdir/result_$i" ]]; then
            cat "$tmpdir/result_$i"
        fi
    done
    rm -rf "$tmpdir"
}

run_fallback() {
    for task in "${TASK_ARRAY[@]}"; do
        IFS=':' read -ra PARTS <<< "$task"
        local server="${PARTS[0]}"
        local tool="${PARTS[1]}"
        local args="${PARTS[*]:2}"

        echo "Trying: $server:$tool" >&2
        result=$("$CALL_TOOL" "$server" "$tool" $args 2>&1) && {
            echo "$result"
            return 0
        }
        echo "Failed, trying next..." >&2
    done
    echo "{\"error\":\"all fallback tasks failed\"}" >&2
    return 1
}

# 执行编排
case "$MODE" in
    sequential) run_sequential ;;
    parallel)   run_parallel ;;
    fallback)   run_fallback ;;
esac
