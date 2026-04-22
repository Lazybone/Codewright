---
name: upgrade
description: >
  Detects current platform (Claude Code or OpenCode), checks for newer Codewright
  versions via GitHub API, and performs platform-specific upgrade. Single skill
  for both platforms — no subagents needed.
  Triggers: "upgrade", "update codewright", "check for updates", "new version",
  "upgrade plugin", "update plugin", "latest version".
  Also triggers on (German): "upgrade", "aktualisieren", "Update prüfen",
  "neue Version", "Plugin aktualisieren", "auf neueste Version bringen",
  "neueste Version".
---

# Upgrade — Coordinator

Detects the running platform, compares the installed version against the latest
GitHub release, and performs a platform-specific upgrade.

**No subagents required** — all logic runs as inline shell commands executed
by the coordinator.

## Architecture

```
Phase 1          Phase 2           Phase 3            Phase 4
┌──────────┐    ┌──────────────┐  ┌────────────────┐  ┌──────────┐
│ Detect   │───▶│ Check        │─▶│ Execute        │─▶│ Verify   │
│ Platform │    │ Version      │  │ Upgrade        │  │ Success  │
└──────────┘    └──────────────┘  └────────────────┘  └──────────┘
  runtime +       GitHub API        Claude Code:        re-read
  filesystem      + fallbacks       /plugin update      version
  + user ask                        OpenCode:           file
                                    setup.sh
```

---

## Phase 1: Platform Detection

Detect which platform Codewright is running on. Try multiple strategies
in order of reliability.

### Strategy 1: Claude Code Plugin Cache

```bash
if [[ -d "$HOME/.claude/plugins/cache/Lazybone-Codewright" ]]; then
  echo "PLATFORM=claude-code"
fi
```

If this directory exists, the user is running Claude Code with the Codewright
marketplace plugin installed.

### Strategy 2: OpenCode Installation

```bash
OPENCODE_GLOBAL="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

# Global install
if [[ -f "$OPENCODE_GLOBAL/.codewright-version" ]] || [[ -d "$OPENCODE_GLOBAL/skills/audit-project" ]]; then
  echo "PLATFORM=opencode-global"
fi

# Project-local install
if [[ -f ".opencode/.codewright-version" ]] || [[ -d ".opencode/skills/audit-project" ]]; then
  echo "PLATFORM=opencode-local"
fi
```

### Strategy 3: User Fallback

If no platform detected automatically, ask the user:

> "I couldn't auto-detect your platform. Which are you using?
> 1. Claude Code
> 2. OpenCode (global install)
> 3. OpenCode (project-local install)"

Store the result as `PLATFORM` — one of: `claude-code`, `opencode-global`, `opencode-local`.

---

## Phase 2: Version Check

### 2a: Get Current Installed Version

**Claude Code:**

```bash
CURRENT=$(grep -o '"version": "[^"]*"' \
  "$HOME/.claude/plugins/cache/Lazybone-Codewright/codewright"/*/plugin.json 2>/dev/null \
  | head -1 | cut -d'"' -f4)
echo "CURRENT=${CURRENT:-unknown}"
```

**OpenCode (global):**

```bash
VERSION_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/.codewright-version"
CURRENT=$(cat "$VERSION_FILE" 2>/dev/null || echo "unknown")
```

**OpenCode (local):**

```bash
VERSION_FILE=".opencode/.codewright-version"
CURRENT=$(cat "$VERSION_FILE" 2>/dev/null || echo "unknown")
```

### 2b: Get Latest Available Version

Try three strategies in order:

```bash
# Strategy 1: GitHub API via gh CLI (authenticated — higher rate limit)
LATEST=$(gh api repos/Lazybone/Codewright/releases/latest --jq '.tag_name' 2>/dev/null \
  | sed 's/^v//')

# Strategy 2: GitHub API via curl (unauthenticated)
if [[ -z "$LATEST" ]]; then
  LATEST=$(curl -sf https://api.github.com/repos/Lazybone/Codewright/releases/latest \
    | grep -o '"tag_name": "[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/^v//')
fi

# Strategy 3: Raw plugin.json from main branch
if [[ -z "$LATEST" ]]; then
  LATEST=$(curl -sf https://raw.githubusercontent.com/Lazybone/Codewright/main/.claude-plugin/plugin.json \
    | grep -o '"version": "[^"]*"' | head -1 | cut -d'"' -f4)
fi

echo "LATEST=${LATEST:-unavailable}"
```

### 2c: Compare and Report

Display the version status to the user:

```
Codewright Version Check
========================
Platform:         <PLATFORM>
Current version:  <CURRENT>
Latest version:   <LATEST>
```

**Decision tree:**

