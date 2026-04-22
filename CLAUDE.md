# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **multi-platform AI coding plugin** (`codewright`) — a collection of multi-agent skills that automate complex development tasks. Skills are self-contained directories with a `SKILL.md` entry point, agent definitions, and reference templates.

**Supported platforms**: Claude Code (primary), OpenCode (PoC via bridge plugin).

## Plugin Structure

```
.claude-plugin/
  plugin.json               # Claude Code plugin manifest (name, version, author)
references/                   # Shared references across all skills
  agent-invocation.md         # How to start and communicate with agents
  finding-format.md           # Unified finding format for all analysis agents
skills/
  skill-name/
    SKILL.md                # Main skill definition (frontmatter + workflow)
    agents/                 # Subagent prompt definitions (.md files)
    references/             # Templates, formats, conventions (.md files)
platforms/
  opencode/                 # OpenCode bridge plugin (@codewright/opencode)
    src/                    # Plugin TypeScript source (orchestrator, tools, types)
    tools/                  # Standalone custom tool (cw_agent.ts → .opencode/tools/)
    agents/                 # Predefined agents (cw-explore, cw-worker)
    skills/                 # OpenCode-specific SKILL.md versions
    setup.sh                # Installation script for .opencode/ setup
```

**Installation (Claude Code)**: `claude plugin add` or test locally with `claude --plugin-dir .`
**Installation (OpenCode)**: `bash platforms/opencode/setup.sh` or (when published) `"plugin": ["@codewright/opencode"]`

### Skills

| Skill | Invocation | Agent Pattern |
|---|---|---|
| `audit-project` | `/codewright:audit-project` | 5 parallel Explore agents → GitHub Issue creation |
| `codebase-doctor` | `/codewright:codebase-doctor` | 3-wave: 7 Explore → Fix → Review agents |
| `github-issue-fixer` | `/codewright:github-issue-fixer` | 9-wave: Validate (dual-agent) → Plan → TDD → Fix → Review-Fix Loop (4 reviewers, max 5) → Harden → Acceptance → CI Validation (max 3) → Commit |
| `refactor-orchestrator` | `/codewright:refactor-orchestrator` | Teamleader + Scout/Architect/Worker/Test agents (agents/ + references/) |
| `auto-dev` | `/codewright:auto-dev` | 8-phase: Analyst → Planner (+Mockup) → Workers → Review-Fix Loop (4 reviewers, max 5 iter.) → Harden → Acceptance → CI Validation (max 3) → Finish |
| `bug-fixer` | `/codewright:bug-fixer` | 8-phase: Bug Analyst → Reproduce (TDD RED) → Plan & Fix (TDD GREEN) → Review-Fix Loop (4 reviewers, max 5 iter.) → Harden → Acceptance → CI Validation (max 3) → Finish |

## Skill File Format

`SKILL.md` files use YAML frontmatter:

```yaml
---
name: skill-name
description: >
  Multi-line description used for skill matching/triggering.
  Include German and English trigger phrases.
disable-model-invocation: true  # Optional: prevents direct model invocation
---
```

## Key Patterns

- **Agent types**: Skills use `subagent_type: "Explore"` for read-only analysis and general-purpose agents with `mode: "auto"` for code changes.
- **Inter-agent communication**: Agents return structured Markdown responses; no `/tmp/` files are used.
- **File conflict avoidance**: When multiple agents modify code in parallel, files are strictly partitioned so no two agents edit the same file.
- **Finding format**: Both `audit-project` and `codebase-doctor` share a standardized finding format defined in their respective `references/finding-format.md`.
- **User confirmation gates**: All skills pause before destructive actions (creating issues, committing, merging) and ask the user.

## Versioning & Release

- **Auto-increment patch version** on every change (e.g., `0.3.0` → `0.3.1` → `0.3.2`). Only bump minor/major when the user explicitly says so.
- Version must be updated in ALL three files simultaneously:
  - `.claude-plugin/plugin.json`
  - `.claude-plugin/marketplace.json`
  - `CHANGELOG.md`
- The plugin marketplace reads the version from `plugin.json` (not git tags). Users must run `/plugin update` or clear their cache to get the new version.

## Language

All skill content, agent prompts, reports, and user-facing output are in **English**. SKILL.md description fields include both English (primary) and German (secondary) trigger phrases for backward compatibility.
