# Codewright for OpenCode — Installation Guide

## For Humans

Paste this prompt into your OpenCode session:

```
Install and configure Codewright for OpenCode by following the instructions here:
https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/opencode/INSTALL.md
```

To uninstall, paste this:

```
Uninstall Codewright for OpenCode by following the instructions here:
https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/opencode/INSTALL.md#uninstall
```

## For LLM Agents

> **IMPORTANT: Fetch this file with `curl`, not WebFetch.**
> WebFetch summarizes content and loses critical steps.
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/opencode/INSTALL.md
> ```

You are helping the user install **Codewright**, a multi-agent skill plugin for OpenCode.
Codewright provides skills like `pr-reviewer`, `auto-dev`, `github-issue-fixer`, and more.

**Always install globally** to `~/.config/opencode/` so the skills are available in every project.

Follow these steps exactly.

---

### Step 1: Verify OpenCode is installed

```bash
if command -v opencode &> /dev/null; then
    echo "✓ OpenCode $(opencode --version) is installed"
else
    echo "✗ OpenCode is not installed."
    echo "Install it first: https://opencode.ai/docs"
fi
```

If OpenCode is not installed, stop and help the user install it from https://opencode.ai/docs before continuing.

---

### Step 2: Download Codewright

```bash
CW_TMP="$(mktemp -d)"
git clone --depth 1 --filter=blob:none --sparse \
    https://github.com/Lazybone/Codewright.git "$CW_TMP/codewright"
cd "$CW_TMP/codewright"
git sparse-checkout set platforms/opencode
echo "✓ Codewright downloaded"
```

---

### Step 3: Run global setup

```bash
bash "$CW_TMP/codewright/platforms/opencode/setup.sh"
```

This installs to `~/.config/opencode/` by default (global, all projects).

**Expected output:**
```
[codewright] Installing Codewright to /home/user/.config/opencode ...
[codewright] Agents installed (cw-explore, cw-worker)
[codewright] 10 skills installed (audit-project auto-dev bug-fixer codebase-doctor ...)
[codewright] Shared references installed
[codewright] Created ~/.config/opencode/opencode.json with Codewright plugin
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
GLOBAL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

echo "=== Verification ==="

for agent in cw-explore cw-worker; do
    if [ -f "$GLOBAL_DIR/agents/$agent.md" ]; then
        echo "✓ Agent: $agent"
    else
        echo "✗ Missing agent: $agent"
    fi
done

for skill in audit-project auto-dev bug-fixer codebase-doctor codebase-onboarding github-issue-fixer perf-analyzer pr-reviewer refactor-orchestrator test-engineer; do
    if [ -f "$GLOBAL_DIR/skills/$skill/SKILL.md" ]; then
        echo "✓ Skill: $skill"
    else
        echo "✗ Missing skill: $skill"
    fi
done

if [ -d "$GLOBAL_DIR/references" ]; then
    echo "✓ Shared references"
else
    echo "✗ Missing references"
fi

if [ -f "$GLOBAL_DIR/opencode.json" ] && grep -q "codewright" "$GLOBAL_DIR/opencode.json"; then
    echo "✓ Plugin registered in opencode.json"
else
    echo "✗ Plugin not registered"
fi

echo ""
echo "=== Done ==="
```

---

### Step 6: Confirm to user

Tell the user:

1. **What was installed** (globally to `~/.config/opencode/`, available in all projects):
   - 2 agents: `cw-explore` (read-only analysis), `cw-worker` (code modifications)
   - 10 skills: `audit-project`, `auto-dev`, `bug-fixer`, `codebase-doctor`, `codebase-onboarding`, `github-issue-fixer`, `perf-analyzer`, `pr-reviewer`, `refactor-orchestrator`, `test-engineer`
   - Shared references (agent-invocation, finding-format)
   - `cw_agent` tool (registered by plugin at startup)

2. **How to use it:**
   - "review my PR" or "review PR #123" — parallel PR review
   - "auto dev: add feature X" — autonomous development
   - "fix issue #42" — GitHub issue fixing
   - "audit this project" — comprehensive codebase audit
   - "onboard me" — generate architecture docs

3. **How to uninstall:**
   - Paste the uninstall prompt from the top of this file, or run `bash setup.sh --uninstall`

---

## Uninstall

### For Humans

Paste this prompt into your OpenCode session:

```
Uninstall Codewright for OpenCode by following the instructions here:
https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/opencode/INSTALL.md#uninstall
```

### For LLM Agents

You are helping the user **uninstall Codewright** from OpenCode.

Follow these steps exactly.

#### Step 1: Remove Codewright files

```bash
GLOBAL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

