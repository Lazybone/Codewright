#!/usr/bin/env bash
# Codewright OpenCode Plugin — Setup Script
#
# Installs all Codewright agents, skills, and references globally to
# ~/.config/opencode/ so they are available in all OpenCode projects.
#
# Usage:
#   bash setup.sh                  # Install globally (default)
#   bash setup.sh --local          # Install to current project's .opencode/
#   bash setup.sh --uninstall      # Remove Codewright globally

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

SKILLS=(
  audit-project
  auto-dev
  bug-fixer
  codebase-doctor
  codebase-onboarding
  github-issue-fixer
  perf-analyzer
  pr-reviewer
  refactor-orchestrator
  test-engineer
  upgrade
)

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

  # Agents
  rm -f "$TARGET_DIR/agents/cw-explore.md"
  rm -f "$TARGET_DIR/agents/cw-worker.md"

  # All skills
  for skill in "${SKILLS[@]}"; do
    rm -rf "$TARGET_DIR/skills/$skill"
  done

  # Shared references
  rm -rf "$TARGET_DIR/references"

  # Version marker
  rm -f "$TARGET_DIR/.codewright-version"

  # Check global opencode.json for plugin reference
  GLOBAL_CONFIG="$GLOBAL_DIR/opencode.json"
  if [[ -f "$GLOBAL_CONFIG" ]] && grep -q "codewright" "$GLOBAL_CONFIG" 2>/dev/null; then
    warn "Remove '@codewright/opencode' from $GLOBAL_CONFIG plugin list."
  fi

  ok "Codewright fully removed from $TARGET_DIR"
  exit 0
fi

# --- Install ---

info "Installing Codewright to $TARGET_DIR ..."

# Agents
mkdir -p "$TARGET_DIR/agents"
cp "$SCRIPT_DIR/agents/cw-explore.md" "$TARGET_DIR/agents/"
cp "$SCRIPT_DIR/agents/cw-worker.md"  "$TARGET_DIR/agents/"
ok "Agents installed (cw-explore, cw-worker)"

# All skills
mkdir -p "$TARGET_DIR/skills"
SKILL_COUNT=0
for skill in "${SKILLS[@]}"; do
  if [[ -d "$SCRIPT_DIR/skills/$skill" ]]; then
    rm -rf "$TARGET_DIR/skills/$skill"
    cp -r "$SCRIPT_DIR/skills/$skill" "$TARGET_DIR/skills/$skill"
    SKILL_COUNT=$((SKILL_COUNT + 1))
  else
    warn "Skill directory not found: $skill"
  fi
done
ok "$SKILL_COUNT skills installed (${SKILLS[*]})"

# Shared references
if [[ -d "$SCRIPT_DIR/references" ]]; then
  cp -r "$SCRIPT_DIR/references" "$TARGET_DIR/references"
  ok "Shared references installed"
fi

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

# Write version marker for upgrade skill
CW_VERSION=$(grep -o '"version": "[^"]*"' "$SCRIPT_DIR/../../.claude-plugin/plugin.json" 2>/dev/null \
  | head -1 | cut -d'"' -f4 || echo "unknown")
echo "$CW_VERSION" > "$TARGET_DIR/.codewright-version"
ok "Version marker written ($CW_VERSION)"

# Verify
info "Verifying installation ..."
MISSING=0

for agent in cw-explore cw-worker; do
  if [[ ! -f "$TARGET_DIR/agents/$agent.md" ]]; then
    warn "Missing agent: $agent"
    MISSING=$((MISSING + 1))
  fi
done

for skill in "${SKILLS[@]}"; do
  if [[ ! -f "$TARGET_DIR/skills/$skill/SKILL.md" ]]; then
    warn "Missing skill: $skill"
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
echo "  - Agents:     cw-explore, cw-worker"
echo "  - Skills:     ${SKILLS[*]}"
echo "  - References: agent-invocation, finding-format"
echo "  - Tool:       cw_agent (registered by plugin at startup)"
echo ""
info "Say 'upgrade', 'review my PR', or 'auto dev: add feature X' in any OpenCode session."
