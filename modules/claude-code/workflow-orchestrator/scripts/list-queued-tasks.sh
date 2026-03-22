#!/bin/bash
# 列出队列中的所有任务
# Usage: list-queued-tasks.sh --queue-dir <dir>

QUEUE_DIR="/tmp/workflow-queue"

while [[ $# -gt 0 ]]; do
    case $1 in
        --queue-dir)
            QUEUE_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [ ! -d "$QUEUE_DIR/tasks" ]; then
    echo "Queue is empty"
    exit 0
fi

for task_file in "$QUEUE_DIR/tasks"/*.json; do
    if [ -f "$task_file" ]; then
        TASK_ID=$(basename "$task_file" .json)
        STATUS=$(grep -o '"status": *"[^"]*"' "$task_file" 2>/dev/null | cut -d'"' -f4 || echo "unknown")
        TEMPLATE=$(grep -o '"template": *"[^"]*"' "$task_file" 2>/dev/null | cut -d'"' -f4 || echo "unknown")
        PRIORITY=$(grep -o '"priority": *"[^"]*"' "$task_file" 2>/dev/null | cut -d'"' -f4 || echo "medium")
        echo "task: $TASK_ID | template: $TEMPLATE | priority: $PRIORITY | status: $STATUS"
    fi
done