| Condition | Action |
|-----------|--------|
| `LATEST` is empty | "Could not reach GitHub. Check connection." → show manual steps, stop |
| `CURRENT == LATEST` | "Already on the latest version!" → stop |
| `CURRENT == "unknown"` | "Could not determine current version. Proceeding with upgrade." → Phase 3 |
| `LATEST > CURRENT` | Show changelog excerpt → proceed to Phase 3 |

### 2d: Show Changelog Excerpt

Fetch the CHANGELOG.md from the main branch and extract entries between
the current and latest version:

```bash
curl -sf https://raw.githubusercontent.com/Lazybone/Codewright/main/CHANGELOG.md
```

Parse and display only the sections newer than `CURRENT`. If parsing fails,
show a link to the full changelog instead:

> "Full changelog: https://github.com/Lazybone/Codewright/blob/main/CHANGELOG.md"

---

## Phase 3: Upgrade

Ask user for confirmation before executing:

> "Upgrade Codewright from **<CURRENT>** to **<LATEST>**?
>
> Changes since your version:
> <changelog excerpt>
>
> Proceed? (yes/no)"

If the user declines, stop.

### Claude Code Upgrade

Claude Code plugins are managed through the marketplace. The upgrade process
requires user action:

> "To upgrade in Claude Code, choose one of these options:
>
> **Option 1** (recommended): Clear the plugin cache so the latest version
> is downloaded on next use:
> ```bash
> rm -rf ~/.claude/plugins/cache/Lazybone-Codewright
> ```
> The latest version will be downloaded automatically when you next invoke
> a Codewright skill.
>
> **Option 2**: If your Claude Code version supports it:
> ```
> /plugin update
> ```
>
> After upgrading, run `/codewright:upgrade` again to verify the new version."

**Important:** The coordinator should offer to execute Option 1 (cache clear)
directly if the user agrees. This is safe because the current skill execution
is already loaded in memory.

```bash
rm -rf "$HOME/.claude/plugins/cache/Lazybone-Codewright"
echo "Plugin cache cleared. Next Codewright skill invocation will download v${LATEST}."
```

### OpenCode Upgrade

OpenCode upgrades are fully automated via sparse git clone + setup.sh:

```bash
CW_TMP="$(mktemp -d)"
echo "Downloading latest Codewright..."

git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/Lazybone/Codewright.git "$CW_TMP/codewright" 2>&1

cd "$CW_TMP/codewright"
git sparse-checkout set platforms/opencode 2>&1

echo "Running setup..."

if [[ "$PLATFORM" == "opencode-local" ]]; then
  bash "$CW_TMP/codewright/platforms/opencode/setup.sh" --local
else
  bash "$CW_TMP/codewright/platforms/opencode/setup.sh" --global
fi

rm -rf "$CW_TMP"
echo "Cleanup done."
```

---

## Phase 4: Verify

After upgrade execution, confirm the installed version matches expectations.

### Claude Code Verification

```bash
NEW_VERSION=$(grep -o '"version": "[^"]*"' \
  "$HOME/.claude/plugins/cache/Lazybone-Codewright/codewright"/*/plugin.json 2>/dev/null \
  | head -1 | cut -d'"' -f4)
echo "INSTALLED=${NEW_VERSION:-not found}"
```

- If cache was just cleared: version file won't exist yet. This is expected.
  Report: "Cache cleared. New version will be active on next skill invocation."
- If version matches `LATEST`: "Upgrade successful! Codewright v<LATEST> is installed."
- If mismatch: "Version mismatch. Try restarting Claude Code."

### OpenCode Verification

```bash
if [[ "$PLATFORM" == "opencode-global" ]]; then
  VERSION_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/.codewright-version"
elif [[ "$PLATFORM" == "opencode-local" ]]; then
  VERSION_FILE=".opencode/.codewright-version"
fi
NEW_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "not found")
echo "INSTALLED=$NEW_VERSION"
```

- If `NEW_VERSION == LATEST`: "Upgrade successful! Codewright v<LATEST> is installed."
- If mismatch or not found: "Verification failed. Try running setup.sh manually."

### Final Summary

Display a summary to the user:

```
Codewright Upgrade Complete
===========================
Platform:          <PLATFORM>
Previous version:  <CURRENT>
New version:       <LATEST>
Status:            <SUCCESS or PENDING RESTART>
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Platform not detected | Ask user to specify (Strategy 3) |
| GitHub unreachable (all 3 strategies) | Show manual upgrade instructions, stop |
| Current version unknown | Proceed with upgrade anyway |
| Neither `gh` nor `curl` available | Stop, tell user to install `curl` |
| OpenCode `setup.sh` fails | Show error output, suggest manual steps |
| Claude Code cache not clearable (permissions) | Suggest `sudo` or manual deletion |
| Git not available (OpenCode upgrade) | Stop, show manual download instructions |
