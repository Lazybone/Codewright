#!/usr/bin/env bash
# Codewright for Kimi CLI — Setup Script
#
# Installs all Codewright skills globally to ~/.kimi/skills/ so they are
# available in every Kimi CLI session.
#
# Usage:
#   bash setup.sh                  # Install globally (default)
#   bash setup.sh --local          # Install to current project's .kimi/skills/
#   bash setup.sh --uninstall      # Remove Codewright globally

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_DIR="$HOME/.kimi"

# Use Kimi CLI-specific skill variants (platforms/kimi/skills/)
SKILLS_SRC="$SCRIPT_DIR/skills"

SKILLS=(
  audit-project
  auto-dev
  brainstormer
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
  --local       Install to .kimi/skills/ in the current directory (project-only)
  --global      Install to ~/.kimi/skills/ (all projects)
  --uninstall   Remove Codewright skills (globally by default, or --local)
  --help        Show this help

Without flags, installs globally to ~/.kimi/skills/ (all projects).
EOF
  exit 0
}

TARGET_DIR="$GLOBAL_DIR"
UNINSTALL=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --local)     TARGET_DIR=".kimi"; shift ;;
    --global)    TARGET_DIR="$GLOBAL_DIR"; shift ;;
    --uninstall) UNINSTALL=true; shift ;;
    --help)      usage ;;
    *)           error "Unknown option: $1" ;;
  esac
done

# --- Uninstall ---

if $UNINSTALL; then
  info "Removing Codewright from $TARGET_DIR ..."

  # All skills
  for skill in "${SKILLS[@]}"; do
    rm -rf "$TARGET_DIR/skills/$skill"
  done

  # Shared references
  rm -rf "$TARGET_DIR/references"

  # Version marker
  rm -f "$TARGET_DIR/.codewright-version"

  ok "Codewright fully removed from $TARGET_DIR"
  exit 0
fi

# --- Install ---

info "Installing Codewright to $TARGET_DIR/skills ..."

# All skills
mkdir -p "$TARGET_DIR/skills"
SKILL_COUNT=0
for skill in "${SKILLS[@]}"; do
  if [[ -d "$SKILLS_SRC/$skill" ]]; then
    rm -rf "$TARGET_DIR/skills/$skill"
    cp -r "$SKILLS_SRC/$skill" "$TARGET_DIR/skills/$skill"
    SKILL_COUNT=$((SKILL_COUNT + 1))
  else
    warn "Skill directory not found: $skill"
  fi
done
ok "$SKILL_COUNT skills installed (${SKILLS[*]})"

# Shared references
if [[ -d "$SCRIPT_DIR/../../references" ]]; then
  rm -rf "$TARGET_DIR/references"
  cp -r "$SCRIPT_DIR/../../references" "$TARGET_DIR/references"
  ok "Shared references installed"
fi

# Write version marker for upgrade skill
CW_VERSION=$(grep -o '"version": "[^"]*"' "$SCRIPT_DIR/../../.claude-plugin/plugin.json" 2>/dev/null \
  | head -1 | cut -d'"' -f4 || echo "unknown")
echo "$CW_VERSION" > "$TARGET_DIR/.codewright-version"
ok "Version marker written ($CW_VERSION)"

# Verify
info "Verifying installation ..."
MISSING=0

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
info "Installed to: $TARGET_DIR/skills"
echo "  - Skills: ${SKILLS[*]}"
echo "  - References: agent-invocation, finding-format"
echo ""
info "Say 'upgrade', 'review my PR', or 'auto dev: add feature X' in any Kimi CLI session."
