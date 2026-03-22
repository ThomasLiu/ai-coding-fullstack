#!/bin/bash
# generate-skill.sh - Auto-generate OpenClaw skill from spec/changelog
# TDD GREEN: Minimal implementation that produces valid skill output

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

show_usage() {
    cat << EOF
Usage: generate-skill.sh [SPEC_FILE] [OPTIONS]

Auto-generate OpenClaw skill from specification.

Options:
  --from-cli-param    Generate skill from CLI parameter spec
  --from-changelog    Generate skill from changelog entry
  --output-dir DIR     Write skill files to directory
  -h, --help           Show this help

Examples:
  generate-skill.sh spec.json --from-cli-param
  generate-skill.sh changelog.json --from-changelog
EOF
}

# Generate skill name from trigger/parameter
gen_skill_name() {
    local input="$1"
    # Convert trigger/param to kebab-case skill name
    echo "$input" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | sed 's/--//g' | sed 's/-*--/-/g' | sed 's/^-//' | sed 's/-$//'
}

# Generate skill YAML frontmatter
gen_frontmatter() {
    local name="$1"
    local description="$2"
    local trigger="$3"
    local tools="${4:-read,write,exec}"
    
    cat << EOF
---
name: $name
description: $description
trigger: $trigger
tools:
  - $tools
---

EOF
}

# Generate skill content body
gen_skill_body() {
    local name="$1"
    local description="$2"
    local trigger="$3"
    
    cat << EOF
# $name

## Description

$description

## Usage

When the user triggers with \`$trigger\`, this skill will be activated.

## Implementation

See scripts/ directory for implementation details.

## Examples

### Example 1
\`\`\`
$trigger --help
\`\`\`

### Example 2
\`\`\`
$trigger --analyze
\`\`\`
EOF
}

# Generate full skill file
generate_from_spec() {
    local spec_file="$1"
    local name=""
    local description=""
    local trigger=""
    local tools=""
    
    if [[ -f "$spec_file" ]]; then
        # Parse JSON spec
        name=$(grep -o '"trigger"[[:space:]]*:[[:space:]]*"[^"]*"' "$spec_file" | head -1 | sed 's/.*: "//;s/"$//')
        [[ -z "$name" ]] && name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$spec_file" | head -1 | sed 's/.*: "//;s/"$//')
        description=$(grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' "$spec_file" | head -1 | sed 's/.*: "//;s/"$//')
        trigger="$name"
        [[ -z "$name" ]] && name=$(gen_skill_name "${trigger:-default}")
        [[ -z "$description" ]] && description="Auto-generated skill for $trigger"
    else
        name=$(gen_skill_name "${1:-default-skill}")
        description="Auto-generated skill"
        trigger="$name"
    fi
    
    gen_frontmatter "$name" "$description" "$trigger" "$tools"
    gen_skill_body "$name" "$description" "$trigger"
}

# Generate from CLI parameter
generate_from_cli_param() {
    local spec_file="$1"
    local param=""
    local description=""
    local use_case=""
    
    if [[ -f "$spec_file" ]]; then
        param=$(grep -o '"cli_param"[[:space:]]*:[[:space:]]*"[^"]*"' "$spec_file" | sed 's/.*: "//;s/"$//')
        description=$(grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' "$spec_file" | head -1 | sed 's/.*: "//;s/"$//')
        use_case=$(grep -o '"use_case"[[:space:]]*:[[:space:]]*"[^"]*"' "$spec_file" | head -1 | sed 's/.*: "//;s/"$//')
    fi
    
    [[ -z "$param" ]] && param="--${1:-unknown-flag}"
    [[ -z "$description" ]] && description="Skill for CLI parameter $param"
    
    local name=$(gen_skill_name "$param")
    
    cat << EOF
---
name: $name
description: $description
trigger: $name
tools:
  - read
  - exec
---

# $name

## CLI Parameter

\`$param\`

## Description

$description

## Use Case

${use_case:-Automate tasks using this CLI parameter.}

## Implementation

\`\`\`bash
claude-code $param [options]
\`\`\`
EOF
}

# Generate from changelog entry
generate_from_changelog() {
    local spec_file="$1"
    local product=""
    local version=""
    local change=""
    local date=""
    
    if [[ -f "$spec_file" ]]; then
        product=$(grep -o '"product"[[:space:]]*:[[:space:]]*"[^"]*"' "$spec_file" | sed 's/.*: "//;s/"$//')
        version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$spec_file" | sed 's/.*: "//;s/"$//')
        change=$(grep -o '"change"[[:space:]]*:[[:space:]]*"[^"]*"' "$spec_file" | sed 's/.*: "//;s/"$//')
        date=$(grep -o '"date"[[:space:]]*:[[:space:]]*"[^"]*"' "$spec_file" | sed 's/.*: "//;s/"$//')
    fi
    
    [[ -z "$product" ]] && product="unknown"
    [[ -z "$version" ]] && version="latest"
    [[ -z "$change" ]] && change="Feature update"
    [[ -z "$date" ]] && date=$(date +%Y-%m-%d)
    
    # Generate skill name from change
    local name=$(gen_skill_name "$change")
    local trigger="$name"
    
    cat << EOF
---
name: $name
description: Skill auto-generated from $product changelog ($version) - $change
trigger: $trigger
tools:
  - read
  - exec
  - web_fetch
---

# $name

## Source

- **Product**: $product
- **Version**: $version
- **Date**: $date
- **Change**: $change

## Description

Auto-generated skill based on changelog entry: $change

## Purpose

Implement workflow improvements based on the new $product feature.

## Implementation Steps

1. Analyze the changelog entry details
2. Design skill workflow for the new feature
3. Implement skill scripts
4. Write tests
5. Create documentation

## Related

This skill was auto-generated by the Skill Generator System (Issue #15).
EOF
}

# Write to output directory
write_to_dir() {
    local content="$1"
    local output_dir="$2"
    local name=$(echo "$content" | grep '^name:' | sed 's/name: //' | tr ' ' '-')
    
    mkdir -p "$output_dir"
    local file="$output_dir/${name:-skill}.md"
    echo "$content" > "$file"
    echo "Written: $file"
}

main() {
    local mode="spec"
    local spec_file=""
    local output_dir=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --from-cli-param)
                mode="cli-param"
                shift
                ;;
            --from-changelog)
                mode="changelog"
                shift
                ;;
            --output-dir)
                output_dir="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                show_usage >&2
                exit 1
                ;;
            *)
                spec_file="$1"
                shift
                ;;
        esac
    done
    
    local content=""
    
    case "$mode" in
        cli-param)
            content=$(generate_from_cli_param "$spec_file")
            ;;
        changelog)
            content=$(generate_from_changelog "$spec_file")
            ;;
        *)
            content=$(generate_from_spec "$spec_file")
            ;;
    esac
    
    if [[ -n "$output_dir" ]]; then
        write_to_dir "$content" "$output_dir"
    else
        echo "$content"
    fi
}

main "$@"
