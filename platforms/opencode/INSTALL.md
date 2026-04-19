# Codewright for OpenCode — Installation Guide

## For Humans

Paste this prompt into your OpenCode session:

```
Install and configure Codewright for OpenCode by following the instructions here:
https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/opencode/INSTALL.md
```

Or install manually — see "Manual Installation" below.

## For LLM Agents

> **IMPORTANT: Fetch this file with `curl`, not WebFetch.**
> WebFetch summarizes content and loses critical steps.
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/opencode/INSTALL.md
> ```

You are helping the user install **Codewright**, a multi-agent skill plugin for OpenCode.
Codewright provides skills like `pr-reviewer`, `auto-dev`, `github-issue-fixer`, and more.

Follow these steps exactly.

---

### Step 1: Verify OpenCode is installed

```bash
if command -v opencode &> /dev/null; then
    echo "✓ OpenCode $(opencode --version) is installed"
else
    echo "✗ OpenCode is not installed."
    echo "Install it first: https://opencode.ai/docs"
    exit 1
fi
```

If OpenCode is not installed, stop and help the user install it from https://opencode.ai/docs before continuing.

---

### Step 2: Detect project directory

Determine where to install. Codewright should be installed into the user's current project.

```bash
if git rev-parse --show-toplevel &> /dev/null; then
    PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    echo "✓ Git project found: $PROJECT_ROOT"
else
    PROJECT_ROOT="$(pwd)"
    echo "⚠ No git repo found, using current directory: $PROJECT_ROOT"
fi
```

---

### Step 3: Download and run setup

Clone the Codewright repository (or use a cached copy) and run the setup script.

```bash
# Download setup files to a temp directory
TMPDIR="$(mktemp -d)"
git clone --depth 1 --filter=blob:none --sparse \
    https://github.com/Lazybone/Codewright.git "$TMPDIR/codewright"
cd "$TMPDIR/codewright"
git sparse-checkout set platforms/opencode

# Run setup in the project directory
cd "$PROJECT_ROOT"
bash "$TMPDIR/codewright/platforms/opencode/setup.sh"

# Clean up
rm -rf "$TMPDIR/codewright"
```

**Expected output:**
```
[codewright] Installing Codewright to .opencode ...
[codewright] Agents installed (cw-explore, cw-worker)
[codewright] Skill installed (pr-reviewer)
[codewright] Installation complete. All files verified.
```

---

### Step 4: Install the plugin package

The `cw_agent` tool is registered by the Codewright plugin at startup. Install the npm package:

```bash
cd "$PROJECT_ROOT"

# Create .opencode directory if it doesn't exist
mkdir -p .opencode

# Add package.json for plugin dependency (if not exists)
if [ ! -f .opencode/package.json ]; then
    echo '{ "dependencies": { "@codewright/opencode": "latest" } }' > .opencode/package.json
fi

# Install (OpenCode uses bun internally)
cd .opencode && bun install && cd ..
```

> **Note:** If `@codewright/opencode` is not yet published on npm, skip this step.
> The plugin will work from the local setup alone once published.

---

### Step 5: Register plugin in opencode.json

Add Codewright to the project's OpenCode configuration.

```bash
cd "$PROJECT_ROOT"

if [ -f opencode.json ]; then
    # Check if already registered
    if grep -q "codewright" opencode.json 2>/dev/null; then
        echo "✓ Codewright already registered in opencode.json"
    else
        echo "⚠ Add '@codewright/opencode' to the plugin array in opencode.json"
        echo "  Example: { \"plugin\": [\"@codewright/opencode\"] }"
    fi
else
    # Create opencode.json with Codewright plugin
    cat > opencode.json << 'OPENCODE_JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["@codewright/opencode"]
}
OPENCODE_JSON
    echo "✓ Created opencode.json with Codewright plugin"
fi
```

---

### Step 6: Verify installation

Run these checks to confirm everything is in place:

```bash
cd "$PROJECT_ROOT"

echo "=== Verification ==="

# Check agents
for agent in cw-explore cw-worker; do
    if [ -f ".opencode/agents/$agent.md" ]; then
        echo "✓ Agent: $agent"
    else
        echo "✗ Missing agent: $agent"
    fi
done

# Check skills
for skill in pr-reviewer; do
    if [ -f ".opencode/skills/$skill/SKILL.md" ]; then
        echo "✓ Skill: $skill"
    else
        echo "✗ Missing skill: $skill"
    fi
done

# Check config
if [ -f "opencode.json" ] && grep -q "codewright" opencode.json; then
    echo "✓ Plugin registered in opencode.json"
else
    echo "✗ Plugin not registered in opencode.json"
fi

echo ""
echo "=== Installation complete ==="
echo "Available skills: pr-reviewer"
echo "Try: 'review my PR' or 'review PR #123'"
```

---

### Step 7: Confirm to user

Tell the user:

1. **What was installed:**
   - `cw-explore` agent (read-only analysis)
   - `cw-worker` agent (code modifications)
   - `pr-reviewer` skill (3-agent parallel PR review)
   - `cw_agent` tool (registered by plugin at startup)

2. **How to use it:**
   - Say "review my PR" or "review PR #123" to trigger the `pr-reviewer` skill
   - The skill spawns 3 parallel agents (Logic, Security, Quality) and consolidates findings

3. **What's coming next:**
   - `auto-dev` — autonomous development with review loops
   - `github-issue-fixer` — 8-wave bug fix pipeline
   - `codebase-doctor` — analyze + auto-fix + verify
   - And 6 more skills

---

## Manual Installation

If you prefer to install without an LLM agent:

```bash
# Clone and run setup
git clone https://github.com/Lazybone/Codewright.git /tmp/codewright
cd /your/project
bash /tmp/codewright/platforms/opencode/setup.sh

# Add to opencode.json
echo '{ "plugin": ["@codewright/opencode"] }' > opencode.json

# Clean up
rm -rf /tmp/codewright
```

## Uninstallation

```bash
bash .opencode/setup.sh --uninstall  # or re-download and run setup.sh --uninstall
# Remove from opencode.json plugin array
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `cw_agent` tool not found | Ensure `@codewright/opencode` is in the `plugin` array of `opencode.json` |
| Skill not discovered | Check that `.opencode/skills/pr-reviewer/SKILL.md` exists |
| Agent not found | Check that `.opencode/agents/cw-explore.md` and `cw-worker.md` exist |
| Plugin not loading | Run `opencode` and check startup logs for `[codewright] Plugin loaded` |
