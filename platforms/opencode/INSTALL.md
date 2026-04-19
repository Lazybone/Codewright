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
[codewright] Skill installed (pr-reviewer)
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

if [ -f "$GLOBAL_DIR/skills/pr-reviewer/SKILL.md" ]; then
    echo "✓ Skill: pr-reviewer"
else
    echo "✗ Missing skill: pr-reviewer"
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
   - `cw-explore` agent (read-only analysis)
   - `cw-worker` agent (code modifications)
   - `pr-reviewer` skill (3-agent parallel PR review)
   - `cw_agent` tool (registered by plugin at startup)

2. **How to use it:**
   - Say "review my PR" or "review PR #123" in any OpenCode session

3. **How to uninstall:**
   - Paste the uninstall prompt from the top of this file, or run `bash setup.sh --uninstall`

4. **What's coming next:**
   - `auto-dev`, `github-issue-fixer`, `codebase-doctor`, and 6 more skills

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

rm -f  "$GLOBAL_DIR/agents/cw-explore.md"
rm -f  "$GLOBAL_DIR/agents/cw-worker.md"
rm -rf "$GLOBAL_DIR/skills/pr-reviewer"

echo "✓ Codewright agents and skills removed"
```

#### Step 2: Remove plugin from opencode.json

Read `~/.config/opencode/opencode.json` and remove `"@codewright/opencode"` from the `plugin` array.

If `@codewright/opencode` is the only plugin, you can remove the entire `plugin` key or leave it as an empty array.

Do **not** delete `opencode.json` itself — the user may have other configuration in it.

#### Step 3: Verify removal

```bash
GLOBAL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

REMAINING=0
for f in "$GLOBAL_DIR/agents/cw-explore.md" "$GLOBAL_DIR/agents/cw-worker.md" "$GLOBAL_DIR/skills/pr-reviewer/SKILL.md"; do
    if [ -f "$f" ]; then
        echo "✗ Still exists: $f"
        REMAINING=$((REMAINING + 1))
    fi
done

if [ $REMAINING -eq 0 ]; then
    echo "✓ Codewright fully removed"
else
    echo "✗ $REMAINING file(s) still present"
fi

if grep -q "codewright" "$GLOBAL_DIR/opencode.json" 2>/dev/null; then
    echo "✗ Plugin still referenced in opencode.json"
else
    echo "✓ Plugin removed from opencode.json"
fi
```

#### Step 4: Confirm to user

Tell the user that Codewright has been completely removed. The `cw_agent` tool, `cw-explore`/`cw-worker` agents, and `pr-reviewer` skill are no longer available. No restart needed — the changes take effect on the next OpenCode session.

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
rm -f  "$GLOBAL_DIR/agents/cw-explore.md"
rm -f  "$GLOBAL_DIR/agents/cw-worker.md"
rm -rf "$GLOBAL_DIR/skills/pr-reviewer"
# Edit $GLOBAL_DIR/opencode.json and remove "@codewright/opencode" from the plugin array
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `cw_agent` tool not found | Ensure `@codewright/opencode` is in the `plugin` array of `~/.config/opencode/opencode.json` |
| Skill not discovered | Check that `~/.config/opencode/skills/pr-reviewer/SKILL.md` exists |
| Agent not found | Check that `~/.config/opencode/agents/cw-explore.md` and `cw-worker.md` exist |
| Plugin not loading | Start OpenCode and check logs for `[codewright] Plugin loaded` |
