#!/bin/bash
# 查询任务状态
# Usage: get-task-status.sh --queue-dir <dir> --task-id <id>

set -e

QUEUE_DIR="/tmp/workflow-queue"
TASK_ID=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --queue-dir)
            QUEUE_DIR="$2"
            shift 2
            ;;
        --task-id)
            TASK_ID="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [ -z "$TASK_ID" ]; then
    echo "Error: --task-id required" >&2
    exit 1
fi

TASK_FILE="$QUEUE_DIR/tasks/$TASK_ID.json"

if [ ! -f "$TASK_FILE" ]; then
    echo "Error: task '$TASK_ID' not found" >&2
    exit 1
fi

# 提取 status 字段
grep -o '"status": *"[^"]*"' "$TASK_FILE" | cut -d'"' -f4
