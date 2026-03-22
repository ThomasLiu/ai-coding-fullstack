#!/bin/bash
# 生成浏览器自动化任务配置
# Usage: generate-browser-task.sh --task <desc> --agent <name>

set -e

TASK=""
AGENT="claude"

while [[ $# -gt 0 ]]; do
    case $1 in
        --task)
            TASK="$2"
            shift 2
            ;;
        --agent)
            AGENT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [ -z "$TASK" ]; then
    echo "Error: --task required" >&2
    exit 1
fi

cat << EOF
{
  "task": "$TASK",
  "agent": "$AGENT",
  "browser": {
    "headless": true,
    "viewport": { "width": 1920, "height": 1080 }
  },
  "steps": [
    { "action": "navigate", "target": "auto" },
    { "action": "execute", "task": "$TASK" }
  ]
}
EOF
