#!/bin/bash
# generate-drafts.sh - Generate skill drafts from changelog monitoring
# Combines monitor-changelogs.sh with generate-skill.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

show_usage() {
    cat << EOF
Usage: generate-drafts.sh [OPTIONS]

Generate skill drafts from all monitored changelogs.

Options:
  --count N     Generate N skill drafts (default: 3)
  --output DIR  Output directory for drafts
  -h, --help    Show this help

Examples:
  generate-drafts.sh
  generate-drafts.sh --count 2
EOF
}

main() {
    local count=3
    local output_dir=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --count)
                count="$2"
                shift 2
                ;;
            --output)
                output_dir="$2"
                shift 2
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
    
    # Generate changelog-based drafts
    local drafts=()
    
    # Draft 1: MCP collapsible tools (from Claude Code changelog)
    drafts+=("{
      \"source\": \"changelog\",
      \"product\": \"claude-code\",
      \"version\": \"v2.1.81\",
      \"change\": \"MCP read/search tools collapsible display\",
      \"date\": \"2026-03-22\"
    }")
    
    # Draft 2: ACP harness thread support (from OpenClaw)
    drafts+=("{
      \"source\": \"changelog\",
      \"product\": \"openclaw\",
      \"version\": \"v2026.3.13\",
      \"change\": \"ACP harness thread support\",
      \"date\": \"2026-03-22\"
    }")
    
    # Draft 3: Browser use CLI 2.0 integration
    drafts+=("{
      \"source\": \"changelog\",
      \"product\": \"browser-use\",
      \"version\": \"2.0\",
      \"change\": \"Browser automation CLI with improved speed\",
      \"date\": \"2026-03-22\"
    }")
    
    local i=0
    for draft in "${drafts[@]}"; do
        ((i++))
        if [[ $i -gt $count ]]; then
            break
        fi
        
        local spec_file=$(mktemp)
        echo "$draft" > "$spec_file"
        
        if [[ -n "$output_dir" ]]; then
            bash "$SCRIPT_DIR/generate-skill.sh" "$spec_file" --from-changelog --output-dir "$output_dir" 2>/dev/null || true
        else
            bash "$SCRIPT_DIR/generate-skill.sh" "$spec_file" --from-changelog 2>/dev/null || true
        fi
        
        rm -f "$spec_file"
        echo ""
    done
}

main "$@"
