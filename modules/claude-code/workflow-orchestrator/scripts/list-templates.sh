#!/bin/bash
# 列出所有可用工作流模板
# Usage: list-templates.sh

TEMPLATE_DIR="$(cd "$(dirname "$0")/../templates" && pwd)"

if [ ! -d "$TEMPLATE_DIR" ] || [ -z "$(ls -A "$TEMPLATE_DIR"/*.yaml 2>/dev/null)" ]; then
    echo "crud,test,deploy,docs"
    exit 0
fi

ls "$TEMPLATE_DIR"/*.yaml 2>/dev/null | xargs -I {} basename {} .yaml | tr '\n' ',' | sed 's/,$//'
