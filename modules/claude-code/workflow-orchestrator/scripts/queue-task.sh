#!/bin/bash
# 添加任务到队列
# Usage: queue-task.sh --queue-dir <dir> --template <name> --priority <level>

set -e

QUEUE_DIR="/tmp/workflow-queue"
TEMPLATE=""
PRIORITY="medium"
TASK_ID=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --queue-dir)
            QUEUE_DIR="$2"
            shift 2
            ;;
        --template)
            TEMPLATE="$2"
            shift 2
            ;;
        --priority)
            PRIORITY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# 创建队列目录
mkdir -p "$QUEUE_DIR/tasks"

# 生成任务 ID
TASK_ID="task-$(date +%s)-$$"

# 创建任务文件
TASK_FILE="$QUEUE_DIR/tasks/$TASK_ID.json"
cat > "$TASK_FILE" << EOF
{
  "id": "$TASK_ID",
  "template": "$TEMPLATE",
  "priority": "$PRIORITY",
  "status": "pending",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "$TASK_ID"
