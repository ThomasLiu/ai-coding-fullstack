#!/bin/bash
# 生成 /Loop 配置文件
# Usage: generate-loop-config.sh --template <name> --interval <seconds>

set -e

TEMPLATE=""
INTERVAL=60

while [[ $# -gt 0 ]]; do
    case $1 in
        --template)
            TEMPLATE="$2"
            shift 2
            ;;
        --interval)
            INTERVAL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [ -z "$TEMPLATE" ]; then
    echo "Error: --template required" >&2
    exit 1
fi

cat << EOF
{
  "template": "$TEMPLATE",
  "interval": $INTERVAL,
  "enabled": true,
  "mode": "sequential",
  "subagent": {
    "enabled": true,
    "maxConcurrency": 3
  }
}
EOF
