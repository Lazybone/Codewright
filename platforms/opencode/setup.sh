#!/usr/bin/env bash
# Codewright OpenCode Plugin — Setup Script
#
# Installs Codewright agents and skills into the project's .opencode/ directory,
# and adds the plugin to opencode.json so OpenCode loads it at startup.
#
# The cw_agent tool is registered by the plugin itself (not as a standalone file),
# because OpenCode's ToolContext doesn't expose the SDK client.
#
# Usage:
#   bash setup.sh                  # Install to current project
#   bash setup.sh --global         # Install to ~/.config/opencode/
#   bash setup.sh --uninstall      # Remove Codewright from current project

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
  --global      Install to ~/.config/opencode/ (all projects)
  --uninstall   Remove Codewright files from target directory
  --help        Show this help

Without flags, installs to .opencode/ in the current directory.
EOF
  exit 0
}

TARGET_DIR=".opencode"
UNINSTALL=false

while [[ $# -gt 0 ]]; do
  case $1 in
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
  ok "Codewright removed."
  echo ""
  warn "Remember to also remove '@codewright/opencode' from opencode.json plugin list."
  exit 0
fi

# --- Install ---

info "Installing Codewright to $TARGET_DIR ..."

# Agents (predefined subagents for cw_agent tool)
mkdir -p "$TARGET_DIR/agents"
cp "$SCRIPT_DIR/agents/cw-explore.md" "$TARGET_DIR/agents/"
cp "$SCRIPT_DIR/agents/cw-worker.md"  "$TARGET_DIR/agents/"
ok "Agents installed (cw-explore, cw-worker)"

# Skills
mkdir -p "$TARGET_DIR/skills/pr-reviewer/agents"
cp "$SCRIPT_DIR/skills/pr-reviewer/SKILL.md" "$TARGET_DIR/skills/pr-reviewer/"
cp "$SCRIPT_DIR/skills/pr-reviewer/agents/"*.md "$TARGET_DIR/skills/pr-reviewer/agents/"
ok "Skill installed (pr-reviewer)"

# Plugin registration hint
if [[ -f "opencode.json" ]]; then
  if grep -q "codewright" opencode.json 2>/dev/null; then
    ok "Plugin already referenced in opencode.json"
  else
    warn "Add the plugin to opencode.json manually:"
    echo '  { "plugin": ["@codewright/opencode"] }'
  fi
else
  warn "No opencode.json found. Create one with:"
  echo '  { "plugin": ["@codewright/opencode"] }'
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
info "Architecture:"
echo "  - Agents (cw-explore, cw-worker) → .opencode/agents/"
echo "  - Skills (pr-reviewer)           → .opencode/skills/"
echo "  - cw_agent tool                  → registered by plugin at startup"
echo ""
info "Next steps:"
echo "  1. Add '@codewright/opencode' to opencode.json plugins"
echo "  2. Start OpenCode in your project"
echo "  3. Say: 'review my PR' or 'review PR #123'"
