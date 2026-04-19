# @codewright/opencode

Bridge plugin that brings [Codewright](https://github.com/user/codewright) multi-agent skills to [OpenCode](https://github.com/anomalyco/opencode).

> **Status: Proof of Concept** — Currently includes `pr-reviewer` skill only.

## How It Works

Codewright skills orchestrate multiple AI agents in parallel. In Claude Code, this uses the built-in `Agent()` tool. OpenCode doesn't have an equivalent, so this plugin bridges the gap:

1. **`cw_agent` custom tool** — Registered by the plugin at startup (via the `tool` hook, closing over the SDK client). Spawns subagent sessions, runs them in parallel, returns consolidated results.

2. **Predefined agents** (`cw-explore`, `cw-worker`) — Container agents with appropriate permissions for read-only analysis and code modifications.

3. **Ported skills** — SKILL.md files adapted to use `cw_agent` instead of `Agent()`, sharing identical agent prompt files.

## Architecture

```
┌─────────────────────────────────────────┐
│  SKILL.md (Orchestration Logic)         │
│  "Use cw_agent to spawn 3 reviewers"   │
└──────────────┬──────────────────────────┘
               │ calls
┌──────────────▼──────────────────────────┐
│  cw_agent (Plugin-Registered Tool)      │
│  Closes over SDK client from plugin     │
│  Validates args, spawns sessions        │
└──────────────┬──────────────────────────┘
               │ session.create + session.prompt
┌──────────────▼──────────────────────────┐
│  OpenCode SDK (session API)             │
├─────────┬─────────┬─────────────────────┤
│ Session │ Session │ Session             │
│cw-explore│cw-explore│cw-explore         │
│ "logic" │"security"│ "quality"          │
└─────────┴─────────┴─────────────────────┘
               │ Promise.allSettled
┌──────────────▼──────────────────────────┐
│  SKILL.md continues                     │
│  Consolidate → Deduplicate → Present    │
└─────────────────────────────────────────┘
```

### Why plugin-registered, not standalone?

OpenCode's `ToolContext` (passed to standalone tools in `.opencode/tools/`) does not expose the SDK client. Only the plugin's `PluginInput` provides `client` with `session.create()`, `session.prompt()`, etc. The tool is registered inside the plugin closure to capture `client`.

## Installation

### Option A: Local setup (per project)

```bash
# Install agents + skills to .opencode/
bash setup.sh

# Add plugin to opencode.json
echo '{ "plugin": ["@codewright/opencode"] }' > opencode.json
```

### Option B: Global setup (all projects)

```bash
bash setup.sh --global
```

### Option C: npm (when published)

```json
{
  "plugin": ["@codewright/opencode"]
}
```

## Available Skills

| Skill | Status | Description |
|-------|--------|-------------|
| `pr-reviewer` | PoC | 3-agent parallel PR review (logic, security, quality) |
| `audit-project` | Planned | 5-agent parallel codebase audit |
| `perf-analyzer` | Planned | 4-agent conditional performance analysis |
| `codebase-onboarding` | Planned | 3-agent sequential documentation |
| `auto-dev` | Planned | 9-agent autonomous dev with review loops |
| `github-issue-fixer` | Planned | 8-wave bug fix pipeline |
| `codebase-doctor` | Planned | 7-agent analysis + fix + verify |
| `refactor-orchestrator` | Planned | Multi-phase refactoring |
| `test-engineer` | Planned | Coverage analysis + test generation |

## Development

```bash
cd platforms/opencode
bun install
bun run typecheck   # tsc --noEmit
bun run build       # bundle to dist/
bun test            # unit tests
```

## Known Limitations

- **Live validation pending**: `session.prompt()` returns `{ info: AssistantMessage, parts: Part[] }` according to the SDK types, confirming it blocks until completion. However, edge cases around timeouts and large responses need live testing.
- **Context overhead**: Each spawned session adds context. Skills with 7+ agents may need context management.
- **Provider agnostic**: Agent prompts are optimized for Claude but should work with other providers.
- **Pattern library pending**: Review-fix loops, selective reactivation, and file partitioning are not yet implemented.

## Uninstall

```bash
bash setup.sh --uninstall
# Also remove '@codewright/opencode' from opencode.json
```
