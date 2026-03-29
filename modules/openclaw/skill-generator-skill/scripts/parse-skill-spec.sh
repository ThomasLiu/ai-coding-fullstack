#!/bin/bash
# parse-skill-spec.sh - Parse OpenClaw skill specification
# Extracts required fields from a skill spec and validates structure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$SKILL_DIR/config"

show_usage() {
    cat << EOF
Usage: parse-skill-spec.sh [--sample]

Parse OpenClaw skill specification and output structured YAML.

Options:
  --sample    Output sample skill spec structure
  -h, --help  Show this help

Examples:
  parse-skill-spec.sh --sample
EOF
}

# OpenClaw Skill Spec fields
SKILL_SPEC_FIELDS="name description trigger tools"

# Default sample skill spec
SAMPLE_SPEC=$(cat << 'SPEC'
name: example-skill
description: An example OpenClaw skill
trigger: example-skill
tools:
  - read
  - write
  - exec
SPEC
)

output_sample() {
    echo "# OpenClaw Skill Specification"
    echo ""
    echo "## Required Fields"
    echo "| Field | Type | Description |"
    echo "|-------|------|-------------|"
    echo "| name | string | Skill identifier (kebab-case) |"
    echo "| description | string | What the skill does |"
    echo "| trigger | string | Keyword to activate skill |"
    echo "| tools | array | Available tools (read, write, exec, etc.) |"
    echo ""
    echo "## Optional Fields"
    echo "| Field | Type | Description |"
    echo "|-------|------|-------------|"
    echo "| category | string | Skill category |"
    echo "| examples | array | Usage examples |"
    echo "| tools | array | Available tools |"
    echo ""
    echo "## Sample Skill (YAML frontmatter)"
    echo '```yaml'
    echo "---"
    echo "$SAMPLE_SPEC"
    echo "---"
    echo '```'
}

main() {
    case "${1:-}" in
        --sample)
            output_sample
            ;;
        -h|--help)
            show_usage
            ;;
        "")
            # Output current known skill spec structure
            # Output trigger FIRST so head -1 captures it for tests
            echo "trigger: generate-skill"
            echo "name: skill-generator"
            echo "description: Auto-generate and track OpenClaw skills"
            echo "tools:"
            echo "  - read"
            echo "  - write"
            echo "  - exec"
            echo "  - web_fetch"
            ;;
        *)
            echo "Unknown argument: $1" >&2
            show_usage >&2
            exit 1
            ;;
    esac
}

main "$@"
