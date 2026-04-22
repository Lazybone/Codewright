# Implementation Plan: Upgrade Skill

## Files to Create
1. skills/upgrade/SKILL.md — Main coordinator skill
2. platforms/opencode/skills/upgrade/SKILL.md — OpenCode copy

## Files to Modify
3. .claude-plugin/plugin.json — version 0.3.9 → 0.4.0
4. .claude-plugin/marketplace.json — version 0.3.9 → 0.4.0
5. CHANGELOG.md — add 0.4.0 entry
6. platforms/opencode/setup.sh — add upgrade to SKILLS array + write version file
7. CLAUDE.md — add upgrade skill to skills table

## Architecture
Coordinator-only skill (no subagents). 4 phases:
1. Platform Detection (runtime + filesystem + user fallback)
2. Version Check (GitHub API → raw plugin.json fallback)
3. Upgrade Execution (Claude Code: /plugin update instructions; OpenCode: automated setup.sh)
4. Verification (read installed version, confirm match)

## ui_mockup
not needed
