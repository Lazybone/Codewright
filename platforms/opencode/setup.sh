#!/usr/bin/env bash
# Codewright OpenCode Plugin — Setup Script
#
# Installs Codewright agents and skills globally to ~/.config/opencode/
# so they are available in all OpenCode projects.
#
# The cw_agent tool is registered by the plugin itself (not as a standalone file),
# because OpenCode's ToolContext doesn't expose the SDK client.
#
# Usage:
#   bash setup.sh                  # Install globally (default)
#   bash setup.sh --local          # Install to current project's .opencode/
#   bash setup.sh --uninstall      # Remove Codewright globally

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

info()  { printf '\033[0;34m[codewright]\033[0m %s\n' "$1"; }
ok()    { printf '\033[0;32m[codewright]\033[0m %s\n' "$1"; }
warn()  { printf '\033[0;33m[codewright]\033[0m %s\n' "$1"; }
error() { printf '\033[0;31m[codewright]\033[0m %s\n' "$1" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --local       Install to .opencode/ in the current directory (project-only)
  --uninstall   Remove Codewright (globally by default, or --local)
  --help        Show this help

Without flags, installs globally to ~/.config/opencode/ (all projects).
EOF
  exit 0
}

TARGET_DIR="$GLOBAL_DIR"
UNINSTALL=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --local)     TARGET_DIR=".opencode"; shift ;;
    --global)    TARGET_DIR="$GLOBAL_DIR"; shift ;;
    --uninstall) UNINSTALL=true; shift ;;
    --help)      usage ;;
    *)           error "Unknown option: $1" ;;
  esac
done

# --- Uninstall ---

if $UNINSTALL; then
  info "Removing Codewright from $TARGET_DIR ..."
  rm -f  "$TARGET_DIR/agents/cw-explore.md"
  rm -f  "$TARGET_DIR/agents/cw-worker.md"
  rm -rf "$TARGET_DIR/skills/pr-reviewer"
  ok "Codewright files removed from $TARGET_DIR"

  # Check global opencode.json for plugin reference
  GLOBAL_CONFIG="$GLOBAL_DIR/opencode.json"
  if [[ -f "$GLOBAL_CONFIG" ]] && grep -q "codewright" "$GLOBAL_CONFIG" 2>/dev/null; then
    warn "Remove '@codewright/opencode' from $GLOBAL_CONFIG plugin list."
  fi

  ok "Uninstall complete."
  exit 0
fi

# --- Install ---

info "Installing Codewright to $TARGET_DIR ..."

# Agents
mkdir -p "$TARGET_DIR/agents"
cp "$SCRIPT_DIR/agents/cw-explore.md" "$TARGET_DIR/agents/"
cp "$SCRIPT_DIR/agents/cw-worker.md"  "$TARGET_DIR/agents/"
ok "Agents installed (cw-explore, cw-worker)"

# Skills
mkdir -p "$TARGET_DIR/skills/pr-reviewer/agents"
cp "$SCRIPT_DIR/skills/pr-reviewer/SKILL.md" "$TARGET_DIR/skills/pr-reviewer/"
cp "$SCRIPT_DIR/skills/pr-reviewer/agents/"*.md "$TARGET_DIR/skills/pr-reviewer/agents/"
ok "Skill installed (pr-reviewer)"

# Plugin registration in global config
GLOBAL_CONFIG="$GLOBAL_DIR/opencode.json"
if [[ -f "$GLOBAL_CONFIG" ]]; then
  if grep -q "codewright" "$GLOBAL_CONFIG" 2>/dev/null; then
    ok "Plugin already registered in $GLOBAL_CONFIG"
  else
    warn "Add '@codewright/opencode' to the plugin array in $GLOBAL_CONFIG"
  fi
else
  mkdir -p "$GLOBAL_DIR"
  cat > "$GLOBAL_CONFIG" << 'OPENCODE_JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["@codewright/opencode"]
}
OPENCODE_JSON
  ok "Created $GLOBAL_CONFIG with Codewright plugin"
fi

# Verify
info "Verifying installation ..."
MISSING=0
for f in \
  "$TARGET_DIR/agents/cw-explore.md" \
  "$TARGET_DIR/agents/cw-worker.md" \
  "$TARGET_DIR/skills/pr-reviewer/SKILL.md" \
  "$TARGET_DIR/skills/pr-reviewer/agents/logic-reviewer.md" \
  "$TARGET_DIR/skills/pr-reviewer/agents/security-reviewer.md" \
  "$TARGET_DIR/skills/pr-reviewer/agents/quality-reviewer.md"
do
  if [[ ! -f "$f" ]]; then
    warn "Missing: $f"
    MISSING=$((MISSING + 1))
  fi
done

if [[ $MISSING -eq 0 ]]; then
  ok "Installation complete. All files verified."
else
  warn "$MISSING file(s) missing — check the output above."
fi

echo ""
info "Installed to: $TARGET_DIR"
echo "  - Agents: cw-explore, cw-worker"
echo "  - Skills: pr-reviewer"
echo "  - Tool:   cw_agent (registered by plugin at startup)"
echo ""
info "Say 'review my PR' or 'review PR #123' in any OpenCode session."
