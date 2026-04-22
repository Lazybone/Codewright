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
  filesystem      + fallbacks       cache clear         version
  + user ask                        OpenCode:           file
                                    setup.sh
```

---

## Phase 1: Platform Detection

Detect which platform Codewright is running on. Try multiple strategies
in order of reliability. **Claude Code takes precedence** if both are installed.

```bash
OPENCODE_GLOBAL="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
PLATFORM=""

# Strategy 1: Claude Code plugin cache (highest priority)
if [[ -d "$HOME/.claude/plugins/cache/Lazybone-Codewright" ]]; then
  PLATFORM="claude-code"

# Strategy 2: OpenCode global install
elif [[ -f "$OPENCODE_GLOBAL/.codewright-version" ]] || [[ -d "$OPENCODE_GLOBAL/skills/audit-project" ]]; then
  PLATFORM="opencode-global"

# Strategy 3: OpenCode project-local install
elif [[ -f ".opencode/.codewright-version" ]] || [[ -d ".opencode/skills/audit-project" ]]; then
  PLATFORM="opencode-local"
fi

echo "PLATFORM=${PLATFORM:-undetected}"
```

### User Fallback

If `PLATFORM` is empty after detection, ask the user:

> "I couldn't auto-detect your platform. Which are you using?
> 1. Claude Code
> 2. OpenCode (global install)
> 3. OpenCode (project-local install)"

Store the result as `PLATFORM` — must be exactly one of: `claude-code`, `opencode-global`,
`opencode-local`. Reject any other value and re-ask.

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

### 2c: Validate Version Format

Before comparing, validate both version strings match semantic versioning:

```bash
SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+$'

if [[ -n "$CURRENT" && "$CURRENT" != "unknown" && ! "$CURRENT" =~ $SEMVER_RE ]]; then
  echo "WARNING: Current version '$CURRENT' is not valid semver. Treating as unknown."
  CURRENT="unknown"
fi

if [[ -n "$LATEST" && ! "$LATEST" =~ $SEMVER_RE ]]; then
  echo "WARNING: Latest version '$LATEST' is not valid semver. Cannot proceed."
  # Show manual upgrade instructions and stop
fi
```

### 2d: Compare and Report

Display the version status to the user:

```
Codewright Version Check
========================
Platform:         <PLATFORM>
Current version:  <CURRENT>
Latest version:   <LATEST>
```

**Version comparison** — use `sort -V` for proper semantic version ordering:

```bash
VERSION_HIGHER=$(printf '%s\n%s\n' "$CURRENT" "$LATEST" | sort -V | tail -1)
```

**Decision tree:**

| Condition | Action |
|-----------|--------|
| `LATEST` is empty or "unavailable" | "Could not reach GitHub. Check connection." → show manual steps, stop |
| `CURRENT == LATEST` | "Already on the latest version!" → stop |
| `CURRENT == "unknown"` | "Could not determine current version. Proceeding with upgrade." → Phase 3 |
| `VERSION_HIGHER == LATEST` (newer available) | Show changelog excerpt → proceed to Phase 3 |
| `VERSION_HIGHER == CURRENT` (user has newer) | "You have a newer version ($CURRENT) than the latest release ($LATEST). No upgrade needed." → stop |

### 2e: Show Changelog Excerpt

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
> rm -rf "$HOME/.claude/plugins/cache/Lazybone-Codewright"
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

OpenCode upgrades are fully automated via sparse git clone + setup.sh.

**Important:** Capture the working directory before changing into the temp dir,
so `--local` installs to the correct project path.

```bash
ORIG_DIR="$(pwd)"
CW_TMP="$(mktemp -d)"
trap 'rm -rf "$CW_TMP"' EXIT

echo "Downloading latest Codewright..."

git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/Lazybone/Codewright.git "$CW_TMP/codewright" \
  || { echo "ERROR: Git clone failed. Check network connection."; exit 1; }

cd "$CW_TMP/codewright"

git sparse-checkout set platforms/opencode .claude-plugin \
  || { echo "ERROR: Sparse checkout failed."; exit 1; }

echo "Running setup..."

if [[ "$PLATFORM" == "opencode-local" ]]; then
  cd "$ORIG_DIR"
  bash "$CW_TMP/codewright/platforms/opencode/setup.sh" --local \
    || { echo "ERROR: setup.sh failed. Check output above."; exit 1; }
else
  bash "$CW_TMP/codewright/platforms/opencode/setup.sh" --global \
    || { echo "ERROR: setup.sh failed. Check output above."; exit 1; }
fi

echo "Cleanup done."
```

The `trap` ensures the temp directory is cleaned up even if the script exits
early due to an error.

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
| Platform not detected | Ask user to specify (User Fallback) |
| GitHub unreachable (all 3 strategies) | Show manual upgrade instructions, stop |
| Current version unknown | Proceed with upgrade anyway |
| Current version newer than latest | Inform user, stop (no downgrade) |
| Version string not valid semver | Warn, treat as unknown |
| Neither `gh` nor `curl` available | Stop, tell user to install `curl` |
| Git clone fails (network/auth) | Show error, suggest manual download |
| Sparse checkout fails | Show error, suggest full clone |
| OpenCode `setup.sh` fails | Show error output, suggest manual steps |
| Claude Code cache not clearable | Suggest manual deletion |
| Git not available (OpenCode upgrade) | Stop, show manual download instructions |
| Temp directory not cleaned up | `trap` ensures cleanup on any exit |
