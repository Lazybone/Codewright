# Codewright for OpenCode

Multi-agent skills for [OpenCode](https://github.com/anomalyco/opencode) — automated code review, bug fixing, refactoring, and project audits.

> **Status: Proof of Concept** — 10 skills available.

## Installation

Paste this into your OpenCode session:

```
Install and configure Codewright for OpenCode by following the instructions here:
https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/opencode/INSTALL.md
```

Installs globally to `~/.config/opencode/` — available in all projects.

Or install manually: [Installation Guide](INSTALL.md)

## What You Get

| Component | Description |
|-----------|-------------|
| `cw_agent` tool | Spawns parallel subagent sessions — OpenCode equivalent of Claude Code's `Agent()` |
| `cw-explore` agent | Read-only analysis (no file modifications) |
| `cw-worker` agent | Code modification agent (edit, write, bash) |
| `pr-reviewer` skill | 3-agent parallel PR review (Logic, Security, Quality) |

## How It Works

Codewright skills orchestrate multiple AI agents in parallel. In Claude Code, this uses the built-in `Agent()` tool. OpenCode doesn't have an equivalent, so this plugin bridges the gap.

```
  SKILL.md says "spawn 3 reviewers"
                  │
                  ▼
        cw_agent (plugin tool)
      closes over SDK client
                  │
        ┌─────────┼─────────┐
        ▼         ▼         ▼
    cw-explore cw-explore cw-explore
     "logic"  "security" "quality"
        │         │         │
        └─────────┼─────────┘
                  ▼
       Consolidate + Present
```

The `cw_agent` tool is registered by the plugin at startup via the `tool` hook — not as a standalone file, because OpenCode's `ToolContext` doesn't expose the SDK client.

## Skills Roadmap

| Skill | Description |
|-------|-------------|
| `audit-project` | 5-agent parallel codebase audit |
| `auto-dev` | 9-agent autonomous development |
| `bug-fixer` | TDD-based bug fixing (8-phase workflow) |
| `codebase-doctor` | 7-agent analyze + fix + verify |
| `codebase-onboarding` | Architecture docs generation |
| `github-issue-fixer` | 8-wave bug fix pipeline |
| `perf-analyzer` | 4-agent performance analysis |
| `pr-reviewer` | 3-agent parallel PR review |
| `refactor-orchestrator` | Multi-phase refactoring |
| `test-engineer` | Coverage analysis + test generation |

## Development

```bash
cd platforms/opencode
bun install
bun run typecheck   # tsc --noEmit
bun run build       # bundle to dist/
bun test            # 25 unit + integration tests
```

## Uninstallation

Paste this into your OpenCode session:

```
Uninstall Codewright for OpenCode by following the instructions here:
https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/opencode/INSTALL.md#uninstall
```

Or manually: [Uninstall Guide](INSTALL.md#uninstall)

## License

MIT
