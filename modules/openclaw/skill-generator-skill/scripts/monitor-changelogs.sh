#!/bin/bash
# monitor-changelogs.sh - Monitor change logs for OpenClaw and Claude Code
# Checks for new releases and outputs changes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$SKILL_DIR/config/sources.conf"

show_usage() {
    cat << EOF
Usage: monitor-changelogs.sh [OPTIONS]

Monitor changelogs for OpenClaw and Claude Code.

Options:
  --check SOURCE     Check specific source (openclaw, claude-code)
  --json             Output in JSON format
  --all              Check all configured sources
  -h, --help         Show this help

Examples:
  monitor-changelogs.sh --check openclaw
  monitor-changelogs.sh --check claude-code --json
  monitor-changelogs.sh --all
EOF
}

# Fetch changelog content (mock - uses cached/static data)
fetch_changelog() {
    local source="$1"
    local url="$2"
    local type="$3"
    
    # For now, return known changelog data
    # In production, this would fetch from actual URLs
    case "$source" in
        openclaw)
            cat << 'EOF'
[
  {
    "version": "v2026.3.13",
    "date": "2026-03-22",
    "changes": [
      "ACP harness thread support",
      "Improved node connection handling",
      "Security hardening features"
    ]
  }
]
EOF
            ;;
        claude-code)
            cat << 'EOF'
[
  {
    "version": "v2.1.81",
    "date": "2026-03-22",
    "changes": [
      "MCP read/search tools collapsible display (Ctrl+O)",
      "Improved tool folding"
    ]
  }
]
EOF
            ;;
        *)
            echo "[]"
            ;;
    esac
}

# Parse sources.conf
get_sources() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "openclaw|https://github.com/punkrocker/openclaw/releases|github" >&2
        echo "claude-code|https://github.com/punkrocker/claude-code/releases|github" >&2
        return
    fi
    
    grep -v '^#' "$CONFIG_FILE" | grep -v '^$' | while IFS='|' read -r name url type; do
        echo "$name|$url|$type"
    done
}

# Check a specific source
check_source() {
    local source="$1"
    local format="${2:-text}"
    
    # Find source config
    local url=""
    local type=""
    while IFS='|' read -r name url type; do
        if [[ "$name" == "$source" ]]; then
            break
        fi
    done < <(get_sources)
    
    if [[ -z "$url" ]]; then
        echo "Source not found: $source" >&2
        exit 1
    fi
    
    if [[ "$format" == "json" ]]; then
        fetch_changelog "$source" "$url" "$type"
    else
        # Text format
        echo "Source: $source"
        echo "URL: $url"
        echo ""
        fetch_changelog "$source" "$url" "$type" | grep -E '"version"|"date"|"changes"' | sed 's/[][]//g' | sed 's/"//g' | sed 's/,//g'
    fi
}

# Check all sources
check_all() {
    local format="${1:-text}"
    
    while IFS='|' read -r name url type; do
        echo "=== $name ==="
        check_source "$name" "$format"
        echo ""
    done < <(get_sources)
}

main() {
    local mode="check"
    local source=""
    local format="text"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check)
                source="$2"
                shift 2
                ;;
            --json)
                format="json"
                shift
                ;;
            --all)
                mode="all"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_usage >&2
                exit 1
                ;;
        esac
    done
    
    case "$mode" in
        all)
            check_all "$format"
            ;;
        *)
            if [[ -z "$source" ]]; then
                source="openclaw"
            fi
            check_source "$source" "$format"
            ;;
    esac
}

main "$@"
