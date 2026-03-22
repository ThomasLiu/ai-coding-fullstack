#!/bin/bash
# 显示模板详情
# Usage: show-template.sh <name>

TEMPLATE_DIR="$(cd "$(dirname "$0")/../templates" && pwd)"
TEMPLATE="$1"

if [ -z "$TEMPLATE" ]; then
    echo "Error: template name required" >&2
    exit 1
fi

# 内置模板
case "$TEMPLATE" in
    crud)
        cat << 'EOF'
name: crud
description: Create/Read/Update/Delete workflow
steps:
  - create: Generate CRUD operations
  - read: Implement read functionality
  - update: Add update endpoints
  - delete: Implement delete logic
tags: [crud, api, database]
EOF
        ;;
    test)
        cat << 'EOF'
name: test
description: Test automation workflow
types:
  - unit: Unit tests
  - integration: Integration tests
  - e2e: End-to-end tests
tags: [testing, quality]
EOF
        ;;
    deploy)
        cat << 'EOF'
name: deploy
description: Deployment pipeline
stages:
  - build: Build application
  - test: Run tests
  - push: Push to registry
  - deploy: Deploy to target
tags: [deploy, ci-cd]
EOF
        ;;
    docs)
        cat << 'EOF'
name: docs
description: Documentation generation
outputs:
  - api: API documentation
  - readme: README generation
  - changelog: Changelog update
tags: [docs, documentation]
EOF
        ;;
    *)
        TEMPLATE_FILE="$TEMPLATE_DIR/${TEMPLATE}.yaml"
        if [ -f "$TEMPLATE_FILE" ]; then
            cat "$TEMPLATE_FILE"
        else
            echo "Error: template '$TEMPLATE' not found" >&2
            exit 1
        fi
        ;;
esac
