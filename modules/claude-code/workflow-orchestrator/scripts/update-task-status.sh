#!/bin/bash
# 更新任务状态
# Usage: update-task-status.sh --queue-dir <dir> --task-id <id> --status <status>

set -e

QUEUE_DIR="/tmp/workflow-queue"
TASK_ID=""
STATUS=""

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
        --status)
            STATUS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [ -z "$TASK_ID" ] || [ -z "$STATUS" ]; then
    echo "Error: --task-id and --status required" >&2
    exit 1
fi

TASK_FILE="$QUEUE_DIR/tasks/$TASK_ID.json"

if [ ! -f "$TASK_FILE" ]; then
    echo "Error: task '$TASK_ID' not found" >&2
    exit 1
fi

# 更新状态
sed -i.bak "s/\"status\": *\"[^\"]*\"/\"status\": \"$STATUS\"/" "$TASK_FILE"
sed -i.bak "s/\"updated_at\": *\"[^\"]*\"/\"updated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"/" "$TASK_FILE"
rm -f "$TASK_FILE.bak"

echo "Updated: $TASK_ID -> $STATUS"
