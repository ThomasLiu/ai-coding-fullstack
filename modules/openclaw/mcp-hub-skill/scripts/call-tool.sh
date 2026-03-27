#!/bin/bash
# MCP 工具调用脚本
# Usage: call-tool.sh <server> <tool> [args...]

set -e

show_help() {
    cat << EOF
MCP Tool Caller - MCP Hub Skill

Usage:
    call-tool.sh <server> <tool> [args...]
    call-tool.sh --help

Examples:
    call-tool.sh github list-repos
    call-tool.sh github create-issue "title" "body"
    call-tool.sh filesystem read-file "/path/to/file"

Servers:
    chrome       - Browser automation
    github       - GitHub API (via gh CLI)
    filesystem   - Local file operations
    memory       - OpenClaw memory system

EOF
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

SERVER="$1"
TOOL="$2"

if [[ -z "$SERVER" ]] || [[ -z "$TOOL" ]]; then
    echo "Error: server and tool are required" >&2
    show_help >&2
    exit 1
fi

shift 2
TOOL_ARGS="$@"

# 路由到对应的 MCP server 实现
case "$SERVER" in
    github)
        if ! command -v gh &>/dev/null; then
            echo "{\"error\":\"gh CLI not installed\"}" >&2
            exit 1
        fi
        case "$TOOL" in
            list-repos)
                gh repo list --limit 10 --json name,url 2>/dev/null || echo "{\"error\":\"failed to list repos\"}"
                ;;
            *)
                echo "{\"error\":\"unknown tool: $TOOL\"}" >&2
                exit 1
                ;;
        esac
        ;;
    filesystem)
        case "$TOOL" in
            read-file)
                if [[ -z "$TOOL_ARGS" ]]; then
                    echo "{\"error\":\"path required\"}" >&2
                    exit 1
                fi
                if [[ -f "$TOOL_ARGS" ]]; then
                    cat "$TOOL_ARGS"
                else
                    echo "{\"error\":\"file not found: $TOOL_ARGS\"}" >&2
                    exit 1
                fi
                ;;
            *)
                echo "{\"error\":\"unknown tool: $TOOL\"}" >&2
                exit 1
                ;;
        esac
        ;;
    chrome)
        # Chrome 通过 OpenClaw agent-browser skill 调用
        echo "{\"info\":\"use agent-browser skill for chrome automation\",\"server\":\"chrome\"}"
        ;;
    memory)
        # Memory 通过 memory_search/memory_get 调用
        if [[ "$TOOL" == "search" ]]; then
            echo "{\"info\":\"use memory_search tool\",\"server\":\"memory\"}"
        else
            echo "{\"info\":\"use memory_get tool\",\"server\":\"memory\"}"
        fi
        ;;
    *)
        echo "{\"error\":\"unknown server: $SERVER\"}" >&2
        exit 1
        ;;
esac
