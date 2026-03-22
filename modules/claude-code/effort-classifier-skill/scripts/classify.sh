#!/bin/bash
# classify.sh - Effort Frontmatter Classifier
# Analyzes task complexity and determines appropriate effort level

set -e

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Classify task effort level based on complexity analysis.

OPTIONS:
    --task <text>       Task description to classify
    --format <format>   Output format: text (default) or frontmatter
    --help              Show this help message

EFFORT LEVELS:
    low     < 1k tokens  - Quick tasks (comments, simple fixes,补全)
    medium  1k-5k tokens - Moderate tasks (feature implementation, tests)
    high    > 5k tokens  - Complex tasks (refactoring, architecture design)

EXAMPLES:
    $(basename "$0") --task "Add validation to form"
    $(basename "$0") --task "Implement auth system" --format frontmatter

EOF
}

# Keyword-based classification (simple heuristic)
classify_by_keywords() {
    local task="$1"
    local lower_task
    lower_task=$(echo "$task" | tr '[:upper:]' '[:lower:]')

    # HIGH effort keywords
    local high_kw="redesign|重构|架构|migration|迁移|重构|entire|整个|complete|全面|microservices|微服务|distributed|分布式|system design|系统设计"
    if echo "$lower_task" | grep -qE "$high_kw"; then
        echo "high"
        return
    fi

    # MEDIUM effort keywords
    local medium_kw="implement|实现|功能|feature|authentication|授权|jwt|oauth|api|接口|integration|集成|测试|test|refactor|优化|database|数据库|middleware"
    if echo "$lower_task" | grep -qE "$medium_kw"; then
        echo "medium"
        return
    fi

    # LOW effort (default)
    echo "low"
}

# Estimate token count (rough heuristic: ~4 chars per token)
estimate_tokens() {
    local text="$1"
    local char_count
    char_count=${#text}
    echo $((char_count / 4))
}

# Get effort description
effort_description() {
    local level="$1"
    case "$level" in
        low)
            echo "Quick task - simple changes, comments, small fixes"
            ;;
        medium)
            echo "Moderate task - feature work, tests, moderate refactoring"
            ;;
        high)
            echo "Complex task - architecture, large refactoring, migrations"
            ;;
    esac
}

# Generate frontmatter
generate_frontmatter() {
    local level="$1"
    cat << EOF
---
effort: $level
created: $(date +%Y-%m-%d)
description: "$(effort_description "$level")"
---
EOF
}

# Main
main() {
    local task=""
    local format="text"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --task)
                task="$2"
                shift 2
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
    done

    if [[ -z "$task" ]]; then
        echo "Error: --task is required" >&2
        usage >&2
        exit 1
    fi

    local level
    level=$(classify_by_keywords "$task")

    if [[ "$format" == "frontmatter" ]]; then
        generate_frontmatter "$level"
    else
        echo "effort: $level"
        echo "description: $(effort_description "$level")"
        echo "estimated_tokens: $(estimate_tokens "$task")"
    fi
}

main "$@"