# Agents
rm -f "$GLOBAL_DIR/agents/cw-explore.md"
rm -f "$GLOBAL_DIR/agents/cw-worker.md"

# All skills
for skill in audit-project auto-dev bug-fixer codebase-doctor codebase-onboarding github-issue-fixer perf-analyzer pr-reviewer refactor-orchestrator test-engineer; do
    rm -rf "$GLOBAL_DIR/skills/$skill"
done

# Shared references
rm -rf "$GLOBAL_DIR/references"

echo "✓ Codewright agents, skills, and references removed"
```

#### Step 2: Remove plugin from opencode.json

Read `~/.config/opencode/opencode.json` and remove `"@codewright/opencode"` from the `plugin` array.

If `@codewright/opencode` is the only plugin, you can remove the entire `plugin` key or leave it as an empty array.

Do **not** delete `opencode.json` itself — the user may have other configuration in it.

#### Step 3: Verify removal

```bash
GLOBAL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

REMAINING=0
for f in "$GLOBAL_DIR/agents/cw-explore.md" "$GLOBAL_DIR/agents/cw-worker.md"; do
    [ -f "$f" ] && echo "✗ Still exists: $f" && REMAINING=$((REMAINING + 1))
done
for skill in audit-project auto-dev bug-fixer codebase-doctor codebase-onboarding github-issue-fixer perf-analyzer pr-reviewer refactor-orchestrator test-engineer; do
    [ -d "$GLOBAL_DIR/skills/$skill" ] && echo "✗ Still exists: skills/$skill" && REMAINING=$((REMAINING + 1))
done
[ -d "$GLOBAL_DIR/references" ] && echo "✗ Still exists: references/" && REMAINING=$((REMAINING + 1))

if [ $REMAINING -eq 0 ]; then
    echo "✓ Codewright fully removed"
else
    echo "✗ $REMAINING item(s) still present"
fi

if grep -q "codewright" "$GLOBAL_DIR/opencode.json" 2>/dev/null; then
    echo "✗ Plugin still referenced in opencode.json"
else
    echo "✓ Plugin removed from opencode.json"
fi
```

#### Step 4: Confirm to user

Tell the user that Codewright has been completely removed. All 10 skills, both agents, shared references, and the `cw_agent` tool are no longer available. No restart needed — the changes take effect on the next OpenCode session.

---

## Manual Installation

```bash
git clone https://github.com/Lazybone/Codewright.git /tmp/codewright
bash /tmp/codewright/platforms/opencode/setup.sh
rm -rf /tmp/codewright
```

## Manual Uninstallation

```bash
GLOBAL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
rm -f  "$GLOBAL_DIR/agents/cw-explore.md" "$GLOBAL_DIR/agents/cw-worker.md"
rm -rf "$GLOBAL_DIR/skills/audit-project" "$GLOBAL_DIR/skills/auto-dev" \
       "$GLOBAL_DIR/skills/bug-fixer" "$GLOBAL_DIR/skills/codebase-doctor" \
       "$GLOBAL_DIR/skills/codebase-onboarding" "$GLOBAL_DIR/skills/github-issue-fixer" \
       "$GLOBAL_DIR/skills/perf-analyzer" "$GLOBAL_DIR/skills/pr-reviewer" \
       "$GLOBAL_DIR/skills/refactor-orchestrator" "$GLOBAL_DIR/skills/test-engineer" \
       "$GLOBAL_DIR/references"
# Edit $GLOBAL_DIR/opencode.json and remove "@codewright/opencode" from the plugin array
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `cw_agent` tool not found | Ensure `@codewright/opencode` is in the `plugin` array of `~/.config/opencode/opencode.json` |
| Skill not discovered | Check that `~/.config/opencode/skills/pr-reviewer/SKILL.md` exists |
| Agent not found | Check that `~/.config/opencode/agents/cw-explore.md` and `cw-worker.md` exist |
| Plugin not loading | Start OpenCode and check logs for `[codewright] Plugin loaded` |
