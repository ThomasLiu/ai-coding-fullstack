#!/bin/bash
# track-claude-params.sh - Track Claude Code CLI parameters
# Lists known parameters, checks for new ones, outputs in various formats

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$SKILL_DIR/config/claude-params.json"

show_usage() {
    cat << EOF
Usage: track-claude-params.sh [OPTIONS]

Track Claude Code CLI parameters from config.

Options:
  --check      Check and list known parameters
  --json       Output in JSON format
  --param NAME Show details for specific parameter
  -h, --help   Show this help

Examples:
  track-claude-params.sh --check
  track-claude-params.sh --json
  track-claude-params.sh --param bare
EOF
}

# Parse JSON config for parameters
list_params() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "ERROR: Config file not found: $CONFIG_FILE" >&2
        exit 1
    fi
    
    local format="${1:-text}"
    
    if [[ "$format" == "json" ]]; then
        cat "$CONFIG_FILE"
    else
        # Text format - list parameter names
        local params=$(grep -o '"name": "[^"]*"' "$CONFIG_FILE" | sed 's/"name": "//;s/"//g')
        for param in $params; do
            echo "$param"
        done
    fi
}

show_param() {
    local name="$1"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "ERROR: Config file not found" >&2
        exit 1
    fi
    
    # Extract param details (basic grep-based parsing)
    local found=false
    local line=""
    while IFS= read -r line; do
        if echo "$line" | grep -q "\"name\".*--$name"; then
            found=true
            echo "$line"
        elif $found; then
            if echo "$line" | grep -q "}"; then
                break
            fi
            echo "$line"
        fi
    done < "$CONFIG_FILE"
    
    $found || echo "Parameter --$name not found"
}

main() {
    case "${1:-}" in
        --check)
            list_params "text"
            ;;
        --json)
            list_params "json"
            ;;
        --param)
            show_param "${2:-}"
            ;;
        -h|--help)
            show_usage
            ;;
        "")
            # Default: list all params
            list_params "text"
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_usage >&2
            exit 1
            ;;
    esac
}

main "$@"
