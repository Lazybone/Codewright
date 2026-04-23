# Codewright for Kimi CLI — Installation Guide

## For Humans

Paste this prompt into your Kimi CLI session:

```
Install and configure Codewright for Kimi CLI by following the instructions here:
https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/kimi/INSTALL.md
```

To uninstall, paste this:

```
Uninstall Codewright for Kimi CLI by following the instructions here:
https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/kimi/INSTALL.md#uninstall
```

## For LLM Agents

> **IMPORTANT: Fetch this file with `curl`, not WebFetch.**
> WebFetch summarizes content and loses critical steps.
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/kimi/INSTALL.md
> ```

You are helping the user install **Codewright**, a multi-agent skill plugin for Kimi CLI.
Codewright provides skills like `pr-reviewer`, `auto-dev`, `github-issue-fixer`, and more.

**Always install globally** to `~/.kimi/skills/` so the skills are available in every project.

Follow these steps exactly.

---

### Step 1: Verify Kimi CLI is installed

```bash
if command -v kimi &> /dev/null; then
    echo "✓ Kimi CLI $(kimi --version) is installed"
else
    echo "✗ Kimi CLI is not installed."
    echo "Install it first: https://moonshotai.github.io/kimi-cli/"
fi
```

If Kimi CLI is not installed, stop and help the user install it from https://moonshotai.github.io/kimi-cli/ before continuing.

---

### Step 2: Download Codewright

```bash
CW_TMP="$(mktemp -d)"
git clone --depth 1 --filter=blob:none --sparse \
    https://github.com/Lazybone/Codewright.git "$CW_TMP/codewright"
cd "$CW_TMP/codewright"
git sparse-checkout set platforms/kimi
echo "✓ Codewright downloaded"
```

---

### Step 3: Run global setup

```bash
bash "$CW_TMP/codewright/platforms/kimi/setup.sh"
```

This installs to `~/.kimi/skills/` by default (global, all projects).

**Expected output:**
```
[codewright] Installing Codewright to /home/user/.kimi/skills ...
[codewright] 11 skills installed (audit-project auto-dev bug-fixer ...)
[codewright] Version marker written (x.y.z)
[codewright] Installation complete. All files verified.
```

---

### Step 4: Clean up temp files

```bash
rm -rf "$CW_TMP"
echo "✓ Temp files cleaned up"
```

---

### Step 5: Verify installation

```bash
GLOBAL_DIR="$HOME/.kimi"

echo "=== Verification ==="

for skill in audit-project auto-dev bug-fixer codebase-doctor codebase-onboarding github-issue-fixer perf-analyzer pr-reviewer refactor-orchestrator test-engineer upgrade; do
    if [ -f "$GLOBAL_DIR/skills/$skill/SKILL.md" ]; then
        echo "✓ Skill: $skill"
    else
        echo "✗ Missing skill: $skill"
    fi
done

if [ -f "$GLOBAL_DIR/.codewright-version" ]; then
    echo "✓ Version marker: $(cat "$GLOBAL_DIR/.codewright-version")"
else
    echo "✗ Missing version marker"
fi

echo ""
echo "=== Done ==="
```

---

### Step 6: Confirm to user

Tell the user:

1. **What was installed** (globally to `~/.kimi/skills/`, available in all projects):
   - 11 Kimi CLI-optimized skills with inline agent definitions (no external references needed)
   - Shared references: `agent-invocation`, `finding-format`
   - Skills: `audit-project`, `auto-dev`, `bug-fixer`, `codebase-doctor`, `codebase-onboarding`, `github-issue-fixer`, `perf-analyzer`, `pr-reviewer`, `refactor-orchestrator`, `test-engineer`, `upgrade`

2. **How to use it:**
   - "review my PR" or "review PR #123" — parallel PR review
   - "auto dev: add feature X" — autonomous development
   - "fix issue #42" — GitHub issue fixing
   - "audit this project" — comprehensive codebase audit
   - "onboard me" — generate architecture docs
   - "upgrade" or "update codewright" — check for updates

3. **How to uninstall:**
   - Paste the uninstall prompt from the top of this file, or run `bash setup.sh --uninstall`

---

## Uninstall

### For Humans

Paste this prompt into your Kimi CLI session:

```
Uninstall Codewright for Kimi CLI by following the instructions here:
https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/kimi/INSTALL.md#uninstall
```

### For LLM Agents

You are helping the user **uninstall Codewright** from Kimi CLI.

Follow these steps exactly.

#### Step 1: Remove Codewright skills

```bash
GLOBAL_DIR="$HOME/.kimi"

# All skills
for skill in audit-project auto-dev bug-fixer codebase-doctor codebase-onboarding github-issue-fixer perf-analyzer pr-reviewer refactor-orchestrator test-engineer upgrade; do
    rm -rf "$GLOBAL_DIR/skills/$skill"
done

# Version marker
rm -f "$GLOBAL_DIR/.codewright-version"

echo "✓ Codewright skills and version marker removed"
```

#### Step 2: Verify removal

```bash
GLOBAL_DIR="$HOME/.kimi"

REMAINING=0
for skill in audit-project auto-dev bug-fixer codebase-doctor codebase-onboarding github-issue-fixer perf-analyzer pr-reviewer refactor-orchestrator test-engineer upgrade; do
    [ -d "$GLOBAL_DIR/skills/$skill" ] && echo "✗ Still exists: skills/$skill" && REMAINING=$((REMAINING + 1))
done

if [ $REMAINING -eq 0 ]; then
    echo "✓ Codewright fully removed"
else
    echo "✗ $REMAINING item(s) still present"
fi
```

#### Step 3: Confirm to user

Tell the user that Codewright has been completely removed. All 11 skills and the version marker are gone. No restart needed — the changes take effect on the next Kimi CLI session.

---

## Manual Installation

```bash
git clone https://github.com/Lazybone/Codewright.git /tmp/codewright
bash /tmp/codewright/platforms/kimi/setup.sh
rm -rf /tmp/codewright
```

## Manual Uninstallation

```bash
GLOBAL_DIR="$HOME/.kimi"
for skill in audit-project auto-dev bug-fixer codebase-doctor codebase-onboarding github-issue-fixer perf-analyzer pr-reviewer refactor-orchestrator test-engineer upgrade; do
    rm -rf "$GLOBAL_DIR/skills/$skill"
done
rm -f "$GLOBAL_DIR/.codewright-version"
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Skill not discovered | Check that `~/.kimi/skills/pr-reviewer/SKILL.md` exists |
| "upgrade" skill not found | Ensure `~/.kimi/skills/upgrade/SKILL.md` exists |
| Wrong version shown after update | Kimi CLI caches skill metadata; restart your session |
| Setup script fails with "Skill directory not found" | Run from inside the cloned Codewright repo, or use absolute paths |
